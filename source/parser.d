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
import std.conv : to;
import std.stdio : writeln;
import std.range : repeat;
import std.regex;
import std.string;
import std.algorithm : canFind;
import std.container : SList;

class parser
{
	/// Breaks source code into tokens
	lexer l;

	/// Stores regexes for determining what tokens are
	Regex!char[string] symbol_regexes;

	/// Keeps track of the current context
	SList!string context;

	/// These are used when declaring things.
	auto attribute_regex = regex( "^(" ~ join( [
		"abstract",
		"const",
		"immutable",
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
	], "|" ) ~ ")$" );

	/// Compare and contrast, producing booleans.
	auto comparator_regex = regex( "^(" ~ join( [
		"equal to",
		"in",
		"is",
		"less than",
		"more than",
		"not"
	], "|" ) ~ ")$" );

	/// Statements used for branching
	auto conditional_regex = regex( "^(" ~ join( [
		"if",
		"else"
	], "|" ) ~ ")$" );

	/// Function types.
	auto function_type_regex = regex( "^(" ~ join( [
		"function",
		"method",
		"procedure"
	], "|" ) ~ ")$" );

	/// join comparisons
	auto logical_regex = regex( "^(" ~ join( [
		"and",
		"or"
	], "|" ) ~ ")$" );

	/// These do things.
	auto statement_regex = regex( "^(" ~ join( [
		"assert",
		"break",
		"catch",
		"continue",
		"finally",
		"for",
		"import",
		"mixin",
		"return",
		"switch",
		"throw",
		"try",
		"typeof",
		"while"
	], "|" ) ~ ")$" );

	/// How is stuff stored in memory?
	auto type_regex = regex( "^(" ~ join( [
		"auto", "bool", "void", "string",
		"byte", "short", "int", "long", "cent",
		"ubyte", "ushort", "uint", "ulong", "ucent",
		"float", "double", "real",
		"ifloat", "idouble", "ireal",
		"cfloat", "cdouble", "creal",
		"char", "wchar", "dchar"
	], "|" ) ~ ")$" );

	/// More complicated types.
	auto user_type_regex = regex( "^(" ~ join( [
		"alias",
		"class",
		"enum",
		"struct",
		"union"
	], "|" ) ~ ")$" );

	/**
	 * Constructor takes a string containing location of source code
	 * and generates a lexer for creating tokens out of text
	 * and a symbol regex array
	 */
	this( string filename )
	{
		/// Lexer parses source into tokens
		l = new lexer( filename );

		/// Unfortunately, associative array literals
		/// can only happen inside a function in D
		symbol_regexes = [
			"assignment operator" : regex( `^[+*%^/~-]?=$` ),
			"attribute"           : attribute_regex,
			"character literal"   : regex( `^'\\?.'$` ),
			"comparator"          : comparator_regex,
			"conditional"         : conditional_regex,
			"function type"       : function_type_regex,
			"logical"             : logical_regex,
			"newline"             : regex( `^(\n|indent [+-]1|begin)$` ),
			"number literal"      : regex( `^[0-9]+.?[0-9]*$` ),
			"operator"            : regex( `^[+*%^/~-]$` ),
			"punctuation"         : regex( `^([.,:()\[\]#]|\.\.|#\.|->)$` ),
			"statement"           : statement_regex,
			"string literal"      : regex( `^".*"$` ),
			"template type"       : regex( `^[A-Z]$` ),
			"type"                : type_regex,
			"user type"           : user_type_regex
		];

		// Add a beginning symbol to the context stack
		context.insertFront( "start" );
	}

