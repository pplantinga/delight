bool contains(H,N)(H h,N n){foreach(i;h)if(i==n)return true;return false;}
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

	if (contains([0,2,4],2))
	{
		x = z / 4;
	}
}
