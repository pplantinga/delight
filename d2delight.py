#!/usr/bin/python

import re
import sys

if len( sys.argv ) != 2:
	print "usage: d2delight.py path/to/file.d"
	sys.exit()

with open( sys.argv[1], 'r' ) as file:
	content = file.read()

content = re.sub( r'(import.*);', r'\1', content )
content = re.sub( r'\b(?!void|new)([a-z]+) ([a-zA-Z0-9_]+\(.*)\)', r'function \2-> \1 ):', content )
content = re.sub( r'void ([a-zA-Z0-9_]*\(.*\))', r'procedure \1:', content )
content = re.sub( r'\n([ \t]*)for\s*\(\s*(.*);\s*(.*);\s*(.*[^ ])\s*\)', r'\n\1\2\n\1while \3:\n\1\t\4;', content )
content = re.sub( r'foreach\s*\(\s*(.*);\s*(.*[^ ])\s*\)', r'for \1 in \2:', content )
content = re.sub( r'(while|switch)\s*\(\s*(.*[^ ])\s*\)', r'\1 \2:', content )
content = re.sub( r'class ([A-Za-z_0-9]+)', r'class \1:', content )
content = re.sub( r'(try|finally|unittest|this\(.*\))', r'\1:', content )
content = re.sub( r'assert\(\s*(.*[^ ])\s*\)', r'assert \1', content )
content = re.sub( r'catch\s*\(\s*(.*[^ ])\s*\)', r'except \1:', content )
content = re.sub( r'/[+*][+*]', r'#.', content )
content = re.sub( r'\n(\t*) [+*]/?', r'\n\1\t', content )
content = re.sub( r'///', r'#.', content )
content = re.sub( r'/[+*/]', r'#', content )
content = re.sub( r'([+-]){2}([ ;])', r' \1= 1\2', content )
content = re.sub( r'if\s*\(\s*(.*[^ ])\s*\)', r'if \1:', content )
content = re.sub( r'else\n', r'else:\n', content )
content = re.sub( r'&&', r'and', content )
content = re.sub( r'\|\|', r'or', content )
content = re.sub( r'<=', r'not more than', content )
content = re.sub( r'>=', r'not less than', content )
content = re.sub( r'<', r'less than', content )
content = re.sub( r' >', r' more than', content )
content = re.sub( r'==', r'equal to', content )
content = re.sub( r'!=', r'not equal to', content )
content = re.sub( r' !', r' not ', content )
content = re.sub( r'[{}]', r'', content )
content = re.sub( r';\n', r'\n', content )

with open( sys.argv[1] + "elight", "w" ) as out:
	out.write( content )
