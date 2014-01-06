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
	SList!string tokens;
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
			auto c = match( current_line, r ).captures;
			if ( !c.empty() )
				indentation = c[1];
		}

		// Go back to the beginning of the file
		f.rewind();
		this.tokenize_line();
	}
	unittest
	{
		auto f1 = File( "test1.delight", "w" );
		f1.write( "void main():\n\tint x = 5\n" );
		f1.close();
		lexer l1 = new lexer( "test1.delight" );
		assert( l1.indentation == "\t" );
		assert( !l1.is_empty() );
		assert( l1.pop() == "void" );
		assert( l1.pop() == "main" );
		assert( l1.pop() == "(" );
		assert( l1.pop() == ")" );
		assert( l1.pop() == ":" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "indentation 1" );
		assert( l1.pop() == "int" );
		assert( l1.pop() == "x" );
		assert( l1.pop() == "=" );
		assert( l1.pop() == "5" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "indentation -1" );
		assert( l1.pop() == "" );
		assert( l1.is_empty() );
		std.file.remove( "test1.delight" );

		auto f2 = File( "test2.delight", "w" );
		f2.write( "void main():\n  double x += 0.2\n" );
		f2.close();
		lexer l2 = new lexer( "test2.delight" );
		assert( l2.indentation == "  " );
		assert( !l2.is_empty() );
		l2.pop();
		l2.pop();
		l2.pop();
		l2.pop();
		l2.pop();
		l2.pop();
		assert( l2.pop() == "indentation 1" );
		assert( l2.pop() == "double" );
		assert( l2.pop() == "x" );
		assert( l2.pop() == "+=" );
		assert( l2.pop() == "0.2" );
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
		if ( tokens.empty() )
			this.tokenize_line();
		
		return token;
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

		string token;

		// indentation tokens
		if ( level != indentation_level )
		{
			auto amount = level - indentation_level;
			auto direction = amount / abs( amount );

			// Keep track of which indentation level we're at
			while ( level != indentation_level )
			{
				tokens.insertFront( "indentation " ~ to!string( direction ) );
				indentation_level += direction;
			}
		}

		/**
		 * The almighty token regex. It matches:
		 * - ".*" (string literals)
		 * - '\.' (character literals)
		 * - [A-Za-z_]+ (identifiers and keywords)
		 * - [0-9.]+ (number literals)
		 * - [+%/*^~-]?= (assignment operators)
		 * - -> (what a function returns)
		 * - [.,:\[\]()+*~/%\n ^-] (punctuation and operators)
		 */
		auto r = regex( `".*"|'\.'|[A-Za-z_]+|[0-9.]+|[+*/%~^-]?=|->|[.,:\[\]()+*/~%\n ^-]` );
		while ( current_line != "" )
		{
			auto c = match( current_line, r ).captures;
			current_line = current_line[c.hit.length .. $];
  		if ( c.hit != " " )
				tokens.insertAfter( tokens[], c.hit );
		}
	}

	/**
	 * Are we out of tokens?
	 */
	bool is_empty()
	{
		return tokens.empty() && f.eof();
	}
}
