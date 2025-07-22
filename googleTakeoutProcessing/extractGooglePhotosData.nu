#!/usr/bin/env nu

use ./constants.nu *

let state = getState
print $state

# TODO(Harper): Extract and delete files that have been downloaded but not extracted
# TODO(Harper): Delete files from previous runs that have been extracted but not deleted
# TODO(Harper): Write takeoutState.nuon after every extraction or deletion

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

# $progress | save -f $progressFilePath

def getFilename [filePath: string]: nothing -> string {
	$filePath | path parse --extension '' | get stem
}

# TODO(Harper): Split up into getRecordedStateRecord, convertStateToTable, convertStateToRecord, updateStateTableAndGetPaths, writeStateRecord
def getState []: nothing -> table<filename: string, filePath: oneof<string, nothing>, progress: string> {
	let takeoutState: record<string, record<type: string, progress: string>> = open $takeoutStateFilePath
	# TODO(Harper): Support .tar.gz
	let downloadedFiles: table<filePath: string, filename: string> = ls ~/Downloads/takeout-*.zip
		| get name # This actually gets the relative paths
		| path expand
		| each { { filePath: $in, filename: (getFilename $in) } }

	# TODO(Harper): Exit with error code if there are files in downloadedZips that are not listed in progress.nuon
	# TODO(Harper): Skip files with a type other than "photos" (with warning)

	$takeoutState
		| transpose filename state # Allow iteration by converting from a record to a table
		| each {
			# TODO(Harper): Extract all of this into a function
			if $in.state.type not-in $VALID_TYPES {
				print -e $"Error: type '($in.state.type)' in ($takeoutStateFilename) is not one of ($VALID_TYPES)"
				exit 1
			}

			let recordedProgress: string = $in.state.progress
			let filename: string = $in.filename
			let filePath: oneof<string, nothing> = (
				$downloadedFiles
				| where filename == $filename
				| get filePath
			).0?

			let progress = if $recordedProgress in $PROGRESS_VALUES_NOT_EXTRACTED { #== $PROGRESS_NONE or $recordedProgress == $PROGRESS_DOWNLOADED {
				# Entries that have not been extracted yet are either downloaded or not
				let actualProgress = if $filePath != null { $PROGRESS_DOWNLOADED } else { $PROGRESS_NONE }

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
				let actualProgress = if $filePath != null { $PROGRESS_EXTRACTED } else { $PROGRESS_EXTRACTED_AND_DELETED }

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

			{ filename: $filename, filePath: $filePath, progress: $progress }
		}
}
