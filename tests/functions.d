pure int add(int a, int b)
{
	return a + b;
}

pure auto subtract(T)(T a, T b)
{
	return a - b;
}

void subtractAdd(ref int a, ref int b)
{
	a = subtract(a, b);
	b = add(a, b);
}

void main()
{
	int c = add(2, 1);
	
	int d = subtract!int(2, 1);
	
	subtractAdd(c, d);
}
