all:
	dmd -lib delight.d lexer.d parser.d

unittest:
	dmd -lib delight.d lexer.d parser.d -unittest
