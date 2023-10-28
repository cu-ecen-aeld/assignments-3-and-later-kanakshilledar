#!/bin/sh

# expecting two arguemnt, filesdir as 1, and search_string as2

if [ $# -ne 2 ]; then
        echo "Usage: $0 file_path, search_string"
        exit 1
fi
if ! [ -d "$1" ]; then
	echo "$1  does not exisit or is not a directory"
	exit 1
fi

file_count=$(find "$1" -type f | wc -l)

search_string="$2"
count=$(grep -r "$search_string" "$1" | wc -l)
echo "The number of files are $file_count and the number of matching lines are $count"
