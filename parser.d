/**
 * Parser takes tokens one at a time and
 * - checks for syntax errors
 * - generates valid d code
 */
class parser
{
	string state;

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
		"'",
		"#"
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

	this()
	{
		state = "start state";
	}

	string process( string token )
	{
		return token;
	}
}
