#!/usr/bin/env nu

use std/assert
use ./constants.nu *

# Horrible hack to work around the facts that I'm relying on `describe` for
# type-safety until https://github.com/nushell/nushell/issues/16229 is
# implemented, and I can't use `null`/`nothing` in tables without running into
# https://github.com/nushell/nushell/issues/16232.
const NO_STRING_VALUE = "~~~NO_STRING~~~";
def isString [val: oneof<string, nothing>]: nothing -> bool {
	if $val == null or $val == $NO_STRING_VALUE or ($val | describe) != "string" {
		false
	} else {
		true
	}
}

let fullUpdatedStateTableWithPaths = (
	getRecordedStateAsRecord $takeoutStateFilePath
	| convertStateToTable
	| do {
		try {
			performBasicValidationOnStateTable $in
		} catch { |e|
			print -e $"Error: ($e.msg)\nEncountered while parsing ($takeoutStateFilePath)"
			exit 1
		}
		$in
	}
	| updateStateTableAndGetPaths
)

# Write out the full, updated state
$fullUpdatedStateTableWithPaths
| convertStateToRecord
| to nuon --tabs 1
| save -f $takeoutStateFilePath

# print (
# 	$fullUpdatedStateTableWithPaths
# 	| where { |x| isString $x.state.path }
# 	| table --expand
# )

# TODO(Harper): Extract and delete files that have been downloaded but not extracted
# TODO(Harper): Delete files from previous runs that have been extracted but not deleted
# TODO(Harper): Write takeoutState.nuon after every extraction or deletion
# TODO(Harper): Skip files with a type other than "photos" (with warning)

# for $filePath in $filePaths {
# 	let fileName = getFileName $filePath
# 	try {
# 		# unzip -q $filePath -d $photosFolder
# 		$progress = $progress | update $fileName "extractedToPhotosFolder"
# 		print $"Extracted ($fileName)"

# 		try {
# 			# rm $filePath
# 			print $"Deleted ($fileName)"
# 		} catch { |e|
# 			print $"Failed to delete ($fileName): ($e.msg)"
# 		}
# 	} catch { |e|
# 		print $"Failed to extract ($fileName): ($e.msg)"
# 	}
# }

# As of Nushell 0.105, it's extremely easy to accidentally return values that do not match the
# output type annotation (see the linked issues). We avoid problems by asserting return values
# using this function. If #16229 ever gets resolved, we should delete this function, as it
# accomplishes the same thing, but with less type safety (ironically).
# https://github.com/nushell/nushell/issues/16227
# https://github.com/nushell/nushell/issues/16229
def returnType [commandName: string, intendedReturnType: string]: any -> any {
	let actualType = $in | describe
	# As of nu 0.105, record values can only be typed if you also know the
	# names of all keys. If the intended type is just "record", be lenient.
	let adjustedActualType = if $intendedReturnType == "record" and $actualType starts-with "record" {
		"record"
	} else {
		$actualType
	}
	(assert
		($adjustedActualType == $intendedReturnType)
		$"($commandName) should return type\n'($intendedReturnType)'\nbut got type\n'($adjustedActualType)'"
	)
	$in
}

def getFilename [filePath: string]: nothing -> string {
	$filePath
	| path parse --extension ''
	| get stem
	| returnType getFilename "string"
}

# The record form ensures that we can't have duplicate filenames,
# and doesn't require iteration for lookups. Unfortunately, nushell
# doesn't have support for typing record values without specifying
# the key names (as far as I know, as of version 0.105)
def getRecordedStateAsRecord [stateFilePath: string]: nothing -> record {
	open $stateFilePath
	| returnType getRecordedStateAsRecord "record"
}

# Using the record form throughout the program would be simpler
# (and still allow for iteration using the `items` command, but
# converting to a table gives us type safety, which is especially
# useful since we sometimes add a `path` column that should not be
# persisted.
def convertStateToTable []: record -> table<filename: string, state: record<type: string, progress: string>> {
	$in
	| transpose filename state
	| returnType convertStateToTable "table<filename: string, state: record<type: string, progress: string>>"
}

