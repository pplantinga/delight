bool contains(H,N)(H h,N n){foreach(i;h)if(i==n)return true;return false;}
import std.algorithm : iota;
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

	if (contains(iota(0,3),2))
	{
		writeln("yes");
	}
}
