extern "C"
{
    #include "serial/rs232.h"
}
#include <cstdint>
#include <iostream>
#include <sys/stat.h> // to determine folder
#include <string>
#include <sstream>
#include <iostream>

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

using namespace cv;

// usage: ./auview absolute_path_to_folder
// the primary folder will hold a bunch of sub folders
int main(int argc, char* argv[])
{
    char mode[] = "8N1";
    const int COM_PORT = 0;
    if (RS232_OpenComport(COM_PORT, 921600, mode))
    {
        std::cout << "Could not find com port" << std::endl;
        return 0;
    }

	std::string folderName(argv[1]);
/*
	struct stat sb; 
	std::ostringstream pn; 
	int folderCount = 0;
	pn << argv[1] << "/" << folderCount;
	std::string pathname = pn.str();
*/
/* 
	if(stat(pathname.c_str(), &sb) == 0 && S_ISDIR(sb.st_mode))
	{
		// pathname is a directory
		folderCount++;
		pn << argv[1] << "/" << folderCount;
		pathname = pn.str();
	}
	else
	{
		// pathname is not a directory
		mkdir(pathname.c_str(), 0777);
	}
*/
    Mat M(240, 320, CV_8UC1, Scalar(0, 0, 0));

    const int32_t size = 320*240;
    uint8_t currentImage[size];
	int32_t currentImageNum = 0;
    int32_t index = 0;

    while (1==1)
    {
        // Get frame from UART
        while (index < size)
        {
            int len = RS232_PollComport(COM_PORT, &(M.data[index]), size - index);
            index += len;
        }

        // Show Image
        imshow("a", M);
        waitKey(1);
		std::ostringstream fileName;
		fileName << folderName << "/" << currentImageNum << ".png";
		imwrite(fileName.str(), M);
        printf("Frame recieved!\n");
        index = 0;
		currentImageNum++;
    }

    RS232_CloseComport(COM_PORT);
    std::cout << "Done!" << std::endl;

    return 0;
}
