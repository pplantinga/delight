import std.stdio : writeln;
import std.algorithm;

pure int add(int a, int b)
{
	return a + b;
}

pure int[][] args(int a, int b, int c, int d, int e, double f, double g = 10.0, int[] so_many_args = null)
{
	return [[2], [3]];
}

pure auto divide(T)(T a, T b)
{
	assert(b != 0);

	scope (exit)
	{
		assert(a / b > 0);
	}

	return a / b;
}

void divideAdd(ref int a, ref int b)
{
	a = divide(a, b);
	b = add(a, b);
}

void main()
{
	int c = add(2, 1);

	int d = divide!int(2, 1);

	auto e = map!(f => f * 2)(args(1, 2, 3, 4, 5, 6));

	divideAdd(c, d);
	
	writeln(c);
	writeln(d);
}
