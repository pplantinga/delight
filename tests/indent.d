
void main()
{
	pure int add(int a, int b)
	{
		int c = a + b;
		
		return c;
	}
	
	int c = add(1, 2);
	
	int d = add(c, 2);
}
