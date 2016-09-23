void main()
{
	pure int add(int a, int b)
	{
		int c = a + b;

		return c;
	}

	int c = add(1, 2);

	int d1 = add(c, 2);
}
