#!/bin/bash

end="elight"
sed -e 's/\(import.*\);/\1/g' \
	-e 's/void \([a-zA-Z0-9_]*(.*)\)/procedure \1:/' \
	-e 's/\(int\|string\|double\) \([a-zA-Z0-9_]\+(.*\))/function \2-> \1 ):/' \
	-e 's/^\(\s*\)for\s*(\s*\(.*\);\s*\(.*\);\s*\(.*[^ ]\)\s*)/\1\2\n\1while \3:\n\1\t\4/' \
	-e 's/foreach\s*(\s*\(.*\);\s*\(.*[^ ]\)\s*)/for \1 in \2:/' \
	-e 's/\(while\|switch\)\s*(\s*\(.*[^ ]\)\s*)/\1 \2:/' \
	-e 's/class \([A-Za-z_0-9]\+\)$/class \1:/' \
	-e 's_/\*\*_#._' \
	-e 's_/++_#._' \
	-e 's_///_#._' \
	-e 's_/\*_#_' \
	-e 's_/+_#_' \
	-e 's_//_#_' \
	-e 's/++/ \+= 1/g' \
	-e 's/--/ -= 1/g' \
	-e 's/\(else \)\?if\s*(\s*\(.*[^ ]\)\s*)/\1if \2:/g' \
	-e 's/&&/and/g' \
	-e 's/||/or/g' \
	-e 's/<=/not more than/g' \
	-e 's/>=/not less than/g' \
	-e 's/</less than/g' \
	-e 's/ >/ more than/g' \
	-e 's/==/equal to/g' \
	-e 's/!=/not equal to/g' \
	-e 's/[{}]//g' \
	-e 's/;$//' < $1 > "$1$end"
