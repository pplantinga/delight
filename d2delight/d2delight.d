/**
 * This script is for translating programs written in D
 * to the delight programming language.
 */
import std.regex;
import std.stdio;
import std.algorithm;
import std.file;

void main( string[] args )
{
	if ( args.length != 2 || !endsWith( args[1], ".d" ) )
	{
		writeln( "usage: d2delight file.d" );
		return;
	}

	auto w = File( args[1] ~ "elight", "w" );
	auto r = read( args[1] );
	w.write( r );
}
