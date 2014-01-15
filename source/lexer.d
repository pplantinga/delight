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
import std.array;

class lexer
{
	static immutable MAX_INDENT = 10000;
	int line_number;
	int indentation_level;
	int block_comment_level = MAX_INDENT;
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
		lexer l1 = new lexer( "tests/indent.delight" );
		assert( l1.indentation == "\t" );
		assert( !l1.is_empty() );
		assert( l1.pop() == "begin" );
		assert( l1.peek() == "procedure" );
		assert( l1.pop() == "procedure" );
		assert( l1.pop() == "main" );
		assert( l1.pop() == ":" );
		assert( l1.pop() == "\n" );
		assert( l1.pop() == "indent +1" );
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
		assert( l1.pop() == "indent +1" );
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
		assert( l1.pop() == "indent -1" );
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
		assert( l1.pop() == "d" );
		assert( l1.pop() == "=" );
		assert( l1.pop() == "add" );
		assert( l1.pop() == "(" );
		assert( l1.pop() == "c" );
		assert( l1.pop() == "," );
		assert( l1.pop() == "2" );
		assert( l1.pop() == ")" );
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
		string newlines;
		while ( current_line == "\n" )
		{
			newlines ~= "\n";
			current_line = f.readln();
		}

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

		// Check for block comments
		if ( current_line && current_line[0] == '#' )
		{
			// Set the level we can't go past
			block_comment_level = level;

			// First line is indented one less than the rest
			level += 1;
		}

		// If we're in a block comment
		if ( level > block_comment_level )
		{
			// Add the newline tokens
			foreach ( count; 0 .. newlines.length )
				tokens.insertBack( "\n" );

			// Parse the comment
			parse_comment( tokens, current_line );
			
			// That's all folks
			return;
		}
		else
		{
			// Don't allow re-entry into block comment
			block_comment_level = MAX_INDENT;
		}

		// Add the newlines back in
		current_line = newlines ~ current_line;

		string[] regexes = [
			`#.*\n`,                // inline comments
			`".*"`,                 // string literals
			`'\\?.'`,               // character literals
			`[0-9]+\.?[0-9]*`,      // number literals
			`less than`,            // two-word tokens
			`more than`,
			`[A-Za-z_]+`,           // identifiers and keywords
			`->`,                   // function return
			`[+*%/~^-]?=`,          // assignment operators
			`[.,:\[\]()+*~/%\n^-]`  // punctuation and operators
		];
		/// The almighty token regex
		auto r = regex( join( regexes, "|" ) );
		auto c = matchAll( current_line, r );
		foreach ( hit; c )
		{
			if ( hit[0][0] == '#' )
				parse_comment( tokens, hit[0] );
			else
				tokens.insertBack( hit );
		}
	}

	void parse_comment( ref DList!string tokens, string comment )
	{
		if ( comment[0] == '#' )
		{
			string token = "#";
			if ( comment[1] == '.' )
				token = "#.";

			tokens.insertBack( token );
			tokens.insertBack( comment[token.length .. $-1] );
		}
		else
		{
			tokens.insertBack( comment[0 .. $-1] );
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
