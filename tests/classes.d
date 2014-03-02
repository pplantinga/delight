class test
{
	int myvar = 5;
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
	tester a = new tester();
	a.myvar = 6;
	a.addto(7);
	another!int b = new another!int();
	b.myvar = 8;
	b.addto(9);
}
