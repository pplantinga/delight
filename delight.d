import std.stdio;
import std.algorithm;
import std.range;
import std.conv;
import lexer;
import parser;

void main( string args[] )
{
	// Check for arguments
	if ( args.length < 2 || find( args[1], "." ) != ".delight" )
	{
		writeln( "Usage: delight [file.delight]" );
		return;
	}

	// Extract filename
	string reverse = to!(string)(retro( args[1] ));
	string filename = to!(string)(retro( find( reverse, '.' ) ));
	auto w = File( filename ~ "d", "w" );

	// Get tokens from lexer
	parser p = new parser( args[1] );
	string result = p.parse();

	w.write( result );
}