	/**
	 * Find the symbol associated with a token
	 */
	string identify_token( string token )
	{
		// Try to match the token to a symbol
		foreach ( symbol, symbol_regex; symbol_regexes )
			if ( !matchFirst( token, symbol_regex ).empty )
				return symbol;
		
		// If we don't match anything else, we're an identifier
		return "identifier";
	}
	unittest
	{
		writeln( "identify_token import" );
		parser p = new parser( "tests/import.delight" );
		assert( p.identify_token( "\n" ) == "newline" );
		assert( p.identify_token( "indent -1" ) == "newline" );
		assert( p.identify_token( "begin" ) == "newline" );
		assert( p.identify_token( `""` ) == "string literal" );
		assert( p.identify_token( `"string"` ) == "string literal" );
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
		assert( p.identify_token( "if" ) == "conditional" );
		assert( p.identify_token( "else" ) == "conditional" );
		assert( p.identify_token( "and" ) == "logical" );
		assert( p.identify_token( "less than" ) == "comparator" );
		assert( p.identify_token( "-" ) == "operator" );
		assert( p.identify_token( "^" ) == "operator" );
		assert( p.identify_token( "." ) == "punctuation" );
		assert( p.identify_token( ":" ) == "punctuation" );
		assert( p.identify_token( "#" ) == "punctuation" );
		assert( p.identify_token( "#." ) == "punctuation" );
		assert( p.identify_token( "->" ) == "punctuation" );
		assert( p.identify_token( ".." ) == "punctuation" );
		assert( p.identify_token( "for" ) == "statement" );
		assert( p.identify_token( "try" ) == "statement" );
		assert( p.identify_token( "char" ) == "type" );
		assert( p.identify_token( "string" ) == "type" );
		assert( p.identify_token( "int" ) == "type" );
		assert( p.identify_token( "long" ) == "type" );
		assert( p.identify_token( "class" ) == "user type" );
		assert( p.identify_token( "asdf" ) == "identifier" );
	}
	
	/**
	 * The parse function takes tokens from the lexer
	 * and passes them to the start state one at a time.
	 *
	 * The end result should be valid D code.
	 */
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
		import std.file : read;

		string[] tests = [
			"import",
			"comments",
			"assignment",
			"indent",
			"functions",
			"conditionals",
			"arrays",
			"loops"
		];

