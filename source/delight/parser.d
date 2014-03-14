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
		"in",
		"out",
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
			"number literal"      : regex( `^[0-9]+.?[0-9]*$` ),
			"operator"            : regex( `^([+*%^/~-]|\.\.)$` ),
			"punctuation"         : regex( `^([.,!:()\[\]#]|#\.|->)$` ),
			"statement"           : regexify( statements ),
			"string literal"      : regex( `^".*"$` ),
			"template type"       : regex( `^[A-Z]$` ),
			"type"                : regexify( types ),
			"user type"           : regexify( user_types )
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
		assert( p.identify_token( "out" ) == "contract" );
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
			auto result = read( "tests/" ~ test ~ ".d" );
			assert( p.parse() == result );
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
				string type = parse_type( token );
				return type ~ declare_state( l.pop() );
			case "template type":
				if ( canFind( context.opSlice(), "template" ) )
					return token ~ declare_state( l.pop() );
				else
					throw new Exception( unexpected( token ) );
			case "function type":
				return function_declaration_state( token );
			case "identifier":
				string result = identifier_state( token );

				// Except for functions, check for assignment
				if ( result[$-1] != ')'
						&& identify_token( l.peek() ) == "assignment operator" )
					return result ~ assignment_state( l.pop() );
				else if ( result[$-1] == ')' && l.peek() == "\n" )
					return result ~ ";" ~ endline_state( l.pop() );
				else if ( l.peek() == "\n" )
					return result ~ ";" ~ endline_state( l.pop() );
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

		// parse result token
		if ( token == "out" && identify_token( l.peek() ) == "identifier" )
			token ~= " (" ~ l.pop() ~ ")";

		return token ~ colon_state( l.pop() );
	}

	string statement_state( string token )
	{
		switch ( token )
		{
			case "for":
				return foreach_state( token );
			case "while":
				return while_state( token );
			case "return":
				return return_state( token );
			case "assert":
				return token ~ "(" ~ expression_state( l.pop() ) ~ ");";
			case "unittest":
				context.insertFront( "unittest" );
				return token ~ colon_state( l.pop() );
			case "break":
			case "continue":
				if ( !canFind( context.opSlice(), "for" )
						&& !canFind( context.opSlice(), "while" ) )
					throw new Exception( unexpected( token ) );
				else
					return token ~ ";";
			case "raise":
				if ( identify_token( l.peek() ) == "string literal" )
					return "throw new Exception(" ~ expression_state( l.pop() ) ~ ");";

				check_token( l.pop(), "new" );
				string exception = l.pop();
				check_token_type( exception, "class identifier" );
				
				return "throw new " ~ exception ~ expression_state( l.pop() ) ~ ";";
			case "print":
				add_function( "print" );
				return "writeln(" ~ expression_state( l.pop() ) ~ ");";
			case "passthrough":
				return passthrough_state( token );
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
		string array = expression_state( l.pop() );

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
		string next = l.pop();

		string statement = "return";

		if ( next != "\n" )
		{
			statement ~= " " ~ expression_state( next );
			next = l.pop();
		}

		statement ~= ";" ~ endline_state( next );

		// Ensure we don't write a "break" right after a "return"
		if ( context.front == "case" && l.peek() == "dedent" )
		{
			string dedent = l.pop();
			if ( l.peek() != "case" )
				return statement ~ newline_state( dedent );
			else
				context.removeFront();
		}

		return statement;
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
		string result;

		// Array declarations
		if ( token == "[" )
		{
			result = "[";

			while ( l.peek() != "]" )
			{
				if ( identify_token( l.peek() ) == "type" )
					result ~= l.pop();
				else if ( l.peek() != "," )
					result ~= expression_state( l.pop() );

				if ( l.peek() == "," )
				{
					result ~= "][";
					l.pop();
				}
			}

			// End bracket
			result ~= l.pop();

			// Array identifier
			token = l.pop();
		}

		check_token_type( token, "identifier" );
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

		string type = parse_type( l.pop() );

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

		// Add end bracket
		return result ~ l.pop();
	}

	/// array literals can have commas and only one set of exterior brackets
	string array_literal_state( string token )
	{
		string result = token;

		while ( l.peek() != "]" )
		{
			result ~= expression_state( l.pop() );

			if ( l.peek() == "," || l.peek() == ":" )
				result ~= l.pop() ~ " ";
			else
				check_token( "]", l.peek() );
		}
		
		return result ~ l.pop();
	}

	/// Expression state
	string expression_state( string token )
	{
		string expression;

		if ( token == "new" )
			return instantiation_state( token );

		switch ( identify_token( token ) )
		{
			case "string literal":
			case "character literal":
			case "number literal":
				expression = token;
				break;
			case "identifier":
			case "constant":
			case "constructor":
				expression = identifier_state( token );
				break;
			default:
				switch( token )
				{
					case "not":
						expression = "!" ~ expression_state( l.pop() );
						break;
					case "[":
						expression = array_literal_state( token );
						break;
					case "-":
					case "(":
						expression = token ~ expression_state( l.pop() );
						break;
					case "#":
					case "#.":
						expression = block_state( token );
						expression ~= expression_state( l.pop() );
						break;
					case "\n":
						string newline = newline_state( token );
						expression = newline ~ expression_state( l.pop() );
						break;
					case "indent":
					case "dedent":
						expression = expression_state( l.pop() );
						break;
					default:
						throw new Exception( unexpected( token ) );
				}
		}

		// While there's unbalanced parentheses
		// parse newlines, comments, and end parentheses
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
				|| identify_token( l.peek() ) == "logical"
				|| l.peek() == "in" )
		{
			// Convert operator into D format
			string op = l.pop();
			
			// "in" means something different in delight
			if ( op == "in" )
			{
				add_function( "contains" );
				string haystack = expression_state( l.pop() );
				expression = "contains(" ~ haystack ~ "," ~ expression ~ ")";
				continue;
			}
			
			// Not combines with the next token
			if ( op == "not" )
				op = "not " ~ l.pop();

			if ( op in conversion )
				op = conversion[op];

			// Here we're after the conversion, so we're talking about D's "in"
			if ( op == "in" || op == "!in" )
			{
				string key = expression_state( l.pop() );
				expression = key ~ " " ~ op ~ " " ~ expression;
				continue;
			}

			expression ~= " " ~ op ~ " " ~ expression_state( l.pop() );

			balance_parens( expression );
		}

		return expression;
	}

	void balance_parens( ref string expression )
	{
		string[] valid_tokens = [
			"\n",
			"indent",
			"dedent",
			"#",
			"#.",
			")"
		];

		while ( canFind( valid_tokens, l.peek() )
				&& !balancedParens( expression, '(', ')' ) )
		{
			switch ( l.peek() )
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
					writeln( l.peek() );
					break;
				case ")":
					expression ~= l.pop();
					break;
				default:
					break;
			}
		}
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
		string result, end;
		string indent = join( repeat( l.indentation, l.block_level ) );

		// If this is a comment block
		if ( token != "passthrough" )
		{
			// Format nicely
			indent ~= " +";

			// First line has opening "/+"
			result = "/+";
			if ( token == "#." )
				result = "/++";

			result ~= "\n" ~ indent ~ " ";

			// Closing "+/"
			end = "/";
		}

		// Add first line to the result
		while ( l.peek() != "\n" )
			result ~= l.pop();

		// Add newline to the result
		result ~= l.pop() ~ indent;

		// If we're going into scope, 
		if ( l.peek() == "indent" )
		{
			l.pop();
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
					result ~= "\n" ~ indent;
				else if ( next == "indent" )
					level += 1;
				else if ( next == "dedent" )
					level -= 1;
				else
					result ~= inside ~ next;
			}
		}

		return result ~ end ~ endline();
	}

	/// Inline comments just eat the rest of the line
	string inline_comment_state( string token )
	{
		check_token( token, "#", "#." );

		string result;
		if ( token == "#" )
			result = " // ";
		else if ( token == "#." )
			result = " /// ";

		result ~= l.pop();

		return result ~ endline_state( l.pop() );
	}

	/// Object Orientation!
	string class_state( string token )
	{
		context.insertFront( "class" );
		check_token_type( token, "class identifier" );

		string result = token;

		// Check if this class is actually a template
		if ( l.peek() == "(" )
		{
			context.removeFront();
			context.insertFront( "template" );
			result ~= parse_template_types( l.pop() );
		}
		else if ( l.peek() == "<-" )
		{
			l.pop();
			check_token_type( l.peek(), "class identifier" );
			result ~= " : " ~ l.pop();
		}
			
		return result ~ colon_state( l.pop() );
	}

	string parse_template_types( string token )
	{
		check_token( token, "(" );
		check_token_type( l.peek(), "template type" );

		string result = token ~ l.pop();

		while ( l.peek() == "," )
		{
			result ~= l.pop();
			check_token_type( l.peek(), "template type" );
			result ~= l.pop();
		}

		check_token( l.pop(), ")" );
		return result ~ ")";
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
			default:
		}
	}
}
