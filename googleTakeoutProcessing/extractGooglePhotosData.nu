#!/usr/bin/env nu

use ./constants.nu *

getAndUpdateStateOfZips
	| updateDownloadStatuses
# updateDownloadStates $filePaths

# $filePaths
# 	| each { getFileName $in }
# 	| each {
# 		print $in
# 	}

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

def getFileName [filePath: string]: nothing -> string {
	$filePath | path parse --extension '' | get stem
}

def getAndUpdateStateOfZips []: nothing -> table<name: string, path: string, status: string> {
	let progress: record<string, record<type: string, progress: string>> = open $progressFilePath
	let downloadedZipPaths: list<string> = ls ~/Downloads/takeout-*.zip | get name | path expand

	let result: table<name: string, path: string, status: string> = $downloadedZipPaths
		| each {
			let path: string = $in
			let name: string = getFileName $path
			let status: string = $progress | get $name
			let status = if $status == $STATUS_NONE {
				$STATUS_DOWNLOADED
			} else {
				$status
			}

			return { name: $name, path: $path, status: $status }
		}

	progress
		|

	result
}

# def updateDownloadProgress []: table<name: string, path: string, status: string> -> table<name: string, path: string, status: string> {
# }

def updateDownloadStates [filePaths: list<string>] {
	# mut progress = open $progressFilePath
	# for $filePath in $filePaths {
	# 	let fileName = getFileName $filePath
	# 	$progress | get $fileName
	# 	if ($progress | get $fileName) == "none" {
	# 		print $"Marking ($fileName) as downloaded"
	# 		$progress = $progress | update $fileName "downloaded"
	# 	}
	# }

	# $progress | to nuon --tabs 1 | save -f $progressFilePath
	# print "Updated downloaded states in progress.nuon"
}
