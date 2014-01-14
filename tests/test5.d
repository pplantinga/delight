
pure int add(int a, int b)
{
	return a + b;
}

pure auto subtract(T)(T a, T b)
{
	return a - b;
}

void main()
{
	int c = add(2, 1);
	
	int d = subtract(2, 1);
}
