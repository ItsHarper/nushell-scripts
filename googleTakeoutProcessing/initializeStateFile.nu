#!/usr/bin/env nu

use ./constants.nu *

def main [
	--type: string,
	--extension: string,
	--parts: int,
	--takeoutId: string
]: nothing -> nothing {
	if $type not-in $VALID_TYPES {
		print -e $"Invalid type '($type)' \(must be one of ($VALID_TYPES)\)"
		exit 1
	}

	if $extension not-in $VALID_EXTENSIONS {
		print -e $"Invalid extension '($extension)' \(must be one of ($VALID_EXTENSIONS)\)"
		exit 1
	}

	# Example of a valid ID: "20250721T134323Z-1"
	let parsedIds = $takeoutId | parse --regex '\d\d\d\d\d\d\d\dT\d\d\d\d\d\dZ-\d+'
	if ($parsedIds | length) != 1 {
		print -e $"Invalid takeoutId '($takeoutId)' \(must match format 'xxxxxxxxTxxxxxxZ-x')"
		exit 1
	}

	if $parts < 1 {
		print -e $"There must be at least 1 part \(you specified ($parts)\)"
		exit 1
	}

	let prefix = $"takeout-($takeoutId)-"

	# TODO(Harper): Make this modify existing progress file (if applicable), and only insert new records if they are not present

	1..$parts
			| each { $in | into string | fill --width 3 --alignment right --character '0' }
			| each { $"($prefix)($in).($extension)" }
			| reduce -f {} { |it, acc|
				$acc | insert $it { type: $type, progress: $PROGRESS_NONE }
			}
			| to nuon --tabs 1
			# TODO(Harper): Remove -f until other TODO has been done
			| save $takeoutStateFilePath

}
