pure auto add(int a, int b)
{
	return a + b;
}

unittest
{
	assert(add(1, 2) == 3);
	assert(add(0, 0) < 1);
}

void main()
{
	int c = add(3, 4);
}
