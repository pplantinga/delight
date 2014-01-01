import std.stdio;
import std.regex;
import std.container;

class lexer
{
	int line_number = 1;
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
		while ( !indentation )
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
		if ( tokens.empty() )
			this.tokenize_line();

		string token;

		if ( !tokens.empty() )
		{
			token = tokens.front;
			tokens.removeFront();
		}
		
		return token;
	}

	void tokenize_line()
	{
		string current_line = f.readln();
		line_number += 1;
	
		// Check for indentation
		int level;
		if ( indentation.length < current_line.length )
		{
			while ( current_line[0 .. indentation.length] == indentation )
			{
				level += 1;

				// remove token
				current_line = current_line[indentation.length .. $];
			}
		}

		string token;

		// indentation token
		if ( level )
		{
			foreach ( i; 0 .. level )
				token = token ~ indentation;
			tokens.insertFront( token );
		}

		auto r = regex( `".*"|'.'|[A-Za-z_]+|[0-9.]+|[.,:\[\]()+*/=%\n -]` );
		while ( current_line != "" )
		{
			auto c = match( current_line, r ).captures;
			current_line = current_line[c.hit.length .. $];
			tokens.insertAfter( tokens[], c.hit );
		}
	}

	bool is_empty()
	{
		return f.eof();
	}
}
