class Test
{
	int myvar;
	this()
	{
		myvar = 5;
	}
	protected
	{
		abstract void addto(int a)
		{
			myvar += a;
		}
	}
}

class Another(T)
{
	T myvar;
	
	auto addto(T)(T a)
	{
		myvar += a;
	}
}

class Tester : Test
{
	this(int x)
	{
		super();
		myvar = x;
	}
	override
	{
		void addto(int a)
		{
			myvar += a + 1;
		}
	}
}

void main()
{
	Tester a = new Tester(10);
	a.myvar = 6;
	a.addto(7);
	Another!int b = new Another!int();
	b.myvar = 8;
	b.addto(9);
}
