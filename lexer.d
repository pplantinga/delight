import std.stdio;
import std.regex;

class lexer
{
	int line_number = 1;
	string current_line;
	string indentation;
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
		while ( !indentation )
		{
			current_line = f.readln().dup;
			auto c = match( current_line, r ).captures;
			if ( !c.empty() )
				indentation = c[1];
		}

		// Go back to beginning
		f.rewind();
		this.parse_line();
	}

	string pop()
	{
		if ( !current_line )
			this.parse_line();

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

		// return whitespace token
		writeln( level );
		if ( level )
		{
			foreach ( i; 0 .. level )
				token = token ~ indentation;
			writeln( token );
			return token;
		}

		// TODO: Do some tokenizing magic
		token = current_line;
		current_line = null;

		return token;
	}

	void parse_line()
	{
		current_line = f.readln().dup;
		line_number += 1;
	}

	bool is_empty()
	{
		return f.eof();
	}
}
