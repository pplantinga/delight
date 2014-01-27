/**
 * Main for Delight programming language preprocessor.
 * Author: Peter Plantinga
 *
 * This program can be called from the command line using:
 * ----------------
 * delight {filename}.delight
 * ----------------
 *
 * This will parse the file and create another file '{filename}.d'
 * which is valid code in the d programming language. Run
 * ----------------
 * dmd {filename}.d
 * ----------------
 * to create an executable.
 */
module delight;

import delight.parser;
import std.stdio : writeln, File;
import std.algorithm : endsWith;

void main( string args[] )
{
	// Check for appropriate arguments
	if ( args.length < 2 || !endsWith( args[1], ".delight" ) )
	{
		writeln( "Usage: delight [file.delight]" );
		return;
	}

	/// Parse the input file
	auto p = new Parser( args[1] );
	string result = p.parse();
	
	/// Extract output filename by removing last 6 chars: test.d*elight*
	string filename = args[1][0 .. $-6];
	auto w = File( filename, "w" );

	// Write the results to the new file
	w.write( result );
}
