#include <iostream>

int main(){

	for (int y = 1; y <= 9; ++y){
		for (int x = 1; x <= 9; ++x){
			if (std::cin.eof()){
				std::cout << "Error: Malformed sudoku" << std::endl;
				return 1;
			}
			int n;
			std::cin >> n;
			if (n > 0){
				std::cout << "s(" << x << "," << y << "," << n << ")." << std::endl;
			}
		}
	}

	return 0;
}
