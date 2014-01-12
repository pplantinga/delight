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
import std.stdio;
import std.regex;
import std.container;
import std.conv;
import std.math;
import std.file;

class lexer
{
	int line_number;
	int indentation_level;
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
		this.tokenize_line();
	}
	unittest
	{
		writeln( "Lexing test2" );
		lexer l1 = new lexer( "tests/test2.delight" );
		assert( l1.indentation == "\t" );
		assert( !l1.is_empty() );
		assert( l1.peek() == "procedure" );
		assert( l1.pop() == "procedure" );
		assert( l1.pop() == "main" );
		assert( l1.pop() == ":" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "indent +1" );
		assert( l1.pop() == "int" );
		assert( l1.pop() == "x" );
		assert( l1.pop() == "=" );
		assert( l1.pop() == "5" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "indent -1" );
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
		if ( token == "indent +1" )
			indentation_level += 1;
		else if ( token == "indent -1" && indentation_level > 0 )
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
	
		// Check for indentation
		int level;
		if ( indentation && indentation.length < current_line.length )
		{
			while ( current_line[0 .. indentation.length] == indentation )
			{
				level += 1;

				// remove token
				current_line = current_line[indentation.length .. $];
			}
		}


		// indentation tokens
		string token;
		if ( level < indentation_level )
			token = "indent -1";
		else if ( level > indentation_level )
			token = "indent +1";

		for ( int i = 0; i < abs( level - indentation_level ); i++ )
			tokens.insertFront( token );

		/**
		 * The almighty token regex. It matches:
		 * - ".*" (string literals)
		 * - '\.' (character literals)
		 * - [A-Za-z_]+ (identifiers and keywords)
		 * - [0-9.]+ (number literals)
		 * - [+%/*^~-]?= (assignment operators)
		 * - -> (what a function returns)
		 * - [.,:\[\]()+*~/%\n^-] (punctuation and operators)
		 */
		auto r = regex( `".*"|'\.'|[A-Za-z_]+|[0-9.]+|[+*/%~^-]?=|->|[.,:\[\]()+*/~%\n^-]` );
		auto c = matchAll( current_line, r );
		foreach ( hit; c )
			tokens.insertBack( hit );
	}

	/**
	 * Are we out of tokens?
	 */
	bool is_empty()
	{
		return tokens.empty() && f.eof();
	}
}