		foreach ( test; tests )
		{
			writeln( "Parsing " ~ test ~ " test" );
			parser p = new parser( "tests/" ~ test ~ ".delight" );
			auto result = read( "tests/" ~ test ~ ".d" );
			assert( p.parse() == result );
		}
	}

	/// The starting state for the parser
	string start_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "statement":
				if ( token == "import" )
					return token ~ " " ~ library_state( l.pop() );
				else if ( token == "for" )
					return "foreach (" ~ foreach_state( l.pop() ) ~ ")";
				else if ( token == "while" )
					return "while (" ~ while_state( l.pop() ) ~ ")";
				else
					return token ~ " " ~ expression_state( l.pop() ) ~ ";";
			case "conditional":
				return conditional_state( token );
			case "type":
				return token ~ declare_state( l.pop() );
			case "function type":
				return function_declaration_state( token );
			case "identifier":
				return token ~ identifier_state( l.pop() );
			case "punctuation":
				if ( token == "#" || token == "#." )
					return inline_comment_state( token );
				else
					throw new Exception( unexpected( token ) );
			case "newline":
				return newline_state( token );
			default:
				throw new Exception( unexpected( token ) );
		}
	}

	/// This state takes care of stuff after an import
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

		if ( l.peek() == ":" )
		{
			result ~= l.pop() ~ " ";
			
			while ( l.peek() != "\n" )
			{
				if ( identify_token( l.peek() ) == "identifier" )
					result ~= l.pop();
				else
					throw new Exception( unexpected( l.peek() ) );

				if ( l.peek() == "," )
					result ~= l.pop() ~ " ";
			}
		}

		return result ~ endline_state( l.pop() );
	}

	/// Default loop state. Form is "for key, item in array"
	string foreach_state( string token )
	{
		context.insertFront( "foreach" );
		if ( identify_token( token ) != "identifier" )
			throw new Exception( unexpected( token ) );

		string result = token;
		if ( l.peek() == "," )
		{
			result ~= l.pop();
			if ( identify_token( l.peek() ) != "identifier" )
				throw new Exception( unexpected( l.peek() ) );
			result ~= l.pop();
		}

		if ( l.peek() != "in" )
			throw new Exception( expected( "in", l.peek() ) );

		l.pop();
		result ~= "; ";

		if ( identify_token( l.peek() ) == "number literal" )
		{
			result ~= l.pop();

			if ( l.peek() != ".." )
				throw new Exception( expected( "..", l.peek() ) );

			result ~= " " ~ l.pop() ~ " ";

			if ( identify_token( l.peek() ) != "number literal" )
				throw new Exception( unexpected( l.peek() ) );
		}
		else if ( identify_token( l.peek() ) != "identifier" )
		{
			throw new Exception( unexpected( l.peek() ) );
		}

		result ~= l.pop();

		if ( l.peek() != ":" )
			throw new Exception( expected( ":", l.peek() ) );

		l.pop();

		return result;
	}

	string while_state( string token )
	{
		context.insertFront( "while" );

		string expression = expression_state( token );

		if ( l.peek() != ":" )
			throw new Exception( expected( ":", l.peek() ) );

		l.pop();

		return expression;
	}

	/// Control branching
	string conditional_state( string token )
	{
		string next = l.pop();

		if ( token == "if" )
			context.insertFront( "if" );
		else if ( token != "if" && context.front != "if" )
			throw new Exception( unexpected( token ) );

		// if, else if, else behavior
		string condition;
		if ( token == "if" )
			condition = "if (" ~ expression_state( next ) ~ ")";
		else if ( token == "else" && next == "if" )
			condition = "else if (" ~ expression_state( l.pop() ) ~ ")";
		else if ( token == "else" )
			condition = token;
		else
			throw new Exception( unexpected( token ) );
		
		// Check for colon after conditional
		string colon;
		if ( token == "else" && next != "if" )
			colon = next;
		else
			colon = l.pop();

		if ( colon != ":" )
			throw new Exception( expected( ":", colon ) );

		return condition;
	}

	/// This state takes care of variable declaration
	string declare_state( string token )
	{
		string result;

		// Array declarations
		if ( token == "[" )
		{
			result = "[";

			while ( identify_token( token ) != "identifier" )
			{
				if ( identify_token( token ) == "number literal"
						|| identify_token( token ) == "type" )
					result ~= token;

				string next = l.pop();
				if ( next == "," )
					result ~= "][";
				else if ( next == "]" )
					result ~= "]";
				else
					throw new Exception( expected( ",' or ']", next ) );

				token = l.pop();
			}
		}
		else if ( identify_token( token ) != "identifier" )
		{
			throw new Exception( unexpected( token ) );
		}

		result ~= " " ~ token;
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

	/// This state takes care of function declaration
	string function_declaration_state( string token )
	{
		// First check if we're a function, method, or procedure
		string start;
		switch ( token )
		{
			case "function":
				context.insertFront( "function" );
				start = "pure ";
				break;
			case "method":
				context.insertFront( "method" );
				start = "";
				break;
			case "procedure":
				context.insertFront( "procedure" );
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
			if ( !return_type && context.front != "procedure" )
				return_type = "auto";
		}
		
		// Function declarations must end with colon
		string colon = l.pop();
		if ( colon == ":" )
			return start ~ return_type ~ " " ~ name ~ "(" ~ args ~ ")";
		else
			throw new Exception( expected( ":", colon ) );
	}

	/// This parses args in function declarations of form "(int a, b, T t..."
	string parse_args( string token )
	{
		// Function params must start with "("
		if ( token != "(" )
			throw new Exception( expected( "(", token ) );

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

	/// Parse return type. If none, return auto
	string parse_return_type( string token )
	{
		// no return type, guess
		if ( token == ")" )
			return "auto";
		
		// return type must start with "-> type"
		if ( token != "->" )
			throw new Exception( expected( "->", token ) );

		if ( identify_token( l.peek() ) != "type" )
			throw new Exception( unexpected( l.peek() ) );

		string type = l.pop();
		string next = l.pop();

		// We're done, make sure the function def is done
		if ( next != ")" )
			throw new Exception( unexpected( next ) );

		return type;
	}

	/// Determine if we're calling a function or assigning to a varible
	string identifier_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "punctuation":
				// calling a function
				if ( token == "(" )
				{
					return token ~ function_call_state( l.pop() ) ~ ";";
				}
				// array
				else if ( token == "[" )
				{
					string array = array_state( token );
					return array ~ identifier_state( l.pop() );
				}
				else
				{
					throw new Exception( unexpected( token ) );
				}
			
			// assigning a variable
			case "assignment operator":
				return " " ~ token ~ " " ~ expression_state( l.pop() ) ~ ";";
			default:
				throw new Exception( unexpected( token ) );
		}
	}

	/// Parses arguments to a function
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
					throw new Exception( expected( ",' or ')", next ) );
			default:
				throw new Exception( unexpected( token ) );
		}
	}

	/// Array accesses can have multiple sets of brackets, no commas
	string array_state( string token )
	{
		if ( token != "[" )
			throw new Exception( expected( "[", token ) );
		
		string result = token;
		while ( l.peek() != "]" )
		{
			result ~= expression_state( l.pop() );
			
			if ( l.peek() == "," )
			{
				l.pop();
				result ~= "][";
			}
		}

		return result ~ l.pop();
	}

	/// array literals can have commas and only one set of exterior brackets
	string array_literal_state( string token )
	{
		string result = token;
		while ( true )
		{
			if ( l.peek() != "]" )
				result ~= expression_state( l.pop() );

			token = l.pop();
			result ~= token;
			if ( token == "," )
				continue;
			else if ( token == "]" )
				break;
			else
				throw new Exception( expected( ",' or ']", token ) );
		}
		
		return result;
	}

	/// Expression state
	string expression_state( string token )
	{
		string expression;
		switch ( identify_token( token ) )
		{
			case "string literal":
			case "character literal":
			case "number literal":
				expression = token;
				break;
			case "identifier":
				expression = token;
				if ( l.peek() == "(" )
				{
					l.pop();
					expression ~= "(" ~ function_call_state( l.pop() );
				}
				else if ( l.peek() == "[" )
				{
					expression ~= array_state( l.pop() );
				}
				break;
			case "punctuation":
				// sub-expression in parentheses
				if ( token == "(" )
					expression = token ~ expression_state( l.pop() );
				else if ( token == "[" )
					expression = array_literal_state( token );
				else
					throw new Exception( unexpected( token ) );
				break;
			case "comparator":
				if ( token == "not" )
				{
					expression = "!" ~ expression_state( l.pop() );
					break;
				}
				else
					throw new Exception( unexpected( token ) );
			default:
				throw new Exception( unexpected( token ) );
		}

		/// Contains conversions to D operators
		string[string] conversion = [
			"and": "&&",
			"or": "||",
			"equal to": "==",
			"less than": "<",
			"more than": ">",
			"^": "^^"
		];

		string[string] negate_op = [
			"not equal to": "!=",
			"not less than": ">=",
			"not more than": "<=",
			"not is": "!is"
		];

		if ( identify_token( l.peek() ) == "operator"
				|| identify_token( l.peek() ) == "comparator"
				|| identify_token( l.peek() ) == "logical" )
		{
			// Convert operator into D format
			string op = l.pop();
			if ( op in conversion )
				op = conversion[op];

			// Not combines with the next token
			if ( op == "not" )
			{
				string next = l.pop();
				if ( identify_token( next ) == "comparator" && next != "not" )
					op = negate_op["not " ~ next];
				else
					throw new Exception( unexpected( next ) );
			}

			return expression ~ " " ~ op ~ " " ~ expression_state( l.pop() );
		}

		if ( l.peek() == ")" )
			return expression ~ l.pop();
		else
			return expression;
	}

	/// Expecting the end of a line
	string endline_state( string token )
	{
		if ( token == "\n" )
			return ";" ~ endline();
		else
			throw new Exception( expected( "newline", token ) );
	}

	/// Block comments eat the rest of the input until it un-indents
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

	/// Inline comments just eat the rest of the line
	string inline_comment_state( string token )
	{
		string result;
		if ( token == "#" )
			result = "//";
		else if ( token == "#." )
			result = "///";
		else
			throw new Exception( expected( "#", token ) );

		result ~= l.pop();
		string newline = l.pop();
		if ( newline == "\n" )
			return result ~ endline();
		else
			throw new Exception( expected( "newline", newline ) );
	}

	/// Newlines keep indent and stuff
	string newline_state( string token )
	{
		string endline = endline();

		// Don't use a newline if token is 'begin'
		if ( token == "begin" )
			endline = "";

		// Don't use a bracket if token is 'begin' or 'newline' 
		string bracket = "";
		if ( token == "indent +1" )
			bracket = "{";
		else if ( token == "indent -1" )
			bracket = "}";

		// Exiting a context when there's an end-indent
		if ( token == "indent -1" )
		{
			// Prepend newlines so we stay in proper context
			while ( !l.is_empty() && l.peek() == "\n" )
				endline = l.pop() ~ endline;

			// We stay in "if" context when else-ing
			if ( context.front != "if" || !l.is_empty() && l.peek() != "else" )
				context.removeFront();
		}

		// Check if there's a block comment coming up
		if ( !l.is_empty() && ( l.peek() == "#" || l.peek() == "#." ) )
			return bracket ~ endline ~ block_comment_state( l.pop() );
		else
			return bracket ~ endline;
	}

	/// New line, plus indentation
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

	/**
	 * We expected to find this token, but didn't
	 */
	string expected( string expected, string unexpected )
	{
		return "On line " ~ to!string( l.line_number ) ~ ": expected '" ~ expected ~ "' but got '" ~ unexpected ~ "'";
	}
}
