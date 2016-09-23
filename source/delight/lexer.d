/**
 * This lexer breaks "Delight" source code into tokens.
 * Author: Peter Massey-Plantinga
 *
 * The lexer
 * - is initialized with a string containing a filename
 *   with "delight" source code in it
 * - reads the file line by line
 * - produces tokens, such as "asdf" "1.2" "+" "foreach" etc.
 */
module delight.lexer;

import std.stdio : writeln, File;
import std.regex;
import std.container : DList;
import std.array : join;
import std.math : abs;
import std.algorithm : startsWith;
import std.string : strip, format;
import std.conv : to;

class Lexer
{
	static immutable MAX_INDENT = 10000;
	int line_number;
	int indentation_level;
	int block_level = MAX_INDENT;
	string indentation;
	DList!string tokens;
	File f;

	/** Constructor takes a file name containing "delight" source code */
	this( string filename )
	{
		/** Open file for reading */
		f = File( filename, "r" );

		/** Find out what the file uses for indentation */
		auto r = regex( "^( +|\t)[^ \t]" );
		string current_line;
		while ( !indentation && !f.eof() )
		{
			current_line = f.readln();
			auto c = matchFirst( current_line, r );
			if ( !c.empty() )
				indentation = c[1];
		}

		// Go back to the beginning of the file
		f.rewind();

		// Add a beginning of input symbol
		tokens.insertFront( "begin" );
		this.tokenize_line();
	}
	unittest
	{
		writeln( "Lexing indent test" );
		auto l1 = new Lexer( "tests/indent.delight" );
		assert( l1.indentation == "\t" );
		assert( !l1.is_empty() );
		assert( l1.pop() == "begin" );
		assert( l1.peek() == "procedure" );
		assert( l1.pop() == "procedure" );
		assert( l1.pop() == "main" );
		assert( l1.pop() == ":" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "indent" );
		assert( l1.pop() == "function" );
		assert( l1.pop() == "add" );
		assert( l1.pop() == "(" );
		assert( l1.pop() == "int" );
		assert( l1.pop() == "a" );
		assert( l1.pop() == "," );
		assert( l1.pop() == "b" );
		assert( l1.pop() == "->" );
		assert( l1.pop() == "int" );
		assert( l1.pop() == ")" );
		assert( l1.pop() == ":" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "indent" );
		assert( l1.pop() == "int" );
		assert( l1.pop() == "c" );
		assert( l1.pop() == "=" );
		assert( l1.pop() == "a" );
		assert( l1.pop() == "+" );
		assert( l1.pop() == "b" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "return" );
		assert( l1.pop() == "c" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "dedent" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "int" );
		assert( l1.pop() == "c" );
		assert( l1.pop() == "=" );
		assert( l1.pop() == "add" );
		assert( l1.pop() == "(" );
		assert( l1.pop() == "1" );
		assert( l1.pop() == "," );
		assert( l1.pop() == "2" );
		assert( l1.pop() == ")" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "int" );
		assert( l1.pop() == "d1" );
		assert( l1.pop() == "=" );
		assert( l1.pop() == "add" );
		assert( l1.pop() == "(" );
		assert( l1.pop() == "c" );
		assert( l1.pop() == "," );
		assert( l1.pop() == "2" );
		assert( l1.pop() == ")" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "dedent" );
		assert( l1.pop() == "" );
		assert( l1.is_empty() );
	}

	/**
	 * Take the next element. If this empties it, tokenize another line.
	 */
	string pop()
	{
		string token;

		// Take a token
		if ( !tokens.empty() )
		{
			token = tokens.front;
			tokens.removeFront();
		}
		
		// If we're empty, tokenize another line
		if ( tokens.empty() && !is_empty() )
			this.tokenize_line();

		// If this is an indentation token, adjust
		if ( token == "indent" )
			indentation_level += 1;
		else if ( token == "dedent" && indentation_level > 0 )
			indentation_level -= 1;
		
		return token;
	}

