class test
{
	int myvar = 5;
	auto addto(int a)
	{
		myvar += a;
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

void main()
{
	test a = new test();
	a.myvar = 6;
	a.addto(7);
	another!int b = new another!int();
	b.myvar = 8;
	b.addto(9);
}
