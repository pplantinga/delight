all:
	dmd delight.d lexer.d parser.d

unittest:
	dmd delight.d lexer.d parser.d -unittest
