void main()
{
	string greeting = "Hello";
	greeting ~= `, world!`;

	static immutable THE_CONSTANT = "Never gonna change";

	int[] not_constant = null;
	bool the_truth = true;
	bool not_the_truth = false;

	auto d = 5_432.1e-3;
	d *= 3.3e4;
	d ^^= 3;

	auto i = 5;
	i -= 2;
	i += 4_000;
	i %= 7;
	i /= 3;
}
