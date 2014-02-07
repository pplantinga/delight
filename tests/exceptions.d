void main()
{
	int a;
	int b;
	try
	{
		a = b + 1;
	}
	catch (Exception e)
	{
		a = b + 2;
	}
	finally
	{
		a = b + 3;
	}
}
