/**
 * Parser takes tokens one at a time and
 * - checks for syntax errors
 * - generates valid d code
 */
import lexer;
import std.algorithm;
import std.conv;
import std.stdio;
import std.range;
import std.array;

class parser
{
	lexer l;

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
		"'",
		"#"
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

	immutable string[] types = [
		"auto", "bool", "void",
		"byte", "short", "int", "long", "cent",
		"ubyte", "ushort", "uint", "ulong", "ucent",
		"float", "double", "real",
		"ifloat", "idouble", "ireal",
		"cfloat", "cdouble", "creal",
		"char", "wchar", "dchar"
	];

	immutable string[] user_types = [
		"alias",
		"class",
		"enum",
		"struct",
		"union"
	];

	this( string filename )
	{
		l = new lexer( filename );
	}

	string identify_symbol( string token )
	{
		if ( count( [
					" ",
					"\n",
					"indentation 1",
					"indentation -1"
					], token ) )
			return token;
		else if ( count( assignment_operators, token ) )
			return "assignment operator";
		else if ( count( attributes, token ) )
			return "attribute";
		else if ( count( logical, token ) )
			return "logical";
		else if ( count( operators, token ) )
			return "operator";
		else if ( count( punctuation, token ) )
			return "punctuation";
		else if ( count( statements, token ) )
			return "statement";
		else if ( count( types, token ) )
			return "type";
		else if ( count( user_types, token ) )
			return "user type";
		else
			return "identifier";
	}
	
	string parse()
	{
		return start_state( l.pop() );
	}

	string start_state( string token )
	{
		if ( l.is_empty() )
		{
			if ( token == "indentation -1" )
				return "}";
			else
				throw unexpected( token );
		}

		string indent = join( repeat( l.indentation, l.indentation_level ) );
		switch ( identify_symbol( token ) )
		{
			case "statement":
				if ( token == "import" )
					return token ~ " " ~ im_state( l.pop() );
				else
					throw unexpected( token );
			case "type":
				return token ~ " " ~ declare_state( l.pop() );
			case "\n":
				return token ~ indent ~ start_state( l.pop() );
			case "identifier":
				return token ~ identifier_state( l.pop() );
			case "indentation 1":
				return "{\n" ~ indent ~ start_state( l.pop() );
			case "indentation -1":
				return "}\n" ~ indent ~ start_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string im_state( string token )
	{
		switch ( identify_symbol( token ) )
		{
			case "identifier":
				return token ~ library_state( l.pop() );
			default:
				throw unexpected( token );
		}
	};

	string library_state( string token )
	{
		switch ( identify_symbol( token ) )
		{
			case "punctuation":
				if ( token == "." )
					return token ~ period_state( l.pop() );
				else
					throw unexpected( token );
			case "\n":
				return ";\n" ~ start_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string period_state( string token )
	{
		switch ( identify_symbol( token ) )
		{
			case "identifier":
				return token ~ library_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string declare_state( string token )
	{
		switch ( identify_symbol( token ) )
		{
			case "identifier":
				return token ~ declared_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string declared_state( string token )
	{
		switch ( identify_symbol( token ) )
		{
			case "punctuation":
				if ( token == "(" )
					return token ~ function_declaration_state( l.pop() );
				else if ( token == "," )
					return token ~ declare_state( l.pop() );
				else
					throw unexpected( token );
			case "\n":
				return ";\n" ~ start_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string function_declaration_state( string token )
	{
		switch ( identify_symbol( token ) )
		{
			case "type":
				return token ~ function_variable_state( l.pop() );
			case "punctuation":
				if ( token == ")" )
					return token ~ colon_state( l.pop() );
				else
					throw unexpected( token );
			default:
				throw unexpected( token );
		}
	}

	string function_variable_state( string token )
	{
		switch ( identify_symbol( token ) )
		{
			case "identifier":
				return token ~ function_declaration_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string colon_state( string token )
	{
		if ( token == ":" )
			return start_state( l.pop() );
		else
			throw new Exception( "On line " ~ to!string( l.line_number ) ~ " expected ':'" );
	}

	string identifier_state( string token )
	{
		switch ( identify_symbol( token ) )
		{
			case "punctuation":
				if ( token == "(" )
					return token ~ function_call_state( l.pop() );
				else
					throw unexpected( token );
			case "assignment_operator":
				return token ~ assignment_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string function_call_state( string token )
	{
		switch ( identify_symbol( token ) )
		{
			case "identifier":
				return token ~ function_call_state( l.pop() );
			case "punctuation":
				if ( token == ")" )
					return token ~ endline_state( l.pop() );
				else
					throw unexpected( token );
			default:
				throw unexpected( token );
		}
	}

	string assignment_state( string token )
	{
		switch ( identify_symbol( token ) )
		{
			case "identifier":
				return token ~ endline_state( l.pop() );
			default:
				throw unexpected( token );
		}
	}

	string endline_state( string token )
	{
		if ( token == "\n" )
			return ";\n" ~ start_state( l.pop() );
		else
			throw unexpected( token );
	}

	Exception unexpected( string token )
	{
		return new Exception( "On line " ~ to!string( l.line_number ) ~ ": unexpected token '" ~ token ~ "'" );
	}
}
