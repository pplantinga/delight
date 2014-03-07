void main()
{
	int a;
	int b;
	try
	{
		a = b + 1;
		throw new Exception("This is an exception");
	}
	catch (Exception e)
	{
		a = b + 2;
		throw new Exception("Weird");
	}
	finally
	{
		a = b + 3;
	}
}
