/**
 * Block comment
 */
import std.stdio;

int add( int a, int b )
{
	return a + b;
}

void writeLine( string toprint )
{
	writeln( toprint );
}

class Da_Class
{
	int a = 5;
	int add( int b )
	{
		a += b;
		return a;
	}
}

void main()
{
	int abcd = 3;

	for ( int i = 3; i < 5; i++ )
	{
		abcd += i;
		if ( i < 4 && i > 0 )
			abcd = add( i, 2 );
	}

	int[] array = [2,3,4,5,6];
	foreach ( i; array )
	{
		abcd -= i;
	}

	auto sum = 1;
	while ( sum <= 20 )
	{
		sum++;
		switch ( sum )
		{
			case 1:
				sum++;
				break;
			case 2:
				sum += 2;
				break;
			case 5:
				sum += 5;
				break;
			default:
				sum = sum * 2;
		}
	}
}
