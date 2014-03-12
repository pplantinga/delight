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
 * which is valid code in the d programming language and run
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
		writeln( "Usage: delight [<files>] [-- <compiler> [<compiler arguments>]]" );
		writeln( "Example: delight file.delight -- dmd -c file2.d" );
		return;
	}

	/// Parse the input files
	auto files = args[1 .. $].until("--");
	string[] output_files;
	foreach ( file; files )
	{		
		/// Extract output filename by removing last 6 chars: test.d*elight*
		string filename = file[0 .. $-6];
		auto w = File( filename, "w" );

		// Store the filename for the compilation command
		output_files ~= filename;

		// Parse the file
		auto p = new Parser( file );
		string result = p.parse();

		// Write the results to the new file
		w.write( result );
		w.close();
	}

	// Invoke compiler
	if ( canFind( args, "--" ) )
	{
		// Compiler name
		string[] compiler_args = [ args[ output_files.length + 2 ] ];
		if ( !canFind( ["dmd", "gdc", "ldc"], compiler_args[0] ) )
			throw new Exception( "Illegal compiler" );

		// Files
		compiler_args ~= output_files;

		// Passthrough arguments
		if ( args.length > output_files.length + 3 )
			compiler_args ~= args[ output_files.length + 1 .. $ ];
	
		writeln( "Executing: ", join( compiler_args, " " ) );

		auto compile = execute( compiler_args );
		if ( compile.status != 0 )
			writeln( "Compilation failed:\n ", compile.output );
	}
}
