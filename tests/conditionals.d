bool In(H, N)(H h, N n) {
	foreach (i; h)
		if (i == n) return true;
	return false;
}
import std.stdio : writeln;
void main()
{
	int x = 1;
	int y = 2;
	int z = 4;

	if (x >= y && x > z - y)
	{
		x = y + z;
	}

	else if (x == y + z || x + 2 != z)
	{
		y = z;

		if (y == 3)
		{
			z = x;
		}
		else
		{
			z = y;
		}
	}

	else if (!z)
	{
		y = 3;
	}
	else
	{
		z = x + y;
	}

	int[] a = [1, 2, 5];
	if (In(a, 2))
	{
		writeln("yes");
	}

	int[string] b = ["a": 1, "b": 2];
	if ("a" in b)
	{
		writeln("yes");
	}

	switch (x)
	{
		case 1:
		case 3:
			x = 2;
			return;
		case 2:
			x = 3;
			throw new Exception("Some error");
		case 4:
			x = 9;
			break;
		default:
			x = 5;
		
	}
}
