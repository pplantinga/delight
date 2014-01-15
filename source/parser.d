/**
 * A parser for the "Delight" programming language.
 * Author: Peter Plantinga
 *
 * This "Delightful" parser
 * - is initialized with a string
 *   containing the name of the source code file
 * - breaks code into tokens with a lexer
 * - checks for syntax errors in the source code
 * - generates valid d code
 */
import lexer;
import std.algorithm;
import std.conv;
import std.stdio;
import std.range;
import std.array;
import std.file;
import std.regex;
import std.string;

class parser
{
	/** Breaks source code into tokens */
	lexer l;

	/** These give a new value to a variable */
	static immutable string[] assignment_operators = [
		"=",
		"+=",
		"-=",
		"*=",
		"/=",
		"%=",
		"~=",
		"^="
	];
	
	/** These are used when declaring things. */
	static immutable string[] attributes = [
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

	/** Function types. */
	static immutable string[] function_types = [
		"function",
		"method",
		"procedure"
	];

	/** Compare and contrast, producing booleans. */
	static immutable string[] logical = [
		"and",
		"equals",
		"is",
		"less than",
		"more than",
		"lambda",
		"not",
		"or"
	];

	/** All about combining literals and variables creating expressions. */
	static immutable string[] operators = [
		"+",
		"-",
		"*",
		"/",
		"%",
		"~",
		"^"
	];

	/** These do weird stuff. */
	static immutable string[] punctuation = [
		",",
		".",
		":",
		"(",
		")",
		"[",
		"]",
		"\"",
		"'",
		"#",
		"#.",
		"->"
	];

	/** These do things. */
	static immutable string[] statements = [
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

	/** How is stuff stored in memory? */
	static immutable string[] types = [
		"auto", "bool", "void", "string",
		"byte", "short", "int", "long", "cent",
		"ubyte", "ushort", "uint", "ulong", "ucent",
		"float", "double", "real",
		"ifloat", "idouble", "ireal",
		"cfloat", "cdouble", "creal",
		"char", "wchar", "dchar"
	];

	/** More complicated types. */
	static immutable string[] user_types = [
		"alias",
		"class",
		"enum",
		"struct",
		"union"
	];

	/** Initialize with a string containing location of source code. */
	this( string filename )
	{
		/** Lexer parses source into tokens */
		l = new lexer( filename );
	}

	/** What kind of thing is this token? */
	string identify_token( string token )
	{
		auto space = regex( `^\n|indent [+-]1$` );
		auto sl = regex( `^".*"$` );
		auto cl = regex( `^'\\?.'$` );
		auto nl = regex( `^[0-9]+.?[0-9]*$` );
		auto tt = regex( `^[A-Z]$` );

		if ( !matchFirst( token, space ).empty )
			return token;
		else if ( !matchFirst( token, sl ).empty )
			return "string literal";
		else if ( !matchFirst( token, cl ).empty )
			return "character literal";
		else if ( !matchFirst( token, nl ).empty )
			return "number literal";
		else if ( !matchFirst( token, tt ).empty )
			return "template type";
		else if ( count( assignment_operators, token ) )
			return "assignment operator";
		else if ( count( attributes, token ) )
			return "attribute";
		else if ( count( function_types, token ) )
			return "function type";
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
	unittest
	{
		writeln( "identify_token import" );
		parser p = new parser( "tests/import.delight" );
		assert( p.identify_token( "\n" ) == "\n" );
		assert( p.identify_token( "indent -1" ) == "indent -1" );
		assert( p.identify_token( "\"\"" ) == "string literal" );
		assert( p.identify_token( "\"string\"" ) == "string literal" );
		assert( p.identify_token( "'a'" ) == "character literal" );
		assert( p.identify_token( "'\\n'" ) == "character literal" );
		assert( p.identify_token( "5" ) == "number literal" );
		assert( p.identify_token( "5.2" ) == "number literal" );
		assert( p.identify_token( "T" ) == "template type" );
		assert( p.identify_token( "=" ) == "assignment operator" );
		assert( p.identify_token( "+=" ) == "assignment operator" );
		assert( p.identify_token( "%=" ) == "assignment operator" );
		assert( p.identify_token( "~=" ) == "assignment operator" );
		assert( p.identify_token( "pure" ) == "attribute" );
		assert( p.identify_token( "and" ) == "logical" );
		assert( p.identify_token( "less than" ) == "logical" );
		assert( p.identify_token( "-" ) == "operator" );
		assert( p.identify_token( "^" ) == "operator" );
		assert( p.identify_token( "." ) == "punctuation" );
		assert( p.identify_token( ":" ) == "punctuation" );
		assert( p.identify_token( "foreach" ) == "statement" );
		assert( p.identify_token( "try" ) == "statement" );
		assert( p.identify_token( "char" ) == "type" );
		assert( p.identify_token( "string" ) == "type" );
		assert( p.identify_token( "int" ) == "type" );
		assert( p.identify_token( "long" ) == "type" );
		assert( p.identify_token( "class" ) == "user type" );
		assert( p.identify_token( "asdf" ) == "identifier" );
	}
	
	string parse()
	{
		string result;

		while ( !l.is_empty() )
		{
			try
			{
				result ~= start_state( l.pop() );
			}
			// Catch exceptions generated by parse and output them
			catch ( Exception e )
			{
				writeln( e.msg );
				debug writeln( e );
				return result;
			}
		}

		return result;
	}
	unittest
	{
		writeln( "Parsing import test" );
		parser p = new parser( "tests/import.delight" );
		auto result = read( "tests/import.d" );
		assert( p.parse() == result );

		writeln( "Parsing comments test" );
		p = new parser( "tests/comments.delight" );
		result = read( "tests/comments.d" );
		assert( p.parse() == result );

		writeln( "Parsing assignment test" );
		p = new parser( "tests/assignment.delight" );
		result = read( "tests/assignment.d" );
		assert( p.parse() == result );

		writeln( "Parsing indent test" );
		p = new parser( "tests/indent.delight" );
		result = read( "tests/indent.d" );
		assert( p.parse() == result );

		writeln( "Parsing functions test" );
		p = new parser( "tests/functions.delight" );
		result = read( "tests/functions.d" );
		assert( p.parse() == result );
	}

	/** The starting state for the parser */
	string start_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "statement":
				if ( token == "import" )
					return token ~ " " ~ library_state( l.pop() );
				else
					return token ~ " " ~ expression_state( l.pop() ) ~ ";";
			case "type":
				return token ~ " " ~ declare_state( l.pop() );
			case "function type":
				return function_declaration_state( token );
			case "\n":
				string endline = endline();
				if ( l.peek() == "#" || l.peek() == "#." )
					return endline ~ block_comment_state( l.pop() );
				else
					return endline;
			case "identifier":
				return token ~ identifier_state( l.pop() );
			case "indent +1":
				return "{" ~ endline();
			case "indent -1":
				return "}" ~ endline();
			case "punctuation":
				if ( token == "#" || token == "#." )
					return inline_comment_state( token );
				else
					throw new Exception( unexpected( token ) );
			default:
				throw new Exception( unexpected( token ) );
		}
	}

	/** This state takes care of stuff after an import */
	string library_state( string token )
	{
		if ( identify_token( token ) != "identifier" )
			throw new Exception( unexpected( token ) );

		string result = token;

		while ( l.peek() == "." )
		{
			result ~= l.pop();

			if ( identify_token( l.peek() ) != "identifier" )
				throw new Exception( unexpected( token ) );

			result ~= l.pop();
		}

		return result ~ endline_state( l.pop() );
	}

	/** This state takes care of variable declaration */
	string declare_state( string token )
	{
		if ( identify_token( token ) != "identifier" )
			throw new Exception( unexpected( token ) );

		string result = token;

		token = l.pop();

		switch ( identify_token( token ) )
		{
			case "assignment operator":
				return result ~ " " ~ token ~ " " ~ expression_state( l.pop() ) ~ ";";
			case "\n":
				return result ~ ";" ~ endline();
			default:
				throw new Exception( unexpected( token ) );
		}
	}

	/** This state takes care of function declaration */
	string function_declaration_state( string token )
	{
		// First check if we're a function, method, or procedure
		string start;
		bool is_function, is_method, is_procedure = false;
		switch ( token )
		{
			case "function":
				is_function = true;
				start = "pure ";
				break;
			case "method":
				is_method = true;
				start = "";
				break;
			case "procedure":
				is_procedure = true;
				start = "void";
				break;
			default:
				throw new Exception( unexpected( token ) );
		}

		// Must call the function something
		if ( identify_token( l.peek() ) != "identifier" )
			throw new Exception( unexpected( l.peek() ) );

		string name = l.pop();
		string args, template_args, return_type;

		if ( l.peek() == "(" )
		{
			args = parse_args( l.pop() );
			return_type = parse_return_type( l.pop );

			// Procedures have no return type
			if ( !return_type && !is_procedure )
				return_type = "auto";
		}
		
		// Function declarations must end with colon
		string colon = l.pop();
		if ( colon == ":" )
			return start ~ return_type ~ " " ~ name ~ "(" ~ args ~ ")";
		else
			throw new Exception( unexpected( colon ) );
	}

	/** This parses args to functions of form "(int a, b, T t..." */
	string parse_args( string token )
	{
		// Function params must start with "("
		if ( token != "(" )
			throw new Exception( unexpected( token ) );

		string result;
		string template_types;

		// For each type we encounter
		while ( identify_token( l.peek() ) == "type"
				|| identify_token( l.peek() ) == "template type" )
		{
			// If we don't have this template type yet, add it to collection
			if ( identify_token( l.peek() ) == "template type"
					&& std.string.indexOf( template_types, l.peek()[0] ) == -1 )
				template_types ~= l.peek() ~ ", ";

			string type = l.pop();

			// For each identifier we encounter
			while ( identify_token( l.peek() ) == "identifier" )
			{
				string var = l.pop();
				if ( l.peek() == "," )
					result ~= type ~ " " ~ var ~ l.pop() ~ " ";
				else
					result ~= type ~ " " ~ var;
			}
		}

		// Add template types (minus the ending comma)
		if ( template_types )
			result = chomp( template_types, ", " ) ~ ")(" ~ result;

		return result;
	}

	/** Parse return type. If none, return auto */
	string parse_return_type( string token )
	{
		// no return type, guess
		if ( token == ")" )
			return "auto";
		
		// return type must start with "-> type"
		if ( token != "->" )
			throw new Exception( unexpected( token ) );

		if ( identify_token( l.peek() ) != "type" )
			throw new Exception( unexpected( l.peek() ) );

		string type = l.pop();
		string next = l.pop();

		// We're done, make sure the function def is done
		if ( next != ")" )
			throw new Exception( unexpected( next ) );

		return type;
	}

	/** Determine if we're calling a function or assigning to a varible */
	string identifier_state( string token )
	{
		switch ( identify_token( token ) )
		{
			// calling a function
			case "punctuation":
				if ( token == "(" )
					return token ~ function_call_state( l.pop() ) ~ ";";
				else
					throw new Exception( unexpected( token ) );
			
			// assigning a variable
			case "assignment operator":
				return " " ~ token ~ " " ~ expression_state( l.pop() ) ~ ";";
			default:
				throw new Exception( unexpected( token ) );
		}
	}

	/** Function call state */
	string function_call_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "string literal":
			case "character literal":
			case "number literal":
			case "identifier":
				string next = l.pop();
				if ( next == "," )
					return token ~ ", " ~ function_call_state( l.pop() );
				else if ( next == ")" )
					return token ~ ")";
				else
					throw new Exception( unexpected( next ) );
			default:
				throw new Exception( unexpected( token ) );
		}
	}

	/** Expression state */
	string expression_state( string token )
	{
		string expression;
		switch ( identify_token( token ) )
		{
			case "string literal":
			case "character literal":
			case "number literal":
			case "identifier":
				expression = token;
				if ( identify_token( token ) == "identifier" && l.peek() == "(" )
				{
					l.pop();
					expression ~= "(" ~ function_call_state( l.pop() );
				}
				break;
			case "punctuation":
				// sub-expression in parentheses
				if ( token == "(" )
					expression = token ~ expression_state( l.pop() );
				else
					throw new Exception( unexpected( token ) );
				break;
			default:
				throw new Exception( unexpected( token ) );
		}

		if ( identify_token( l.peek() ) == "operator" )
		{
			string op = l.pop();
			return expression ~ " " ~ op ~ " " ~ expression_state( l.pop() );
		}

		switch ( l.peek() )
		{
			case ")":
				return expression ~ l.pop();
			case "\n":
			case "#":
			case "#.":
				return expression;
			default:
				throw new Exception( unexpected( l.peek() ) );
		}
	}

	/** Expecting the end of a line */
	string endline_state( string token )
	{
		if ( token == "\n" )
			return ";" ~ endline();
		else
			throw new Exception( unexpected( token ) );
	}

	/** Block comments eat the rest of the input until it un-indents */
	string block_comment_state( string token )
	{
		string indent = join( repeat( l.indentation, l.block_comment_level ) );
		
		// Do the whole first line at once
		string line = l.pop();
		string newline = l.pop();
		string result = endline() ~ " +" ~ line ~ newline ~ indent ~ " +";
		if ( token == "#" )
			result = "/+" ~ result;
		else if ( token == "#." )
			result = "/++" ~ result;

		if ( l.peek() == "indent +1" )
		{
			l.pop();
			string inside;
			int level = 1;
			while ( level > 0 )
			{
				/// Indentation inside the block
				/// Use 2 spaces cuz we're inside the comment, tabs can mess up
				inside = join( repeat( "  ", level - 1 ) );
				
				token = l.pop();
				if ( token == "\n" )
					result ~= "\n" ~ indent ~ " +";
				else if ( token == "indent +1" )
					level += 1;
				else if ( token == "indent -1" )
					level -= 1;
				else
					result ~= " " ~ inside ~ token;
			}
		}

		return result ~= "/" ~ endline();
	}

	/** Inline comments just eat the rest of the line */
	string inline_comment_state( string token )
	{
		string result;
		if ( token == "#" )
			result = "//";
		else if ( token == "#." )
			result = "///";
		else
			throw new Exception( unexpected( token ) );

		result ~= l.pop();
		string newline = l.pop();
		if ( newline == "\n" )
			return result ~ endline();
		else
			throw new Exception( unexpected( newline ) );
	}

	/** New line, plus indentation */
	string endline()
	{
		int level = l.indentation_level;

		// Since the indentation level doesn't get changed till after
		// the pop, we'll need to shift the indentation here
		if ( !l.is_empty() && l.peek() == "indent -1" )
			level -= 1;
		
		return "\n" ~ join( repeat( l.indentation, level ) );
	}

	/**
	 * We didn't expect to find this kind of token!
	 * so generate an exception.
	 */
	string unexpected( string token )
	{
		return "On line " ~ to!string( l.line_number ) ~ ": unexpected " ~ identify_token( token ) ~ " '" ~ token ~ "'";
	}
}
