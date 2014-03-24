import std.stdio : writeln;
void main()
{
	int a;
	int b;
	try
	{
		a += b + 1;
		throw new Exception("This is an exception");
	}
	catch (Exception e)
	{
		a += b + 2;
		throw new Exception("Weird");
	}
	catch
	{
		a += b + 4;
	}
	finally
	{
		a += b + 3;
		writeln( a );
	}
}
