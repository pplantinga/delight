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

	while (y < 10)
	{
		y *= 2;

		y -= 2;
	}
}
