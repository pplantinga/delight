import std.stdio;
import std.regex;
import std.container;
import std.conv;
import std.math;

class lexer
{
	int line_number;
	int indentation_level;
	string indentation;
	SList!string tokens;
	File f;

	this( string filename )
	{
		// Open file for reading
		f = File( filename, "r" );

		// Find out what the file uses for indentation
		auto r = regex( "^( +|\t)[^ \t]" );
		string current_line;
		while ( !indentation && !f.eof() )
		{
			current_line = f.readln();
			auto c = match( current_line, r ).captures;
			if ( !c.empty() )
				indentation = c[1];
		}

		// Go back to beginning
		f.rewind();
		this.tokenize_line();
	}

	string pop()
	{
		string token;

		if ( !tokens.empty() )
		{
			token = tokens.front;
			tokens.removeFront();
		}
		
		if ( tokens.empty() )
			this.tokenize_line();
		
		return token;
	}

	void tokenize_line()
	{
		string current_line = f.readln();
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
			while ( level != indentation_level )
			{
				tokens.insertFront( "indentation " ~ to!string( direction ) );
				indentation_level += direction;
			}
		}

		auto r = regex( `".*"|'\.'|[A-Za-z_]+|[0-9.]+|[+*/%~^-]?=|[.,:\[\]()+*/=~%\n ^-]` );
		while ( current_line != "" )
		{
			auto c = match( current_line, r ).captures;
			current_line = current_line[c.hit.length .. $];
  		if ( c.hit != " " )
				tokens.insertAfter( tokens[], c.hit );
		}
	}

	bool is_empty()
	{
		return tokens.empty() && f.eof();
	}
}
