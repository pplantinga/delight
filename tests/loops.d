void main()
{
	int[] arr = [1,2,3];
	int i = 0;
	foreach (x; arr)
	{
		i += x;
	}
	
	while (i < 10)
	{
		i *= 2;
		
		i -= 2;
	}
}
