Delight
=======

Delight is a D programming language preprocessor. The resulting language, called "Delight" has a Python-like syntax, with a touch of Haskell and Ada. The philosophy is like Python's, that there should be one obvious way to do things.

There is an opportunity to discuss language features at [pplantinga.github.io](http://pplantinga.github.io).

Delightful Features
-------------------

Let's start with some example code, and then we can analyze it.

	function add: int a, b -> int
		return a + b

	procedure main:
		array = [ 1, 2, 3 ]
		foreach element in array:
			if element less than 2 and element greater than 0:
				writeln( add( element, 4 ) )
			else:
				writeln( add( element, -2 ) )

In delight, as in python, scope is determined by indentation. You can indent with spaces or tabs, but it must be consistent throughout the file.

Delight is strongly typed, like D, but can do type inference using the D keyword auto. Function definitions start with something like Haskell's type definitions. Templates can be easily created by using T or some such instead of a type. Leaving off parameters works as expected, and leaving off a return type returns void.

Functions are like mathematical functions, they don't have side-effects. Procedures can do whatever they want. And methods are part of a class definition, and thus make some change to the class internals.

Like python, delight leans towards using keywords over symbols. Examples: in, less than, and, equals, etc. The exceptions are operators and some punctuation, like "," "->" "[" "+=" "^" etc.

Loops and conditionals end in ":"

The language as it stands here is subject to expansion and change, it's still in it's infancy. I'll keep a list here of the keywords and what they do once they solidify a bit more.
