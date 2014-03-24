import std.stdio : writeln;
pure int add(int a, int b)
{
	return a + b;
}

pure int[][] args(int a, int b, int c, int d, int e, double f, double g, int[] so_many_args)
{
	return [[2], [3]];
}

pure auto divide(T)(T a, T b)
in
{
	assert(b != 0);
}
out (result)
{
	assert(result > 0);
}
body
{
	return a / b;
}

void divideAdd(ref int a, ref int b)
{
	scope (exit)
	{
		b = add(a, b);
	}
	a = divide(a, b);
}

void main()
{
	int c = add(2, 1);

	int d = divide!int(2, 1);

	divideAdd(c, d);
	
	writeln(c);
	writeln(d);
}