# Because we don't have type-safety for the record form, it should never have extra
# information added to it so that it's always in the right format for serialization
def convertStateToRecord []: table<filename: string, state: record<type: string, progress: string>> -> record {
	$in
	# Filter out any extra data that got added somehow (our record can't be type-safe) :(
	| each { { filename: $in.filename, state: { type: $in.state.type, progress: $in.state.progress } } }
	| transpose --as-record --header-row
	| returnType convertStateToRecord "record"
}

# Error-handling in pipelines isn't great, so this returns nothing, and should be used outside of a pipeline
def performBasicValidationOnStateTable [
	stateTable: table<filename: string, state: record<type: string, progress: string>>
]: nothing -> nothing {
	# If we were to call `error make` from `each`, we'd end up with an `nu::shell::eval_block_with_input`
	for entry in $stateTable {
		if $entry.state.type not-in $VALID_TYPES {
			error make { msg: $"Type '($entry.state.type)' is not one of ($VALID_TYPES)" }
		}
	}
}

# Accepts a state table and returns one with an updated progress column as well as a new path column
# (which is set to $NO_PATH for files that are not present in the downloads location)
def updateStateTableAndGetPaths [
]: table<filename: string, state: record<type: string, progress: string>> -> table<filename: string, state: record<type: string, progress: string, path: string>> {
	let stateTable = $in
	# TODO(Harper): Exit with error code if there are files in downloadedZips that are not listed in progress.nuon

	# TODO(Harper): Support .tar.gz
	let downloadedFiles: table<filePath: string, filename: string> = ls ~/Downloads/takeout-*.zip
		| get name # This actually gets the relative paths
		| path expand
		| each { { filePath: $in, filename: (getFilename $in) } }

	$stateTable
		| each {
			# TODO(Harper): Extract all of this into a function
			let recordedProgress: string = $in.state.progress
			let type: string = $in.state.type
			let filename: string = $in.filename
			# MAY CONTAIN $NO_STRING_VALUE
			let filePath: string = do {
				let filteredFilenamesArray = (
					$downloadedFiles
					| where filename == $filename
					| get filePath
				)

				if ($filteredFilenamesArray | length) == 1 {
					$filteredFilenamesArray.0
				} else {
					$NO_STRING_VALUE
				}
			}

			let progress = if $recordedProgress in $PROGRESS_VALUES_NOT_EXTRACTED { #== $PROGRESS_NONE or $recordedProgress == $PROGRESS_DOWNLOADED {
				# Entries that have not been extracted yet are either downloaded or not
				let actualProgress = if (isString $filePath) { $PROGRESS_DOWNLOADED } else { $PROGRESS_NONE }

				if $recordedProgress != $actualProgress {
					if $actualProgress == $PROGRESS_DOWNLOADED {
						# Since this script doesn't do any actual downloading,
						# downloads are expected to always start out untracked
						print $"Discovered download for ($filename)"
					} else {
						print -e $"WARNING: ($takeoutStateFilename) reported progress '($recordedProgress)' for ($filename), but the actual progress seems to be '($actualProgress)'"
					}
				}

				$actualProgress
			} else if $recordedProgress in $PROGRESS_VALUES_EXTRACTED {
				# Entries that have already been extracted are either deleted or not
				let actualProgress = if (isString $filePath) { $PROGRESS_EXTRACTED } else { $PROGRESS_EXTRACTED_AND_DELETED }

				if $recordedProgress != $actualProgress {
					if $actualProgress == $PROGRESS_EXTRACTED_AND_DELETED {
						# It's not unusual for users to clean up their downloads folder, and no harm was done
						print $"Discovered that extracted download ($filename) has already been deleted"
					} else {
						print -e $"WARNING: ($takeoutStateFilename) reported progress '($recordedProgress)' for ($filename), but the actual progress seems to be '($actualProgress)'"
					}
				}

				$actualProgress
			} else {
				print -e $"ERROR: Unrecognized progress state '($recordedProgress)' in ($takeoutStateFilename)"
				exit 1
			}

			{ filename: $filename, state: { type: $type, progress: $progress, path: $filePath } }
		}
		| returnType updateStateTableAndGetPaths "table<filename: string, state: record<type: string, progress: string, path: string>>"
}
