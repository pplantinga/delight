/++
 + docblock
 + author: Peter Plantinga
 +/

/+
 + not docblock
 +
 + with a break in the middle
 +   and indentation
 + back to normal
 +/

void main()
{
	/++
	 + indented docblock
	 +/
	int x = 5; // inline
	int y = 6; /// inline doc
}
