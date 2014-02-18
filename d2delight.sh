#!/bin/bash

end="elight"
cat $1 | sed 's/\(import.*\);/\1/g' | sed 's/void main()/procedure main:/' | sed 's/^\(\s*\)for\s*(\s*\(.*\);\s*\(.*\);\s*\(.*[^ ]\)\s*)/\1\2\n\1while \3:\n\1\t\4/' | sed 's/foreach\s*(\s*\(.*\);\s*\(.*[^ ]\)\s*)/for \1 in \2:/' | sed 's/++/ += 1/g' | sed 's/--/ -= 1/g' | sed 's/\(else \)\?if\s*(\s*\(.*[^ ]\)\s*)/\1if \2:/g' | sed 's/&&/and/g' | sed 's/||/or/g' | sed 's/</less than/g' | sed 's/>/more than/g' | sed 's/==/equal to/' | sed 's/<=/not more than/g' | sed 's/>=/not less than/g' | sed 's/[{}]//g' | sed 's/;$//' > "$1$end"
