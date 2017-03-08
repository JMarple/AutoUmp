extern "C"
{
    #include "serial/rs232.h"
}
#include <cstdint>
#include <iostream>
#include <cstdint>
#include <algorithm>
#include <string>

#include <opencv2/core/core.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

using namespace cv;

#define IMG_WIDTH 320
#define IMG_HEIGHT 240
#define EMPTY_OBJECT_ID 65535


#define RED 0
#define GREEN 1
#define BLUE 2

// makes a red cross hair, with the center at the given x, y position.
void makeCrosshairs(Mat* colorImage, uint16_t x, uint16_t y, uint16_t color)
{
    if(x >= IMG_WIDTH || y >= IMG_HEIGHT)
	{
		printf("pixel given is out of bounds. You gave me: x = %i, y = %i. hex: %x, %x\n", x, y, x, y);
		return;
	}

	// cross hair is going to have tails that are 5 pixels long and 1 pixel wide.
    Vec3b bgr;
    
    if(color == RED)
    {
        bgr.val[0] = 0; // blue
        bgr.val[1] = 0; // green
        bgr.val[2] = 255; // red
    }
    else if(color == GREEN)
    {
        bgr.val[0] = 0; // blue
        bgr.val[1] = 255; // green
        bgr.val[2] = 0; // red 
    }
    else if(color == BLUE)
    {
        bgr.val[0] = 255; // blue
        bgr.val[1] = 0; // green
        bgr.val[2] = 0; // red     
    }


    int8_t crosshairsLength = 5;

    // go along columns
	int tmpXLower = max(x-crosshairsLength, 0);
	int tmpXUpper = min(x+crosshairsLength, IMG_WIDTH);
    for(int i = tmpXLower; i <= tmpXUpper; i++)
    {
        colorImage->at<Vec3b>(Point(i,y)) = bgr;
    }

    // go along rows. Some redudancy, but w/e...
	int tmpYLower = max(y-crosshairsLength, 0);
	int tmpYUpper = min(y+crosshairsLength, IMG_HEIGHT);
    for(int j = tmpYLower; j <= tmpYUpper; j++)
    {
        colorImage->at<Vec3b>(Point(x,j)) = bgr;
    }
}


void makeLine(Mat* colorImage, uint16_t rowOrColumn, uint16_t color, uint16_t isVertical)
{
    Vec3b bgr;
    
    if(color == RED)
    {
        bgr.val[0] = 0; // blue
        bgr.val[1] = 0; // green
        bgr.val[2] = 255; // red
    }
    else if(color == GREEN)
    {
        bgr.val[0] = 0; // blue
        bgr.val[1] = 255; // green
        bgr.val[2] = 0; // red 
    }
    else if(color == BLUE)
    {
        bgr.val[0] = 255; // blue
        bgr.val[1] = 0; // green
        bgr.val[2] = 0; // red     
    }

    if(isVertical)
    {
        for(int i = 0; i < IMG_HEIGHT; i++)
        {   
            colorImage->at<Vec3b>(Point(rowOrColumn, i)) = bgr;
        }
    }
    else
    {
        for(int i = 0; i < IMG_WIDTH; i++)
        {   
            colorImage->at<Vec3b>(Point(i, rowOrColumn)) = bgr;
        }
    }
}

struct Object
{
    uint8_t  isBall; // -1 = not checked, 0 = no, 1 = yes
    uint16_t id; // id representing object
    uint16_t minX, maxX, minY, maxY; // lower/uppper bounds of object
    uint16_t centX, centY;
    uint16_t distanceFromCenter;
};

int32_t unpackCenters(
    struct Object* objArray,
    uint8_t* buffer,
    uint16_t bufferLength)
{
    for(int i = 1; i < bufferLength; i+=4) // i = 1 because I think there's a 0 byte at the front
    {
        uint8_t xLower = buffer[i]; // each of these is flipped from what I would expect 
        uint8_t xUpper = buffer[i+1];
        uint8_t yLower = buffer[i+2];
        uint8_t yUpper = buffer[i+3];

		uint16_t centX = (xUpper << 8) | xLower;
		uint16_t centY = (yUpper << 8) | yLower;

		if(centX == 0xFFFF) // that's our cue -- we've hit our last object
		{
			return i/4+1; // num objects
			break;
		}

        objArray[i/4].centX = centX;
        objArray[i/4].centY = centY;
    }
	return bufferLength/4; // num objects
}

int32_t unpackBoundingBoxes(
	struct Object* objArray,
	uint8_t* buffer,
	uint16_t bufferLength)
{
	for(int i = 0; i < bufferLength; i+=8)
	{
		uint8_t xMinLower = buffer[i+1];
		uint8_t xMinUpper = buffer[i];
		uint8_t xMaxLower = buffer[i+3];
		uint8_t xMaxUpper = buffer[i+2];
		uint8_t yMinLower = buffer[i+5];
		uint8_t yMinUpper = buffer[i+4];
		uint8_t yMaxLower = buffer[i+7];
		uint8_t yMaxUpper = buffer[i+6];

		uint16_t xMin = (xMinUpper << 8) | xMinLower;
		uint16_t xMax = (xMaxUpper << 8) | xMaxLower;
		uint16_t yMin = (yMinUpper << 8) | yMinLower;
		uint16_t yMax = (yMaxUpper << 8) | yMaxLower;

		objArray[i/4].minX = xMin;
		objArray[i/4].maxX = xMax;
		objArray[i/4].minY = yMin;
		objArray[i/4].maxY = yMax;	
	}
	return bufferLength/8; // numObjects
}


