Delight
=======

Delight is a D programming language preprocessor. The resulting language, called "Delight" has a Python-like syntax, with a touch of Haskell and Ada. The philosophy is like Python's, that there should be one obvious way to do things.

There is an opportunity to discuss language features at [pplantinga.github.io](http://pplantinga.github.io).

Installing Delight
------------------

If you want to install this program, first make sure you have at least dmd 2.064 installed. Then you can clone this repository, build using dub (or manually compile using all the files in the source directory), and copy the "delight" executable to a directory included in your "PATH" variable.

Execute using

	delight file-0.delight [file-n.delight]* [-- [dmd parameters] [d files]]

which will create file-0.d in the same directory and compile using dmd.

Delightful Features
-------------------

Let's start with some example code, and then we can analyze it.

	# Welcome to delight!

	#. This is our first function, "add"
		it takes two addable items, and returns the sum.
	function add(T a, b -> T):
		return a + b
	unittest:
		assert add( 2, 3 ) equal to 5
		assert add( 0, 0 ) less than 1

	procedure main:

		int[] array = [ 1, 2, 3 ]
		for element in array:

			if element in 0 .. 2:
				print "it's in!"

			else if element equal to 3:
				print add( element, 2 )

			else:
				print "it's out!"

In delight, as in python, scope is determined by indentation. You can indent with spaces or tabs, but it must be consistent throughout the file.

Delight is strongly typed, like D, but can do type inference using the D keyword auto. Function definitions start with something like Haskell's type definitions. Templates can be easily created by using a single uppercase letter instead of a type. Leaving off parameters works as expected, and leaving off a return type returns auto (which deduces type).

Functions are like mathematical functions, they don't have side-effects. Procedures don't return anything, but all their arguments are passed by reference. And methods are part of a class definition, and thus make some change to the class internals.

Like python, delight leans towards using keywords over symbols. Examples: in, less than, and, equal to, etc. The exceptions are operators and some punctuation, like "," "->" "[" "+=" "^" etc. Every operator with = in it is an assignment operator.

Function definitions, loops, class definitions, conditionals, and pretty much everything that has a scope ends in ":".

Comments start with "#" and if they have a "." they are documentation comments. They whitespace-delimited.

The language as it stands here is subject to expansion and change, it's still in it's infancy. I'll keep a list here of the keywords and what they do once they solidify a bit more.
