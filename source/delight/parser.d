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
import std.algorithm : canFind, startsWith, balancedParens;
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

	/// Store the last item to come off the stack, for if-else and such
	string previous_context = "start";

	/// Attributes for various things
	auto attributes = [
		"abstract",
		"deprecated",
		"export",
		"immutable",
		"lazy",
		"override",
		"package",
		"private",
		"protected",
		"public",
		"ref",
		"scope",
		"static",
		"synchronized"
	];

	/// Compare and contrast, producing booleans.
	auto comparators = [
		"equal to",
		"is",
		"in",
		"has key",
		"less than",
		"more than",
		"not"
	];

	/// Statements used for branching
	auto conditionals = [
		"case",
		"default",
		"else",
		"if",
		"switch"
	];

	/// Creating instances
	auto constructors = [
		"super",
		"this"
	];

	/// Contract programming
	auto contracts = [
		"enter",
		"exit",
		"body"
	];

	/// Exception handling
	auto exceptions = [
		"try",
		"except",
		"finally"
	];

	/// Function types.
	auto function_types = [
		"function",
		"method",
		"procedure"
	];

	/// For imports
	auto librarys = [
		"as",
		"from",
		"import"
	];

	/// join comparisons
	auto logical = [
		"and",
		"or"
	];

	/// These do things.
	auto statements = [
		"assert",
		"break",
		"continue",
		"for",
		"new",
		"passthrough",
		"print",
		"raise",
		"return",
		"unittest",
		"while"
	];

	/// How is stuff stored in memory?
	auto types = [
		"auto", "bool", "void", "string",
		"byte", "short", "int", "long", "cent",
		"ubyte", "ushort", "uint", "ulong", "ucent",
		"float", "double", "real",
		"ifloat", "idouble", "ireal",
		"cfloat", "cdouble", "creal",
		"char", "wchar", "dchar"
	];

	/// More complicated types.
	auto user_types = [
		"class",
		"enum"
	];

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
			"attribute"           : regexify( attributes ),
			"character literal"   : regex( `^'\\?.'$` ),
			"class identifier"    : regex( `^[A-Z][a-z][A-Za-z_]*$` ),
			"comparator"          : regexify( comparators ),
			"conditional"         : regexify( conditionals ),
			"constant"            : regex( `^[A-Z_]{2,}$` ),
			"constructor"         : regexify( constructors ),
			"contract"            : regexify( contracts ),
			"exception"           : regexify( exceptions ),
			"function type"       : regexify( function_types ),
			"library"             : regexify( librarys ),
			"logical"             : regexify( logical ),
			"newline"             : regex( `^(\n|(in|de)dent|begin)$` ),
			"number literal"      : regex( `^\d[0-9_]*\.?[0-9_]*(e-?[0-9_]+)?$` ),
			"operator"            : regex( `^([+*%^/~-]|\.\.)$` ),
			"punctuation"         : regex( `^([.,!:(){}\[\]#]|#\.|->)$` ),
			"statement"           : regexify( statements ),
			"string literal"      : regex( `^".*"$` ),
			"template type"       : regex( `^[A-Z]$` ),
			"type"                : regexify( types ),
			"user type"           : regexify( user_types )
		];

		// Initialize possible includes
		include_functions = [
			"in" : false,
			"iota" : false,
			"writeln" : false,
			"map" : false,
			"filter" : false
		];

		// Add a beginning symbol to the context stack
		context.insertFront( "start" );
	}

	auto regexify( string[] tokens )
	{
		return regex( "^(" ~ join( tokens, "|" ) ~ ")$" );
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
		assert( p.identify_token( "immutable" ) == "attribute" );
		assert( p.identify_token( "=" ) == "assignment operator" );
		assert( p.identify_token( "+=" ) == "assignment operator" );
		assert( p.identify_token( "%=" ) == "assignment operator" );
		assert( p.identify_token( "~=" ) == "assignment operator" );
		assert( p.identify_token( "'a'" ) == "character literal" );
		assert( p.identify_token( "'\\n'" ) == "character literal" );
		assert( p.identify_token( "if" ) == "conditional" );
		assert( p.identify_token( "else" ) == "conditional" );
		assert( p.identify_token( "enter" ) == "contract" );
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
		assert( p.identify_token( "\n" ) == "newline" );
		assert( p.identify_token( "dedent" ) == "newline" );
		assert( p.identify_token( "begin" ) == "newline" );
		assert( p.identify_token( "5" ) == "number literal" );
		assert( p.identify_token( "5.2" ) == "number literal" );
		assert( p.identify_token( "3_333.5e-5" ) == "number literal" );
		assert( p.identify_token( "-" ) == "operator" );
		assert( p.identify_token( "^" ) == "operator" );
		assert( p.identify_token( ".." ) == "operator" );
		assert( p.identify_token( "." ) == "punctuation" );
		assert( p.identify_token( ":" ) == "punctuation" );
		assert( p.identify_token( "#" ) == "punctuation" );
		assert( p.identify_token( "#." ) == "punctuation" );
		assert( p.identify_token( "->" ) == "punctuation" );
		assert( p.identify_token( "for" ) == "statement" );
		assert( p.identify_token( `""` ) == "string literal" );
		assert( p.identify_token( `"string"` ) == "string literal" );
		assert( p.identify_token( "T" ) == "template type" );
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
		string d_code;

		while ( !l.is_empty() )
		{
			try
			{
				d_code ~= start_state( l.pop() );
			}
			// Catch exceptions generated by parse and output them
			catch ( Exception e )
			{
				writeln( e.msg );
				debug writeln( e );
				return d_code;
			}
		}

		return includes ~ d_code;
	}
	unittest
	{
		import std.file : read;

		string[] tests = [
			"arrays",
			"assignment",
			"classes",
			"comments",
			"conditionals",
			"exceptions",
			"functions",
			"import",
			"indent",
			"loops",
			"passthrough",
			"unittests"
		];

		foreach ( test; tests )
		{
			writeln( "Parsing " ~ test ~ " test" );
			auto p = new Parser( "tests/" ~ test ~ ".delight" );
			auto d_code = read( "tests/" ~ test ~ ".d" );
			assert( p.parse() == d_code );
		}
	}

	/// Check if this token is right
	void check_token( string check, string[] tokens... )
	{
		if ( !canFind( tokens, check ) )
			throw new Exception( expected( join( tokens, "' or '" ), check ) );
	}

	/// Check if this token is the right type
	void check_token_type( string check, string[] types... )
	{
		if ( !canFind( types, identify_token( check ) ) )
			throw new Exception( unexpected( check ) );
	}

	/// The starting state for the parser
	string start_state( string token )
	{
		switch ( identify_token( token ) )
		{
			case "attribute":
				return attribute_state( token );
			case "library":
				return library_state( token );
			case "statement":
				return statement_state( token );
			case "conditional":
				return conditional_state( token );
			case "constructor":
				return constructor_state( token );
			case "constant":
				return "static immutable " ~ token ~ assignment_state( l.pop() );
			case "contract":
				return contract_state( token );
			case "type":
			case "class identifier":
				return declare_state( token );
			case "template type":
				if ( canFind( context.opSlice(), "template" ) )
					return declare_state( token );
				else
					throw new Exception( unexpected( token ) );
			case "function type":
				return function_declaration_state( token );
			case "identifier":
				string identifier = identifier_state( token );
		
				// Except for functions, check for assignment
				if ( identifier[$-1] != ')'
						&& identify_token( l.peek() ) == "assignment operator" )
					return identifier ~ assignment_state( l.pop() );
				else if ( l.peek() == "\n" )
					return identifier ~ ";" ~ endline_state( l.pop() );
				else
					throw new Exception( unexpected( l.peek() ) );
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

	string attribute_state( string token )
	{
		if ( l.peek() == ":" )
		{
			// Add attribute to front of current context
			context.insertFront( token );

			return token ~ colon_state( l.pop() );
		}

		return token ~ " ";
	}

	string colon_state( string token )
	{
		check_token( token, ":" );

		string endline = endline_state( l.pop() );

		check_token( l.pop(), "indent" );

		return endline ~ newline_state( "indent" );
	}

	string constructor_state( string token )
	{
		string args = parse_args( l.pop() );
		check_token( l.pop(), ")" );

		string endline = ";";
		if ( l.peek() == ":" )
		{
			// Enter constructor context
			context.insertFront( token );
			endline = colon_state( l.pop() );
		}
		
		return token ~ "(" ~ args ~ ")" ~ endline;
	}

	string contract_state( string token )
	{
		check_token_type( context.front, "function type" );

		// Enter context, body context is taken care of by function dec
		if ( token != "body" )
			context.insertFront( token );

		// parse returned value token
		string returned;
		if ( token == "exit" && identify_token( l.peek() ) == "identifier" )
			returned ~= " (" ~ l.pop() ~ ")";

		// Convert to D keyword
		auto convert = [
			"enter": "in",
			"exit": "out",
			"body": "body"
		];
		auto keyword = convert[token];
		
		return keyword ~ returned ~ colon_state( l.pop() );
	}

	string statement_state( string token )
	{
		string statement;
		switch ( token )
		{
			case "for":
				return foreach_state( token );
			case "while":
				return while_state( token );
			case "assert":
				return token ~ "(" ~ expression_state( l.pop() ) ~ ");";
			case "unittest":
				context.insertFront( "unittest" );
				return token ~ colon_state( l.pop() );
			case "print":
				add_function( "writeln" );
				return "writeln(" ~ expression_state( l.pop() ) ~ ");";
			case "passthrough":
				return passthrough_state( token );

			// The following cases end with "break" to continue execution
			case "break":
			case "continue":
				statement = token ~ ";" ~ endline_state( l.pop() );
				break;
			case "raise":
				statement = raise_state( token );
				break;
			case "return":
				statement = return_state( token );
				break;
			default:
				throw new Exception( unexpected( token ) );
		}

		// The only cases that should be left at this point
		check_token( token, "break", "continue", "raise", "return" );

		statement ~= clear_tokens( ["\n", "#", "#."] );

		// Ensure we don't write an extra "break" in a "case" statement
		if ( context.front == "case" && l.peek() == "dedent" )
		{
			string dedent = l.pop();
			statement ~= clear_tokens( ["\n", "#", "#."] );
			
			if ( l.peek() != "case" && l.peek() != "default" )
				return statement ~ newline_state( dedent );
			else
				context.removeFront();
		}

		return statement;
	}

	/// This state takes care of stuff after an import
	string library_state( string token )
	{
		/// If this is a selective import
		bool selective = token == "from";

		string library;

		check_token( token, "import", "from" );

		library = parse_library( l.pop() );

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
				check_token_type( l.peek(), "identifier", "class identifier" );
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

		// Replace "^=" with "^^="
		if ( token == "^=" )
			token = "^^=";
		
		return " " ~ token ~ " " ~ expression_state( l.pop() ) ~ ";";
	}

	/// Default loop state. Form is "for key, item in array"
	string foreach_state( string token )
	{
		check_token( token, "for" );
		context.insertFront( "for" );
		check_token_type( l.peek(), "identifier" );

		string items = l.pop();
		// If we're keeping track of the index
		if ( l.peek() == "," )
		{
			items ~= l.pop() ~ " ";
			check_token_type( l.peek(), "identifier" );
			items ~= l.pop();
		}

		check_token( l.pop(), "in" );

		// Parse array expression
		string array = expression_state( l.pop(), false );

		return "foreach (" ~ items ~ "; " ~ array ~ ")" ~ colon_state( l.pop() );
	}

	/// Generic loop
	string while_state( string token )
	{
		check_token( token, "while" );
		context.insertFront( "while" );

		string expression = expression_state( l.pop() );

		return "while (" ~ expression ~ ")" ~ colon_state( l.pop() );
	}

	/// return statement
	string return_state( string token )
	{
		string statement = "return";

		if ( l.peek() != "\n" )
			statement ~= " " ~ expression_state( l.pop() );

		return statement ~ ";" ~ endline_state( l.pop() );
	}

	string raise_state( string token )
	{
		check_token( token, "raise" );

		string exception;
		if ( l.peek() == "new" )
		{
			l.pop();
			check_token_type( l.peek(), "class identifier" );
			exception = l.pop();
			check_token( l.pop(), "(" );
			exception ~= "(" ~ expression_state( l.pop() ) ~ ");";
			check_token( l.pop(), ")" );
		}
		else
		{
			exception = "Exception(" ~ expression_state( l.pop() ) ~ ");";
		}

		return "throw new " ~ exception ~ endline_state( l.pop() );
	}

	/// This code gets passed to D as is
	string passthrough_state( string token )
	{
		context.insertFront( "passthrough" );
		check_token( l.pop(), ":" );

		return block_state( token );
	}

	/// Control branching
	string conditional_state( string token )
	{
		// Add "if" to "else"
		if ( token == "else" && l.peek() == "if" )
			token ~= " " ~ l.pop();
	
		// Check for else without if
		if ( startsWith( token, "else" ) && previous_context != "if" )
			throw new Exception( unexpected( token ) );
		
		// Check for case, default outside switch
		if ( ( token == "case" || token == "default" )
				&& context.front != "switch" )
			throw new Exception( unexpected( token ) );

		// Add current statement to the context
		if ( token == "else if" )
			context.insertFront( "if" );
		else
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

		// If there are multiple cases in a row,
		//  we don't actually enter the scope yet
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
		string type = parse_type( token );

		check_token_type( l.peek(), "identifier" );
		string declaration = type ~ " " ~ l.pop();

		switch ( identify_token( l.peek() ) )
		{
			case "assignment operator":
				return declaration ~ assignment_state( l.pop() );

			case "newline":
				return declaration ~ ";" ~ endline_state( l.pop() );

			default:
				throw new Exception( unexpected( token ) );
		}
	}

	/// This state takes care of function declaration
	string function_declaration_state( string token )
	{
		// Methods can only live in classes and templates
		if ( canFind( context.opSlice(), "class" ) 
				|| canFind( context.opSlice(), "template" ) )
			check_token( token, "method" );
		else
			check_token( token, "function", "procedure" );

		// Enter appropriate context
		context.insertFront( token );

		// Must call the function something
		check_token_type( l.peek(), "identifier" );
		string name = l.pop();
		string return_type = "void ";
		string args;
		
		// Check for arguments and a return type
		if ( l.peek() == "(" )
		{
			args = parse_args( l.pop() );

			// Clear any unwanted tokens before the type
			clear_tokens( ["\n", "#", "#."] );

			return_type = parse_return_type( l.pop() ) ~ " ";
		}

		// Check argument to main
		if ( name == "main" && args != "" )
		{
			check_token( args, "ref string[] args" );

			// Remove the ref, it's illegal in main
			args = args[4 .. $];
		}

		// Functions are pure functions
		if ( token == "function" )
			return_type = "pure " ~ return_type;
		
		// Must end with a colon-newline-indent
		check_token( l.pop(), ":" );
		check_token( l.pop(), "\n" );
		string newline = endline();

		// Check for contracts
		if ( identify_token( l.peek() ) == "contract" )
			newline ~= contract_state( l.pop() );

		return return_type ~ name ~ "(" ~ args ~ ")" ~ newline;
	}


	/// This parses args in function declarations of form "(int a, b, T t..."
	string parse_args( string token )
	{
		// Function params must start with "("
		check_token( token, "(" );

		string args;
		string template_types;

		clear_tokens( ["\n", "#", "#.", "indent"] );

		// For each type we encounter
		while ( identify_token( l.peek() ) == "attribute"
				|| identify_token( l.peek() ) == "type"
				|| identify_token( l.peek() ) == "template type"
				|| identify_token( l.peek() ) == "class identifier" )
		{
			string type;
			while ( identify_token( l.peek() ) == "attribute" )
				type = l.pop() ~ " ";

			// If we don't have this template type yet, add it to collection
			if ( identify_token( l.peek() ) == "template type"
					&& std.string.indexOf( template_types, l.peek()[0] ) == -1 )
				template_types ~= l.peek() ~ ", ";

			type ~= parse_type( l.pop() );

			// Add ref to procedures
			if ( context.front == "procedure" )
				type = "ref " ~ type;

			// For each identifier we encounter
			while ( identify_token( l.peek() ) == "identifier" )
			{
				args ~= type ~ " " ~ l.pop();
				if ( l.peek() == "," )
					args ~= l.pop() ~ " ";
			}

			clear_tokens( ["\n", "#", "#."] );
		}

		// Add template types (minus the ending comma)
		if ( template_types )
			template_types = chomp( template_types, ", " ) ~ ")(";

		return template_types ~ args;
	}

	/// Parse return type. If none, return auto
	string parse_return_type( string token )
	{
		// procedures have no return type
		if ( context.front == "procedure" )
			return "void";

		// no return type, guess
		if ( token == ")" )
			return "auto";

		// return type must start with "-> type"
		check_token( token, "->" );

		clear_tokens( ["\n"] );

		string type = parse_type( l.pop() );

		clear_tokens( ["\n", "dedent"] );

		// We're done, make sure the function def is done
		check_token( l.pop(), ")" );

		return type;
	}

	string parse_type( string token )
	{
		check_token_type( token, "type", "class identifier", "template type" );

		string type = token;

		if ( ( identify_token( token ) == "type"
					|| identify_token( token ) == "template type" )
				&& l.peek() == "[" )
			type ~= array_declaration_state( l.pop() );

		if ( identify_token( token ) == "class identifier" && l.peek() == "!" )
		{
			type ~= l.pop();
			check_token_type( l.peek(), "type", "class identifier" );
			type ~= l.pop();
		}

		return type;
	}

	string array_declaration_state( string token )
	{
		check_token( token, "[" );

		string array_declaration = token;
		while ( l.peek() != "]" )
		{
			if ( identify_token( l.peek() ) == "type" )
				array_declaration ~= l.pop();

			if ( l.peek() != "," && l.peek() != "]" )
				array_declaration ~= expression_state( l.pop() );

			check_token( l.peek(), "]", "," );
			
			if ( l.peek() == "," )
			{
				l.pop();
				array_declaration ~= "][";
			}
		}

		return array_declaration ~ l.pop();
	}

	/// Determine what kind of variable this is. 
	string identifier_state( string token )
	{
		check_token_type( token, "identifier", "constant", "constructor" );

		string identifier = token;
		
		// Constants are lowercase in D
		if ( token == "NULL" || token == "TRUE" || token == "FALSE" )
			identifier = toLower( token );

		while ( canFind( ["(", "[", "!", "."], l.peek() ) )
		{
			switch ( l.pop() )
			{
				// Function call
				case "(":
					identifier ~= "(" ~ function_call_state( l.pop() );
					break;
				
				// Array access
				case "[":
					identifier ~= array_access_state( "[" );
					break;
			
				// template instance
				case "!":
					check_token_type( l.peek(), "type", "class identifier" );
					identifier ~= "!" ~ l.pop();
					break;
			
				// class member
				case ".":
					identifier ~= "." ~ identifier_state( l.pop() );
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
		if ( token == ")" )
			return token;

		string expression = expression_state( token );

		expression ~= clear_tokens( ["\n", "dedent"] );

		string next = l.pop();

		if ( next == "," )
			return expression ~ ", " ~ function_call_state( l.pop() );
		else if ( next == ")" )
			return expression ~ ")";
		else
			throw new Exception( expected( ",' or ')", next ) );
	}

	/// Array accesses can have multiple sets of brackets, no commas
	string array_access_state( string token )
	{
		check_token( token, "[" );
		
		string access = token;
		while ( l.peek() != "]" )
		{
			access ~= expression_state( l.pop(), false );
			
			if ( l.peek() == "," )
			{
				l.pop();
				access ~= "][";
			}
		}

		// Add end bracket
		return access ~ l.pop();
	}

	/// array literals can have commas and only one set of exterior brackets
	string array_literal_state( string token )
	{
		string literal = token;

		while ( l.peek() != "]" )
		{
			literal ~= expression_state( l.pop() );
			literal ~= clear_tokens( ["\n", "indent", "dedent", "#", "#."] );

			if ( l.peek() == "," || l.peek() == ":" )
				literal ~= l.pop() ~ " ";
			else
				check_token( l.peek(), "]" );
		}
		
		return literal ~ l.pop();
	}

	/// Expression state
	string expression_state( string token, bool parse_range = true )
	{
		// Parse the first operand
		string expression = parse_operand( token );

		// While there's unbalanced parentheses
		// parse newlines, comments, and end parentheses
		if ( !balancedParens( expression, '(', ')' ) )
			balance_parens( expression );

		/// Contains conversions to D operators
		string[string] conversion = [
			"and": "&&",
			"or": "||",
			"has key": "in",
			"equal to": "==",
			"less than": "<",
			"more than": ">",
			"not has key": "!in",
			"not equal to": "!=",
			"not less than": ">=",
			"not more than": "<=",
			"not is": "!is",
			"^": "^^"
		];

		while ( identify_token( l.peek() ) == "operator"
				|| identify_token( l.peek() ) == "comparator"
				|| identify_token( l.peek() ) == "logical" )
		{
			// Convert operator into D format
			string op = l.pop();
		
			// Not combines with the next token
			if ( op == "not" )
				op = "not " ~ l.pop();

			// These operators require adding a function that's not in D 
			if ( op == "not in" || op == "in" || op == ".." )
			{
				expression = add_function_op( op, expression, parse_range );
				continue;
			}

			// Convert operator from Delight to D
			if ( op in conversion )
				op = conversion[op];

			// Here we're after the conversion, so we're talking about D's "in"
			if ( op == "in" || op == "!in" )
			{
				string key = parse_operand( l.pop() );
				expression = key ~ " " ~ op ~ " " ~ expression;
				continue;
			}

			expression ~= " " ~ op ~ " " ~ parse_operand( l.pop() );

			if ( !balancedParens( expression, '(', ')' ) )
				balance_parens( expression );
		}

		return expression;
	}

	string parse_operand( string token )
	{
		switch ( identify_token( token ) )
		{
			case "string literal":
			case "character literal":
			case "number literal":
				return token;
			case "identifier":
			case "constant":
			case "constructor":
				return identifier_state( token );
			default:
				switch( token )
				{
					case "new":
						return instantiation_state( token );
					case "not":
						return "!" ~ parse_operand( l.pop() );
					case "[":
						return array_literal_state( token );
					case "-":
					case "(":
						return token ~ parse_operand( l.pop() );
					case "#":
					case "#.":
						string block = block_state( token );
						return block ~ parse_operand( l.pop() );
					case "\n":
						string newline = newline_state( token );
						return newline ~ parse_operand( l.pop() );
					case "indent":
					case "dedent":
						return parse_operand( l.pop() );
					case "{":
						return list_comprehension_state( token );
					default:
						throw new Exception( unexpected( token ) );
				}
		}
	}

	void balance_parens( ref string expression )
	{
		string[] valid_tokens = [
			"\n",
			"indent",
			"dedent",
			"#",
			"#.",
		];

		expression ~= clear_tokens( valid_tokens );

		if ( l.peek() == ")" && !balancedParens( expression, '(', ')' ) )
		{
			expression ~= l.pop();

			// If we're still not balanced, go around again
			if ( !balancedParens( expression, '(', ')' ) )
				balance_parens( expression );
		}
	}
	
	string clear_tokens( string[] tokens )
	{
		string expression;
		while ( canFind( tokens, l.peek() ) )
		{
			switch( l.peek() )
			{
				case "\n":
					expression ~= newline_state( l.pop() );
					break;
				case "indent":
				case "dedent":
					l.pop();
					break;
				case "#":
				case "#.":
					expression ~= block_state( l.pop() );
					break;
				default:
					break;
			}
		}
		return expression;
	}

	string add_function_op( string operator, string expression, bool parse_range )
	{
		if ( operator == "in" || operator == "not in" )
		{
			add_function( "in" );
			string haystack = expression_state( l.pop() );

			expression = "In(" ~ haystack ~ ", " ~ expression ~ ")";
			if ( operator == "not in" )
				expression = "!" ~ expression;
		}
		else if ( operator == ".." )
		{
			string to = expression_state( l.pop() );

			// Don't use iota when !parse_range
			if ( !parse_range && l.peek() != "by" )
				return expression ~ " .. " ~ to;

			add_function( "iota" );

			if ( l.peek() == "by" )
			{
				l.pop();
				string by = expression_state( l.pop() );
				return format( "iota(%s, %s, %s)", expression, to, by );
			}

			expression = format( "iota(%s, %s)", expression, to );
		}

		return expression;
	}

	string list_comprehension_state( string token )
	{
		// Since we use indents for scope, brackets are fine for list comprehensions
		check_token( token, "{" );

		// Mapping function
		string map_fun = expression_state( l.pop() );

		// variable
		check_token( l.pop(), "for" );
		check_token_type( l.peek(), "identifier" );
		string var = l.pop();
		
		// range expression
		check_token( l.pop(), "in" );
		string range = expression_state( l.pop() );
		
		// Put it all together and what have you got?
		// Bippity boppity boo
		string list_comprehension = "map!(" ~ var ~ "=>" ~ map_fun ~ ")"
			~ "(" ~ range ~ ")";

		add_function( "map" );

		// Add filter clause
		if ( l.peek() == "where" )
		{
			add_function( "filter" );
			l.pop();
			string filter_fun = expression_state( l.pop() );
			list_comprehension ~= ".filter!(" ~ var ~ "=>" ~ filter_fun ~ ")";
		}
		
		check_token( l.pop(), "}" );

		return list_comprehension;
	}


	string instantiation_state( string token )
	{
		check_token( token, "new" );
		check_token_type( l.peek(), "class identifier" );
		string identifier = "new " ~ parse_type( l.pop() );
		
		check_token( l.pop(), "(" );

		return identifier ~ "(" ~ function_call_state( l.pop() );
	}

	/// Expecting the end of a line
	string endline_state( string token )
	{
		check_token( token, "\n" );
		return endline();
	}

	/// Blocks eat the rest of the input until it un-indents
	string block_state( string token )
	{
		string begin, block, end;
		string indent = join( repeat( l.indentation, l.block_level ) );

		// If this is a comment block
		if ( token != "passthrough" )
		{
			// First line has opening "/+"
			begin = "/+";
			if ( token == "#." )
				begin = "/++";

			begin ~= "\n" ~ indent ~ " + ";

			// Closing "+/"
			end = "/";
		}

		// Add first line to the result
		while ( l.peek() != "\n" )
			block ~= l.pop();

		// Add newline to the result
		block ~= l.pop();

		// If we're going into scope, 
		if ( l.peek() == "indent" )
		{
			// Begin every line with "+" 
			if ( token != "passthrough" )
				indent ~= " +";
			
			// Add indent
			l.pop();
			block ~= indent;

			string inside;
			int level = 1;
			
			while ( level > 0 )
			{
				/// Indentation inside the block
				/// Use 2 spaces in comments, tabs can mess up
				if ( token == "passthrough" )
					inside = join( repeat( l.indentation, level - 1 ) );
				else
					inside = " " ~ join( repeat( "  ", level - 1 ) );
				
				string next = l.pop();
				if ( next == "\n" )
					block ~= "\n" ~ indent;
				else if ( next == "indent" )
					level += 1;
				else if ( next == "dedent" )
					level -= 1;
				else
					block ~= inside ~ next;
			}
		}
		else if ( token == "#." )
		{
			return "/// " ~ block ~ indent;
		}
		else
		{
			return "// " ~ block ~ indent;
		}

		return begin ~ block ~ end ~ endline();
	}

	/// Inline comments just eat the rest of the line
	string inline_comment_state( string token )
	{
		check_token( token, "#", "#." );

		string comment;
		if ( token == "#" )
			comment = " // ";
		else if ( token == "#." )
			comment = " /// ";

		comment ~= l.pop();

		return comment ~ endline_state( l.pop() );
	}

	/// Object Orientation!
	string class_state( string token )
	{
		context.insertFront( "class" );
		check_token_type( token, "class identifier" );

		string class_identifier = token;

		// Check if this class is actually a template
		if ( l.peek() == "(" )
		{
			context.removeFront();
			context.insertFront( "template" );
			class_identifier ~= parse_template_types( l.pop() );
		}
		else if ( l.peek() == "<-" )
		{
			l.pop();
			check_token_type( l.peek(), "class identifier" );
			class_identifier ~= " : " ~ l.pop();
		}
			
		return class_identifier ~ colon_state( l.pop() );
	}

	string parse_template_types( string token )
	{
		check_token( token, "(" );
		check_token_type( l.peek(), "template type" );

		string template_types = token ~ l.pop();

		while ( l.peek() == "," )
		{
			template_types ~= l.pop();
			check_token_type( l.peek(), "template type" );
			template_types ~= l.pop();
		}

		check_token( l.pop(), ")" );
		return template_types ~ ")";
	}

	/// Newlines keep indent and stuff
	string newline_state( string token )
	{
		string endline = endline();
		
		// Don't use a newline if token is 'begin'
		if ( token == "begin" )
			endline = "";
		
		// In the case of empty newline, don't use indentation
		while ( !l.is_empty() && l.peek() == "\n" )
			endline = l.pop() ~ endline;

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
			// Store previous context for if-else and such
			previous_context = context.front;
			context.removeFront();
		}

		// Check if there's a block comment coming up
		if ( !l.is_empty() && ( l.peek() == "#" || l.peek() == "#." ) )
			return bracket ~ endline ~ block_state( l.pop() );
		else
			return bracket ~ endline;
	}

	string exception_state( string token )
	{
		// Keep track of context
		context.insertFront( token );

		// parse exception type
		string exception_type;
		if ( token == "except" )
		{
			exception_type = l.pop();
			exception_type ~= " " ~ l.pop();
		}

		// Check for proper context
		bool try_or_except =
			previous_context == "try" || previous_context == "except";

		string exception;
		if ( token == "try"
				|| token == "finally" && try_or_except )
			exception = token;
		else if ( token == "except" && try_or_except )
			exception = "catch (" ~ exception_type ~ ")";
		else
			throw new Exception( unexpected( token ) );

		return exception ~ colon_state( l.pop() );
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

	/// Add a function that Delight has but D doesn't
	void add_function( string func )
	{
		assert( func in include_functions );

		if ( include_functions[func] )
			return;

		include_functions[func] = true;
		
		switch ( func )
		{
			// "in" means "is in range" in Delight
			case "in":
				includes ~= "bool In(H, N)(H h, N n) {\n"
					~ "	foreach (i; h)\n"
					~ "		if (i == n) return true;\n"
					~ "	return false;\n"
					~ "}\n";
				break;

			// "x .. y" can create a range in Delight
			case "iota":
				includes ~= "import std.range : iota;\n";
				break;
		
			// Printing is so common, it deserves a keyword
			case "writeln":
				includes ~= "import std.stdio : writeln;\n";
				break;

			// For list comprehensions
			case "map":
			case "filter":
				includes ~= "import std.algorithm : " ~ func ~ ";\n";
				break;
			
			default:
				throw new Exception( "Cannot add " ~ func );
		}
	}
}
