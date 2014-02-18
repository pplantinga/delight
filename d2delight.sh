#!/bin/bash

end="elight"
sed -r -e 's/(import.*);/\1/g' \
	-e 's/void main\(\)/procedure main:/' \
	-e 's/^(\s*)for\s*\(\s*(.*);\s*(.*);\s*(.*[^ ])\s*\)/\1\2\n\1while \3:\n\1\t\4/' \
	-e 's/foreach\s*\(\s*(.*);\s*(.*[^ ])\s*\)/for \1 in \2:/' \
	-e 's/\+\+/ \+= 1/g' \
	-e 's/--/ -= 1/g' \
	-e 's/(else )?if\s*\(\s*(.*[^ ])\s*\)/\1if \2:/g' \
	-e 's/&&/and/g' \
	-e 's/\|\|/or/g' \
	-e 's/</less than/g' \
	-e 's/>/more than/g' \
	-e 's/==/equal to/' \
	-e 's/<=/not more than/g' \
	-e 's/>=/not less than/g' \
	-e 's/[{}]//g' \
	-e 's/;$//' < $1 > "$1$end"
