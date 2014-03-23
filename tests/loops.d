import std.range : iota;
import std.algorithm : map;
import std.algorithm : filter;
void main()
{
	int[] arr = [1, 2, 3];
	int y = 0;
	foreach (i, x; arr)
	{
		y += x;
	}

	foreach (j; 0 .. 5)
	{
		y -= j;
		if (y < 0)
		{
			break;
		}
	}

	foreach (k; iota(0, 10, 2))
	{
		y *= k;
	}

	foreach (l; map!(x=>2 * x)(iota(0, 10)).filter!(x=>x ^^ 2 > 3))
	{
		y /= l;
	}

	while (y < 10)
	{
		y *= 2;

		y -= 2;
	}
}
