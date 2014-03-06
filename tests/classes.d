class test
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

class another(T)
{
	T myvar;
	
	auto addto(T)(T a)
	{
		myvar += a;
	}
}

class tester : test
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
	tester a = new tester(10);
	a.myvar = 6;
	a.addto(7);
	another!int b = new another!int();
	b.myvar = 8;
	b.addto(9);
}
