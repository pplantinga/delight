Delight
=======

Delight is a D programming language preprocessor. The resulting language, called "Delight" has a Python-like syntax, with a touch of Haskell and Ada. The philosophy is like Python's, that there should be one obvious way to do things.

There is an opportunity to discuss language features at [pplantinga.github.io](http://pplantinga.github.io).

Installing Delight
------------------

If you want to install this program, first make sure you have at least dmd 2.064 installed. Then you can clone this repository, build using dub (or manually compile using all the files in the source directory), and copy the "delight" executable to a directory included in your "PATH" variable.

Using Delight
-------------

To convert your pre-existing D program to Delight, simply use the d2delight.py python script. It will get you most of the way there, but it's not perfect, so you'll have to clean up a few things yourself. For example, right now it has a little trouble with for-loops that are more complicated than just `i = 0; i < x; i++`, since Pythonic for-loops are quite different.

You can execute the Delight preprocessor using:

	delight {filename}.delight [{filename}.delight]* [-- {compiler} [{options}]]

which will create {filename}.d for each source file in the same directory. If you include the compiler command (dmd, ldc, or gdc) then this program will compile the code as well. Options are just passed through to the compiler, including any source files already in D.

Delightful Features
-------------------

Let's start with some example code, and then we can analyze it.

	# Welcome to Delight!
		Author: Peter Massey-Plantinga

	#. This is our first function, "add"
		it takes two addable items, and returns the sum.
	function add(T a, b -> T):
		return a + b
	unittest:
		assert add( 2, 3 ) equal to 5
		assert add( 0, 0 ) less than 1

	procedure main:

		auto array = [ "a": 1, "b": 2, "c": 3 ]
		for key, element in array:

			if element in [ 0, 2, 4 ]:
				print key ~ "'s in!"

			else if element equal to 3:
				print add( element, 2 )

			else:
				print key ~ "'s out!"

In Delight, as in Python, scope is determined by indentation. You can indent with spaces or tabs, but it must be consistent throughout the file.

Delight is strongly typed, like D, but can do type inference using the D keyword auto. Function definitions start with something like Haskell's type definitions. Templates can be easily created by using a single uppercase letter instead of a type. Leaving off a return type uses the D keyword 'auto' (which deduces type).

Functions are like mathematical functions, they don't have side-effects (thanks to the D keyword "pure") and procedures don't return anything, but all their arguments are passed by reference. Methods are part of a class definition, and thus can make state changes to the class internals.

Like Python, Delight leans towards using keywords over symbols. Examples: in, less than, and, equal to, etc. The exceptions are operators ( +, -, %, etc. ) and some punctuation ("," "->" ":" etc) One cool feature of this is that every operator with "=" in it is an assignment operator.

Function definitions, loops, class definitions, conditionals, and pretty much everything that has a scope ends in ":".

Comments start with "#" and if they have a "." they are documentation comments. They are whitespace-delimited, which avoids problems of nesting a little more cleanly than D's 6 different types of comments, and Python's multi-line strings as the only multi-line comments.

The language as it stands here is subject to expansion and change, it's still in it's infancy.

Read more at [pplantinga.github.io/archives/delight-programming-language.html](http://pplantinga.github.io/archives/delight-programming-language.html)
