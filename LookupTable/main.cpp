#include <iostream>
#include <fstream>
#include <cmath>

void generateBinaryCombinations(int n, const char* fileName) 
{
	int count = 0;
	ofstream file;
	file.open(fileName);
	while(count < pow(2, 14))
	{
		
	}
	file.close();
}


int main(int argc, char** argv)
{
	generateBinary(14, argv[1]); // argv[1] is the file name
}