	/**
	 * Just lookin'
	 */
	string peek()
	{
		return tokens.front;
	}

	/**
	 * Split the next line into tokens.
	 */
	void tokenize_line()
	{
		string current_line = f.readln();

		// Keep track of which line we're at (for errors and such).
		line_number += 1;

		// Read newlines into a variable, so indentation isn't messed up
		string newlines;
		while ( current_line == "\n" )
		{
			line_number += 1;
			newlines ~= "\n";
			current_line = f.readln();
		}

		// Check for indentation
		auto whitespace_regex = regex( `^[\t| ]*` );
		string whitespace = matchFirst( current_line, whitespace_regex ).hit;

		current_line = replaceFirst( current_line, whitespace_regex, `` );
		int level;
		if ( indentation )
			level = to!int( whitespace.length / indentation.length );
		
		// Check that whitespace is legal
		string whitespace_error = "Whitespace error on line %s";
		if ( level * indentation.length != whitespace.length )
			throw new Exception( format( whitespace_error, line_number ) );
		foreach ( character; whitespace )
			if ( character != whitespace[0] )
				throw new Exception( format( whitespace_error, line_number ) );

		// indentation tokens
		string token;
		if ( level < indentation_level )
			token = "dedent";
		else
			token = "indent";

		foreach ( i; 0 .. abs( level - indentation_level ) )
			tokens.insertFront( token );

		// Check for stuff we won't parse (comments)
		auto block_start = regex( `^(#|passthrough)` );
		if ( !matchFirst( current_line, block_start ).empty )
		{
			// Set the level we can't go past
			block_level = level;

			// First line is indented one less than the rest
			level += 1;
		}

		// If we're in a block that we're not parsing
		if ( level > block_level )
		{
			// Add the newline tokens
			foreach ( count; 0 .. newlines.length )
				tokens.insertBack( "\n" );

			// Parse the block
			parse_block( tokens, current_line );
			
			// That's all folks
			return;
		}
		else
		{
			// Don't allow re-entry into expired blocks
			block_level = MAX_INDENT;
		}

		// Add the newlines back in
		current_line = newlines ~ current_line;

		string[] regexes = [
			`#.*\n`,                          // inline comments
			`".*?"`,                          // string literals
			"`.*?`",
			`'\\?.'`,                         // character literals
			`\d[0-9_]*\.?[0-9_]*e?-?[0-9_]*`, // number literals
			`less than`,                      // two-word tokens
			`more than`,
			`equal to`,
			`has key`,
			`[A-Za-z][A-Za-z_0-9]*`,          // identifiers and keywords
			`->`,                             // function return
			`<-`,                             // inheritance
			`\.\.`,                           // range and slice operator
			`[+*%/~^&|-]?=`,                  // assignment operators
			`[.,!:\[\]{}()+*~/%\n^$-;&|]`     // punctuation and operators
		];
		/// The almighty token regex
		auto r = regex( join( regexes, "|" ) );
		auto c = matchAll( current_line, r );
		foreach ( hit; c )
		{
			if ( hit[0][0] == '#' )
				parse_block( tokens, hit[0] );
			else if ( hit[0] == ";" )
				throw new Exception( format( "Illegal ';' line %s", line_number ) );
			else
				tokens.insertBack( hit[0] );
		}
	}

	void parse_block( ref DList!string tokens, string block )
	{
		if ( block[0] == '#' )
		{
			string token = "#";
			if ( block[1] == '.' )
				token = "#.";

			tokens.insertBack( token );
			string inside = strip( block[token.length .. $-1] );
			tokens.insertBack( inside );
		}
		else if ( startsWith( block, "passthrough" ) )
		{
			tokens.insertBack( "passthrough" );
			tokens.insertBack( block[11 .. $-1] );
		}
		else
		{
			tokens.insertBack( block[0 .. $-1] );
		}
		
		tokens.insertBack( "\n" );
	}


	/**
	 * Are we out of tokens?
	 */
	bool is_empty()
	{
		return tokens.empty() && f.eof();
	}
}
