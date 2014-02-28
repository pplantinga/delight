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
module delight.app;

import delight.parser;
import std.stdio;
import std.algorithm;
import std.process;
import std.array;

void main( string args[] )
{
	// Check for appropriate arguments
	if ( args.length < 2 || !endsWith( args[1], ".delight" ) )
	{
		writeln( "Usage: delight [<files>] [-- <dmd arguments>]" );
		return;
	}

	/// Parse the input files
	auto files = args[1 .. $].until("--");
	string[] dmd_args = ["dmd"];
	foreach ( file; files )
	{		
		/// Extract output filename by removing last 6 chars: test.d*elight*
		string filename = file[0 .. $-6];
		auto w = File( filename, "w" );

		// Append the filename to the compilation command
		dmd_args ~= filename;

		// Parse the file
		auto p = new Parser( file );
		string result = p.parse();

		// Write the results to the new file
		w.write( result );
		w.close();
	}

	// Pass arguments through
	if ( canFind( args, "--" ) )
		dmd_args ~= args[ dmd_args.length + 1 .. $ ];
	
	// Call DMD
	writeln( "Executing: ", join( dmd_args, " " ) );
	auto dmd = execute( dmd_args );
	if ( dmd.status != 0 )
		writeln( "Compilation failed:\n ", dmd.output );
}
