import std.stdio;

void main()
{
	int abcd = 3;

	for ( int i = 3; i < 5; i++ )
	{
		abcd += i;
		if ( i < 4 )
			abcd = 2 * 5;
	}

	int[] array = [2,3,4,5,6];
	foreach ( i; array )
	{
		abcd -= i;
	}
}
