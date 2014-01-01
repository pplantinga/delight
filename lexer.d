import std.stdio;
import std.regex;
import std.container;

class lexer
{
	int line_number = 1;
	string indentation;
	SList!string tokens;
	File f;

	immutable string[] assignment_operators = [
		"=",
		"+=",
		"-=",
		"*=",
		"/=",
		"%=",
		"~=",
		"^^="
	];
	
	immutable string[] attributes = [
		"abstract",
		"const",
		"immutable",
		"in",
		"inout",
		"lazy",
		"nothrow",
		"out",
		"override",
		"pure",
		"ref",
		"shared",
		"static",
		"synchronized"
	];

	immutable string[] logical = [
		"and",
		"equals",
		"is",
		"less than",
		"more than",
		"not",
		"or"
	];

	immutable string[] statements = [
		"assert",
		"break",
		"catch",
		"continue",
		"do",
		"finally",
		"foreach",
		"foreach_reverse",
		"import",
		"mixin",
		"return",
		"switch",
		"throw",
		"try",
		"typeof"
		"while"
	];

	immutable string[] operators = [
		"+",
		"-",
		"*",
		"/",
		"%",
		"~",
		"^^"
	];

	immutable string[] punctuation = [
		",",
		".",
		":",
		"(",
		")",
		"[",
		"]",
		"\"",
		"'"
	];

	immutable string[] types = [
		"auto", "bool",
		"byte", "short", "int", "long", "cent",
		"ubyte", "ushort", "uint", "ulong", "ucent",
		"float", "double", "real",
		"ifloat", "idouble", "ireal",
		"cfloat", "cdouble", "creal",
		"char", "wchar", "dchar"
	];

	immutable string[] user_type = [
		"alias",
		"class",
		"enum",
		"struct",
		"union"
	];

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

		// whitespace token
		if ( level )
		{
			foreach ( i; 0 .. level )
				token = token ~ indentation;
			tokens.insertFront( token );
		}

		// TODO: more intelligent tokenization
		auto r = regex( " " );
		tokens.insertAfter( tokens[], split( current_line, r ) );
	}

	bool is_empty()
	{
		return f.eof();
	}
}
