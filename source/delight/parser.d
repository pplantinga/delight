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
module delight.parser;

import delight.lexer;
import std.conv : to;
import std.stdio : writeln;
import std.range : repeat;
import std.regex;
import std.string;
import std.algorithm : canFind, startsWith;
import std.container : SList;

class Parser
{
	/// Breaks source code into tokens
	Lexer l;

	/// Stores regexes for determining what tokens are
	Regex!char[string] symbol_regexes;

	/// Keeps track of the current context
	SList!string context;

	/// Keeps track of the things we want to import
	string includes;

	/// Whether or not we've included various functions
	bool[string] include_functions;

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
		"case",
		"default",
		"else",
		"if",
		"switch"
	], "|" ) ~ ")$" );

	/// Exception handling
	auto exception_regex = regex( "^(" ~ join( [
		"try",
		"except",
		"finally"
	], "|" ) ~ ")$" );

	/// Function types.
	auto function_type_regex = regex( "^(" ~ join( [
		"function",
		"method",
		"procedure"
	], "|" ) ~ ")$" );

	/// For imports
	auto library_regex = regex( "^(" ~ join( [
		"as",
		"from",
		"import"
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
		"continue",
		"for",
		"print",
		"raise",
		"return",
		"unittest",
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
		"class",
		"enum"
	], "|" ) ~ ")$" );

	/**
	 * Constructor takes a string containing location of source code
	 * and generates a lexer for creating tokens out of text
	 * and a symbol regex array
	 */
	this( string filename )
	{
		/// Lexer parses source into tokens
		l = new Lexer( filename );

		/// Unfortunately, associative array literals
		/// can only happen inside a function in D
		symbol_regexes = [
			"assignment operator" : regex( `^[+*%^/~-]?=$` ),
			"character literal"   : regex( `^'\\?.'$` ),
			"comparator"          : comparator_regex,
			"conditional"         : conditional_regex,
			"exception"           : exception_regex,
			"function type"       : function_type_regex,
			"library"             : library_regex,
			"logical"             : logical_regex,
			"newline"             : regex( `^(\n|(in|de)dent|begin)$` ),
			"number literal"      : regex( `^[0-9]+.?[0-9]*$` ),
			"operator"            : regex( `^[+*%^/~-]$` ),
			"punctuation"         : regex( `^([.,!:()\[\]#]|\.\.|#\.|->)$` ),
			"statement"           : statement_regex,
			"string literal"      : regex( `^".*"$` ),
			"template type"       : regex( `^[A-Z]$` ),
			"type"                : type_regex,
			"user type"           : user_type_regex
		];

		// Initialize possible includes
		include_functions = [
			"contains" : false,
			"iota" : false,
			"print" : false
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
		auto p = new Parser( "tests/import.delight" );
		assert( p.identify_token( "\n" ) == "newline" );
		assert( p.identify_token( "dedent" ) == "newline" );
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
		assert( p.identify_token( "if" ) == "conditional" );
		assert( p.identify_token( "else" ) == "conditional" );
		assert( p.identify_token( "less than" ) == "comparator" );
		assert( p.identify_token( "not" ) == "comparator" );
		assert( p.identify_token( "equal to" ) == "comparator" );
		assert( p.identify_token( "try" ) == "exception" );
		assert( p.identify_token( "except" ) == "exception" );
		assert( p.identify_token( "function" ) == "function type" );
		assert( p.identify_token( "method" ) == "function type" );
		assert( p.identify_token( "procedure" ) == "function type" );
		assert( p.identify_token( "import" ) == "library" );
		assert( p.identify_token( "from" ) == "library" );
		assert( p.identify_token( "and" ) == "logical" );
		assert( p.identify_token( "-" ) == "operator" );
		assert( p.identify_token( "^" ) == "operator" );
		assert( p.identify_token( "." ) == "punctuation" );
		assert( p.identify_token( ":" ) == "punctuation" );
		assert( p.identify_token( "#" ) == "punctuation" );
		assert( p.identify_token( "#." ) == "punctuation" );
		assert( p.identify_token( "->" ) == "punctuation" );
		assert( p.identify_token( ".." ) == "punctuation" );
		assert( p.identify_token( "for" ) == "statement" );
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

		return includes ~ result;
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
			"loops",
			"exceptions",
			"unittests",
			"classes"
		];

		foreach ( test; tests )
		{
			writeln( "Parsing " ~ test ~ " test" );
			auto p = new Parser( "tests/" ~ test ~ ".delight" );
			auto result = read( "tests/" ~ test ~ ".d" );
			assert( p.parse() == result );
		}
	}

	/// Check if this token is right
	void check_token( string check, string token )
	{
		if ( check != token )
			throw new Exception( expected( token, check ) );
	}

	/// Check if this token is the right type
	void check_token_type( string check, string type )
	{
		if ( identify_token( check ) != type )
			throw new Exception( unexpected( check ) );
	}

	/// The starting state for the parser
	string start_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "library":
				return library_state( token );
			case "statement":
				return statement_state( token );
			case "conditional":
				return conditional_state( token );
			case "type":
				return token ~ declare_state( l.pop() );
			case "template type":
				if ( canFind( context.opSlice(), "template" ) )
					return token ~ declare_state( l.pop() );
				else
					throw new Exception( unexpected( token ) );
			case "function type":
				return function_declaration_state( token );
			case "identifier":
				string result = identifier_state( token );
				string next = l.pop();
				// Except for functions, check for assignment
				if ( result[$-1] != ')'
						&& identify_token( next ) == "assignment operator" )
					return result ~ assignment_state( next );
				else if ( identify_token( next ) == "identifier" )
					return result ~ " " ~ next ~ class_instance_state( l.pop() );
				else if ( result[$-1] == ')' && next == "\n" )
					return result ~ ";" ~ endline_state( next );
				else if ( next == "\n" )
					return result ~ endline_state( next );
				else
					throw new Exception( unexpected( next ) );
			case "punctuation":
				if ( token == "#" || token == "#." )
					return inline_comment_state( token );
				else
					throw new Exception( unexpected( token ) );
			case "newline":
				return newline_state( token );
			case "user type":
				if ( token == "class" )
					return token ~ " " ~ class_state( l.pop() );
				else
					throw new Exception( unexpected( token ) );
			case "exception":
				return exception_state( token );
			default:
				throw new Exception( unexpected( token ) );
		}
	}

	string statement_state( string token )
	{
		switch ( token )
		{
			case "for":
				return "foreach (" ~ foreach_state( l.pop() ) ~ ")";
			case "while":
				return "while (" ~ while_state( l.pop() ) ~ ")";
			case "return":
				return return_state( token );
			case "assert":
				return token ~ "(" ~ expression_state( l.pop() ) ~ ");";
			case "unittest":
				check_token( l.pop(), ":" );
				return token;
			case "break":
			case "continue":
				if ( !canFind( context.opSlice(), "for" )
						&& !canFind( context.opSlice(), "while" ) )
					throw new Exception( unexpected( token ) );
				else
					return token ~ ";";
			case "raise":
				if ( identify_token( l.peek() ) == "string literal" )
					return "throw new Exception(" ~ l.pop() ~ ");";
				else
					return "throw " ~ expression_state( l.pop() ) ~ ";";
			case "print":
				add_function( "print" );
				return "writeln(" ~ expression_state( l.pop() ) ~ ");";
			default:
				throw new Exception( unexpected( token ) );
		}
	}

	/// This state takes care of stuff after an import
	string library_state( string token )
	{
		/// If this is a selective import
		bool selective = token == "from";

		string library;
		if ( token == "import" || token == "from" )
			library = parse_library( l.pop() );
		else
			throw new Exception( unexpected( token ) );

		/// Renamed library
		if ( l.peek() == "as" )
		{
			l.pop();
			string join = " = ";
			
			check_token_type( l.peek(), "identifier" );

			library = l.pop() ~ join ~ library;
		}

		// Selective imports
		string parts;
		if ( selective )
		{
			check_token( l.pop(), "import" );

			parts = " : ";
			
			string part;
			while ( l.peek() != "\n" )
			{
				check_token_type( l.peek(), "identifier" );
				part = l.pop();

				// Renamed import
				if ( l.peek() == "as" )
				{
					l.pop();
					check_token_type( l.peek(), "identifier" );
					part = l.pop() ~ " = " ~ part;
				}

				// Additional import
				if ( l.peek() == "," )
					part ~= l.pop() ~ " ";

				parts ~= part;
			}
		}

		return "import " ~ library ~ parts ~ ";";
	}

	/// Parse foo.bar.baz type libraries
	string parse_library( string token )
	{
		check_token_type( token, "identifier" );

		string library = token;

		while ( l.peek() == "." )
		{
			library ~= l.pop();
			check_token_type( token, "identifier" );
			library ~= l.pop();
		}

		return library;
	}


	/// Assignment state parses operator and expression
	string assignment_state( string token )
	{
		check_token_type( token, "assignment operator" );
		
		return " " ~ token ~ " " ~ expression_state( l.pop() ) ~ ";";
	}

	/// Default loop state. Form is "for key, item in array"
	string foreach_state( string token )
	{
		context.insertFront( "for" );
		check_token_type( token, "identifier" );

		string result = token;
		if ( l.peek() == "," )
		{
			result ~= l.pop();
			check_token_type( l.peek(), "identifier" );
			result ~= l.pop();
		}

		check_token( l.pop(), "in" );

		result ~= "; ";

		if ( identify_token( l.peek() ) == "number literal" )
		{
			result ~= l.pop();
			check_token( l.pop(), ".." );
			result ~= " .. ";
			check_token_type( l.peek(), "number literal" );
			result ~= l.pop();
			check_token( l.pop(), ":" );
			return result;
		}

		check_token_type( l.peek(), "identifier" );
		result ~= l.pop();
		check_token( l.pop(), ":" );

		return result;
	}

	/// Generic loop
	string while_state( string token )
	{
		context.insertFront( "while" );

		string expression = expression_state( token );

		check_token( l.pop(), ":" );

		return expression;
	}

	/// return statement
	string return_state( string token )
	{
		if ( l.peek() == "\n" )
			return token ~ ";";
		else
			return token ~ " " ~ expression_state( l.pop() ) ~ ";";
	}

	/// Control branching
	string conditional_state( string token )
	{
		if ( l.peek() == "if" )
			token ~= " " ~ l.pop();
	
		// Check for else without if
		if ( startsWith( token, "else" ) && context.front != "if" )
			throw new Exception( unexpected( token ) );
		
		// Check for case, default without switch
		if ( ( token == "case" || token == "default" )
				&& context.front != "switch" )
			throw new Exception( unexpected( token ) );

		// Else is excepted, because we're still in "if" context
		if ( !startsWith( token, "else" ) )
			context.insertFront( token );

		string condition;
		switch ( token )
		{
			case "if":
			case "else if":
			case "switch":
				condition = token ~ " (" ~ expression_state( l.pop() ) ~ ")";
				break;
			case "else":
				condition = token;
				break;
			case "default":
				condition = token ~ ":";
				break;
			case "case":
				condition = token ~ " " ~ expression_state( l.pop() ) ~ ":";
				break;
			default:
				throw new Exception( unexpected( token ) );
		}
		
		// Check for colon after conditional
		check_token( l.pop(), ":" );

		// If a case or default, newline already handled
		if ( token == "case" || token == "default" )
			check_token( l.pop(), "\n" );

		// In this case, we don't actually enter the scope yet
		if ( l.peek() == "case" )
		{
			context.removeFront();
			condition ~= endline();
		}

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
				return result ~ assignment_state( token );

			case "newline":
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
				// Methods can only live in classes and templates
				if ( !canFind( context.opSlice(), "class" ) 
						&& !canFind( context.opSlice(), "template" ) )
					throw new Exception( unexpected( "method" ) );

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
		check_token_type( l.peek(), "identifier" );

		string name = l.pop();
		string args, template_args, return_type;

		if ( l.peek() == "(" )
		{
			args = parse_args( l.pop() );
			return_type = parse_return_type( l.pop() );
		}
		
		// Function declarations must end with colon
		check_token( l.pop(), ":" );

		return start ~ return_type ~ " " ~ name ~ "(" ~ args ~ ")";
	}


	/// This parses args in function declarations of form "(int a, b, T t..."
	string parse_args( string token )
	{
		// Function params must start with "("
		check_token( token, "(" );

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

			// Add ref to procedures
			if ( context.front == "procedure" )
				type = "ref " ~ type;

			// For each identifier we encounter
			while ( identify_token( l.peek() ) == "identifier" )
			{
				result ~= type ~ " " ~ l.pop();
				if ( l.peek() == "," )
					result ~= l.pop() ~ " ";
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
		// procedures have no return type
		if ( context.front == "procedure" )
			return "";

		// no return type, guess
		if ( token == ")" )
			return "auto";
		
		// return type must start with "-> type"
		check_token( token, "->" );
		check_token_type( l.peek(), "type" );

		string type = l.pop();

		// We're done, make sure the function def is done
		check_token( l.pop(), ")" );

		return type;
	}

	/// Determine what kind of variable this is. 
	string identifier_state( string token )
	{
		check_token_type( token, "identifier" );
		string identifier = token;

		if ( identify_token( l.peek() ) == "punctuation" && l.peek() != ":" )
		{
			token = l.pop();
			switch ( token )
			{
				// Function call
				case "(":
					identifier ~= token ~ function_call_state( l.pop() );
					break;
				
				// Array access
				case "[":
					identifier ~= array_state( token );
					break;
			
				// template instance
				case "!":
					check_token_type( l.peek(), "type" );
					identifier ~= token ~ l.pop();
					if ( l.peek() == "(" )
					{
						identifier ~= l.pop();
						identifier ~= function_call_state( l.pop() );
					}
					break;
			
				// class member
				case ".":
					identifier ~= token ~ identifier_state( l.pop() );
					break;

				default:
					throw new Exception( unexpected( token ) );
			}
		}

		return identifier;
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
		check_token( token, "[" );
		
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
				expression = identifier_state( token );
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
			"not equal to": "!=",
			"not less than": ">=",
			"not more than": "<=",
			"not is": "!is",
			"^": "^^"
		];

		if ( identify_token( l.peek() ) == "operator"
				|| identify_token( l.peek() ) == "comparator"
				|| identify_token( l.peek() ) == "logical" )
		{
			// Convert operator into D format
			string op = l.pop();

			// Not combines with the next token
			if ( op == "not" )
				op = "not " ~ l.pop();

			if ( op in conversion )
				op = conversion[op];

			if ( op == "in" )
			{
				add_function( "contains" );
				string haystack = expression_state( l.pop() );
				return "contains(" ~ haystack ~ "," ~ expression ~ ")";
			}

			return expression ~ " " ~ op ~ " " ~ expression_state( l.pop() );
		}
		else if ( l.peek() == ".." )
		{
			l.pop();
			add_function( "iota" );
			return "iota(" ~ expression ~ "," ~ l.pop() ~ ")";
		}

		if ( l.peek() == ")" )
			return expression ~ l.pop();
		else
			return expression;
	}

	/// Expecting the end of a line
	string endline_state( string token )
	{
		check_token( token, "\n" );
		return endline();
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

		if ( l.peek() == "indent" )
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
				else if ( token == "indent" )
					level += 1;
				else if ( token == "dedent" )
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

		return result ~ endline_state( l.pop() );
	}

	/// Object Orientation!
	string class_state( string token )
	{
		context.insertFront( "class" );
		check_token_type( token, "identifier" );

		string result = token;

		if ( l.peek() == "(" )
		{
			// This isn't a class, it's a template!
			context.removeFront();
			context.insertFront( "template" );
			result ~= l.pop();

			if ( identify_token( l.peek() ) == "template type" )
				result ~= l.pop();

			while ( l.peek() == "," )
			{
				result ~= l.pop();
				check_token_type( l.peek(), "template type" );
				result ~= l.pop();
			}

			check_token( l.pop(), ")" );
			result ~= ")";
		}
			
		check_token( l.pop(), ":" );

		return result ~ endline_state( l.pop() );
	}

	string class_instance_state( string token )
	{
		check_token( token, "=" );
		check_token( l.peek(), "new" );

		string result = " " ~ token ~ " " ~ l.pop();

		check_token_type( l.peek(), "identifier" );
		result ~= " " ~ l.pop();

		// template instance
		if ( l.peek() == "!" )
		{
			result ~= l.pop();
			check_token_type( l.peek(), "type" );
			result ~= l.pop();
		}

		check_token( l.peek(), "(" );
		result ~= "(" ~ parse_args( l.pop() );
		check_token( l.pop(), ")" );

		return result ~ ");";
	}


	/// Newlines keep indent and stuff
	string newline_state( string token )
	{
		string endline = endline();

		// Don't use a newline if token is 'begin'
		if ( token == "begin" )
			endline = "";

		// Don't use a bracket if token is 'begin' or 'newline'
		// Nor if we're in a case: or default: context
		string bracket = "";
		if ( context.front != "case"
				&& context.front != "default" )
		{
			if ( token == "indent" )
				bracket = "{";
			else if ( token == "dedent" )
				bracket = "}";
		}
		else if ( context.front == "case" && token == "dedent" )
		{
			bracket = l.indentation ~ "break;";
		}

		// Exiting a context when there's an end-indent
		if ( token == "dedent" )
		{
			// Prepend newlines so we stay in proper context
			while ( !l.is_empty() && l.peek() == "\n" )
				endline = l.pop() ~ endline;

			// Unless going to "else", "except", or "finally" drop out of context
			if ( l.is_empty()
					|| l.peek() != "else"
					&& l.peek() != "except"
					&& l.peek() != "finally" )
				context.removeFront();
		}

		// Check if there's a block comment coming up
		if ( !l.is_empty() && ( l.peek() == "#" || l.peek() == "#." ) )
			return bracket ~ endline ~ block_comment_state( l.pop() );
		else
			return bracket ~ endline;
	}

	string exception_state( string token )
	{
		string exception = token;

		string next = l.pop();

		if ( token == "try" )
			context.insertFront( "try" );
		else if ( token == "except" && context.front == "try" )
			exception = "catch (" ~ next ~ " " ~ l.pop() ~ ")";
		else if ( token == "finally" && context.front == "try" )
			exception = "finally";
		else
			throw new Exception( unexpected( token ) );

		if ( token == "except" )
			next = l.pop();

		check_token( next, ":" );

		return exception;
	}

	/// New line, plus indentation
	string endline()
	{
		int level = l.indentation_level;

		// Since the indentation level doesn't get changed till after
		// the pop, we'll need to shift the indentation here
		if ( !l.is_empty() && l.peek() == "dedent" )
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

	/// Add a function that "delight" has but "d" doesn't
	void add_function( string func )
	{
		if ( func !in include_functions || include_functions[func] )
			return;

		include_functions[func] = true;
		switch ( func )
		{
			case "contains":
				includes ~= "bool contains(H,N)(H h,N n){foreach(i;h)if(i==n)return true;return false;}\n";
				break;
			case "print":
				includes ~= "import std.stdio : writeln;\n";
				break;
			case "iota":
				includes ~= "import std.algorithm : iota;\n";
				break;
			default:
		}
	}
}
