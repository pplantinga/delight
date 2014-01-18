void main()
{
	int[] arr = [1,2,3];
	int i = 0;
	foreach (x; arr)
	{
		i += x;
	}
	
	foreach (j; 0 .. 5)
	{
		i -= j;
	}
	
	while (i < 10)
	{
		i *= 2;
		
		i -= 2;
	}
}
