import std.range : iota;
import std.algorithm : map;
import std.algorithm : filter;
void main()
{
	int[] arr = [1, 2, 3];
	foreach (i, ref x; arr)
	{
		x += 2;
	}

	int y = 2;
	foreach (j; 0 .. 5)
	{
		y *= j;
		if (y > 0)
		{
			break;
		}
	}

	foreach (k; iota(0, 10, 2))
	{
		y -= k;
	}

	foreach (l; filter!(x => x ^^ 2 > 3)(iota(0, 10)).map!(x=>2 * x))
	{
		y /= l;
	}

	while (y >= -10)
	{
		y %= 2;

		y -= 100;
	}
}
