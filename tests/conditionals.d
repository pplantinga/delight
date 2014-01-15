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
		
		z = x;
	}
	else if (!z)
	{
		y = 3;
	}
	else
	{
		z = x + y;
	}
}
