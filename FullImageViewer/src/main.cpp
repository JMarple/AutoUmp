extern "C"
{
    #include "serial/rs232.h"
}
#include <cstdint>
#include <iostream>

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

using namespace cv;

int main()
{
    char mode[] = "8N1";
    const int COM_PORT = 0;
    if (RS232_OpenComport(COM_PORT, 921600, mode))
    {
        std::cout << "Could not find com port" << std::endl;
        return 0;
    }

    Mat M(240, 320, CV_8UC1, Scalar(0, 0, 0));

    const int32_t size = 320*240;
    uint8_t currentImage[size];
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
        printf("Frame recieved!\n");
        index = 0;
    }

    RS232_CloseComport(COM_PORT);
    std::cout << "Done!" << std::endl;

    return 0;
}