void packCenters(
    struct Object* objArray,
    uint8_t* buffer,
    int32_t numObjects)
{
    for(int i = 0; i < numObjects; i++)
    {
        uint8_t xLower = objArray[i].centX & 0xFF;
        uint8_t xUpper = objArray[i].centX >> 8;
        uint8_t yLower = objArray[i].centY & 0xFF;
        uint8_t yUpper = objArray[i].centY >> 8;

        buffer[i*4] = xLower;
        buffer[i*4 + 1] = xUpper;
        buffer[i*4 + 2] = yLower;
        buffer[i*4 + 3] = yUpper;
    }
}

void initObjectArray(struct Object* objArray, uint16_t length)
{
    for (int i = 0; i < length; i ++)
    {
        objArray[i].id = EMPTY_OBJECT_ID;
        objArray[i].isBall = -1;
        objArray[i].minX = IMG_WIDTH;
        objArray[i].maxX = 0;
        objArray[i].minY = IMG_HEIGHT;
        objArray[i].maxY = 0;
        objArray[i].centX = 0;
        objArray[i].centY = 0;
        objArray[i].distanceFromCenter = 0;
    }
}

void printCenters(struct Object* objArray, uint16_t length)
{
    uint16_t i = 0;
    while((i < length) && (objArray[i].centX != 65535))
    {
        printf("centX: %x; centY: %x. decimal %i, %i \n",
            objArray[i].centX,
            objArray[i].centY,
			objArray[i].centX,
			objArray[i].centY);
        i++;
    }
    printf("\n");
}


int main(int argc, char** argv)
{
	char mode[] = "8N1";
   	const int COM_PORT = 0;
    if (RS232_OpenComport(COM_PORT, 921600, mode))
    {
        std::cout << "Could not find com port" << std::endl;
        return 0;
    }
	
	// these are only used if we are given a foldername to store files
	std::string folderName;
	int32_t currentImageNumber = 0;
	if(argc == 2)
	{
		folderName = std::string(argv[1]);
	}

	// general init
    Mat M(240, 320, CV_8UC1, Scalar(0, 0, 0));
	Mat M_color;
    const int32_t size = 40*240;
    uint8_t currentImage[size];
    int32_t indexPic = 0;
	int32_t indexObjects = 0;
	const int32_t sizeObjects = 250*4; // 250 objects * 4 bytes to represent the center
	uint8_t objectBuffer[sizeObjects];

	for(int i = 0; i < sizeObjects; i++)
	{
		objectBuffer[i] = 0;
	}
	struct Object objArray[250];
	initObjectArray(objArray, 250);

    /*
	// make fake data
	struct Object fakeObjArray[250];
	initObjectArray(fakeObjArray, 250);
	for(int i = 0; i < 250; i++)
	{
		fakeObjArray[i].centX = i; 
		fakeObjArray[i].centY = i*5 % IMG_HEIGHT;
	}
	packCenters(fakeObjArray, objectBuffer, 249); 
	*/
    while (1==1)
    {
 		for(int i = 0; i < sizeObjects; i++)
		{
			objectBuffer[i] = 0;
		}
		struct Object objArray[250];
		initObjectArray(objArray, 250);

        // Get frame from UART
        while (indexPic < size)
        {
            int len = RS232_PollComport(COM_PORT, &(currentImage[indexPic]), size - indexPic);
            indexPic += len;
        }
		
		// get object array
		while (indexObjects < sizeObjects)
		{
			int len = RS232_PollComport(COM_PORT, &(objectBuffer[indexObjects]), sizeObjects - indexObjects);
			indexObjects += len;
		}
		for(int i = 0; i < sizeObjects; i++)
		{
			if(i % 4 == 0 && i != 0)
			{
				printf("\n");
			}
			printf("%x ", objectBuffer[i]);
		}

        for (int idx = 0; idx < size; idx++)
        {
            uint8_t data = currentImage[idx];

            for (int i = 0; i < 8; i++)
            {
               M.data[idx*8 + i] = ((data >> i) & 0b1)*255;
            }
        }

		int32_t numObjects = unpackCenters(objArray, objectBuffer, sizeObjects);
		/*for(int i = 0; i < 40; i++)
		{
			printf("%i ", objectBuffer[i]);
			if(i % 10 == 0 && i != 0)
			{
				printf("\n");
			}
		} 
		printf("\n");
        printCenters(objArray, numObjects);*/
		cvtColor(M, M_color, cv::COLOR_GRAY2BGR);
		makeLine(&M_color, 160, GREEN, 1);

		// show data
		for(int i = 0; i < numObjects; i++)
		{
			makeCrosshairs(&M_color, objArray[i].centX, objArray[i].centY, RED);
		}
		imshow("a", M_color);
        waitKey(250);

		// only do anything here if we're given a folder name to store files
		if(argc == 2)
		{
			std::ostringstream fileName;
			fileName << folderName << "/" << currentImageNumber << ".png";
			imwrite(fileName.str(), M_color);
			printf("Stored in %s\n", fileName.str().c_str());
			currentImageNumber++;
		}
		else // not saving frames
		{
        	printf("Frame recieved!\n");
		}
       
 
		indexPic = 0;
		indexObjects = 0;
	    for(int i = 0; i < sizeObjects; i++)
    	{
        	objectBuffer[i] = 0;
		}	

	}

    RS232_CloseComport(COM_PORT);
    std::cout << "Done!" << std::endl;

    return 0;
}
