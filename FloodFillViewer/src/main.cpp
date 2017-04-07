extern "C"
{
    #include "serial/rs232.h"
}
#include <cstdint>
#include <iostream>
#include <cstdint>
#include <algorithm>
#include <string>
#include <sys/stat.h>

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

struct Object
{
    int8_t  isBall; // -1 = not checked, 0 = no, 1 = yes
    uint16_t id; // id representing object
    uint16_t box[4]; // box[0]: minX. box[1]: maxX. box[2]: minY. box[3]: maxY
    uint16_t centX, centY;
    uint16_t distanceFromCenter;
};


// marks each object: is it a ball or not?
int32_t filterBalls(struct Object* objectArray, uint16_t length)
{
	int32_t numBalls = 0;
	for (int i = 0; i < length; i++)
	{
        if(objectArray[i].isBall == 0) continue; 
        
        // if object is smaller than possible for our ball
		if(objectArray[i].box[1] - objectArray[i].box[0] < 5 ||
			objectArray[i].box[3] - objectArray[i].box[2] < 5)
		{
			objectArray[i].isBall = 0;
		}
		
		// if the object is on the edge of the image 
		// (where edge is defined as 2 pixel width surrounding edge)
		else if(objectArray[i].box[0] < 2 || objectArray[i].box[2] < 2 || 
			objectArray[i].box[1] > IMG_WIDTH-3 || objectArray[i].box[3] > IMG_HEIGHT-3)
		{
			objectArray[i].isBall = 0;
		}

		else // it's a ball
		{
			objectArray[i].isBall = 1;
			numBalls++;
		}
		i++;
	}
	return numBalls;
}





// makes a red cross hair, with the center at the given x, y position.
void makeCrosshairs(Mat* colorImage, uint16_t x, uint16_t y, uint16_t color)
{
    if(x >= IMG_WIDTH || y >= IMG_HEIGHT)
	{
		printf("pixel given is out of bounds. You gave me: x = %i, y = %i. hex: %x, %x\n", x, y, x, y);
		return;
	}

	if(x == 0 && y == 0) // one of our dumbo empty objects
	{
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

void makeBox(
	Mat* colorImage,
	uint16_t minX,
	uint16_t maxX,
	uint16_t minY,
	uint16_t maxY, 
	uint16_t color)
{
    if(minX < 0 || minX > IMG_WIDTH-1 ||
		maxX < 0 || maxX > IMG_WIDTH-1 ||
		minY < 0 || minY > IMG_HEIGHT-1 ||
		maxY < 0 || maxY > IMG_HEIGHT-1)
	{
		printf("out of bounds. You gave me: minX %i, maxX %i, minY %i, maxY %i\n",
			minX,
			maxX,
			minY,
			maxY);
		return;
	}

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

	// the values we use to draw
	int realMinX = max(0, (int)minX);
	int realMaxX = min(IMG_WIDTH-1, (int)maxX);
	int realMinY = max(0, (int)minY);
	int realMaxY = min(IMG_HEIGHT-1, (int)maxY);

	for(int i = realMinX; i < realMaxX; i++)
	{
		colorImage->at<Vec3b>(Point(i, realMinY)) = bgr;
		colorImage->at<Vec3b>(Point(i, realMaxY)) = bgr;
	}

	for(int i = realMinY; i < realMaxY; i++)
	{
		colorImage->at<Vec3b>(Point(realMinX, i)) = bgr;
		colorImage->at<Vec3b>(Point(realMaxX, i)) = bgr;
	}
}
    
int32_t unpackObjects(
    struct Object* objArray,
    uint8_t* buffer,
    uint16_t bufferLength)
{        
    for (int q = 0; q < 36; q++)
        printf("%x ", buffer[q]);

    printf("\n");


    #define NB 9 // num objects per byte
    for(int i = 0; i < bufferLength; i+=NB) 
    {
		uint8_t xMinLower  = buffer[i];
		uint8_t xMinUpper  = buffer[i+1];
		uint8_t xMaxLower  = buffer[i+2];
		uint8_t xMaxUpper  = buffer[i+3];
		uint8_t yMinLower  = buffer[i+4];
		uint8_t yMinUpper  = buffer[i+5];
		uint8_t yMaxLower  = buffer[i+6];
		uint8_t yMaxUpper  = buffer[i+7];

		uint16_t xMin = (xMinUpper << 8) | xMinLower;
		uint16_t xMax = (xMaxUpper << 8) | xMaxLower;
		uint16_t yMin = (yMinUpper << 8) | yMinLower;
		uint16_t yMax = (yMaxUpper << 8) | yMaxLower;
		uint8_t  markVal = buffer[i+8];
        if(xMin == 0xFFFF) // that's our cue -- we've hit our last object
		{
			return i/NB+1; // num objects
			break;
		}

		objArray[i/NB].box[0] = xMin;
		objArray[i/NB].box[1] = xMax;
		objArray[i/NB].box[2] = yMin;
		objArray[i/NB].box[3] = yMax;	
	    objArray[i/NB].isBall = markVal;
	}
	return bufferLength/NB; // num objects
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
        objArray[i].box[0] = 0;
        objArray[i].box[1] = 0;
        objArray[i].box[2] = 0;
        objArray[i].box[3] = 0;
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


void printObjectArray(struct Object* objArray, uint16_t length)
{
    for(int i = 0; i < length; i++)
    {
        printf("minX: %i; maxX: %i; minY: %i; maxY: %i; centX: %i; centY: %i \n",
            objArray[i].box[0],
            objArray[i].box[1],
            objArray[i].box[2],
            objArray[i].box[3],
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

	RS232_flushRX(COM_PORT); // trying to avoid corrupted data that comes when we Ctrl+C on a previous application...?
	
	// these are only used if we are given a foldername to store files
	std::string folderName;
	int32_t currentImageNumber = 0;
	if(argc == 2)
	{
		folderName = std::string(argv[1]);
    	struct stat sb;

    	if (!(stat(folderName.c_str(), &sb) == 0 && S_ISDIR(sb.st_mode)))
    	{
        	printf("not a valid folder\n");
			return -1;
    	}
	}

	// general init
    Mat M(240, 320, CV_8UC1, Scalar(0, 0, 0));
	Mat M_color;
	int32_t indexObjects = 0;
	const int32_t sizeObjects = 250*12; // 250 objects * 12 bytes to represent the center
	uint8_t objectBuffer[sizeObjects];

	for(int i = 0; i < sizeObjects; i++)
	{
		objectBuffer[i] = 0;
	}
	struct Object objArray[250];
	initObjectArray(objArray, 250);

    while (1==1)
    {
 		for(int i = 0; i < sizeObjects; i++)
		{
			objectBuffer[i] = 0;
		}
		struct Object objArray[250];
		initObjectArray(objArray, 250);

        while (true)
        {
            unsigned char tst;
   			int len = RS232_PollComport(COM_PORT, &tst, 1);
            if (tst == 0xFA) break;
        }

		// get object array
		while (indexObjects < sizeObjects)
		{
			int len = RS232_PollComport(COM_PORT, &(objectBuffer[indexObjects]), sizeObjects - indexObjects);
			indexObjects += len;
		}
		
        int32_t numObjects = unpackObjects(objArray, objectBuffer, sizeObjects);
		int32_t numBalls = filterBalls(objArray, numObjects);

/** uncomment this to print out data that's unpacked
        printCenters(objArray, numObjects);*/
		//printObjectArray(objArray, numObjects);


		cvtColor(M, M_color, cv::COLOR_GRAY2BGR);
		//makeLine(&M_color, 160, GREEN, 1);


		// show data
		for(int i = 0; i < numObjects; i++)
		{
			if (objArray[i].isBall == 1)
			{
				makeBox(
					&M_color,
					objArray[i].box[0], 
					objArray[i].box[1],  
					objArray[i].box[2],
					objArray[i].box[3],
					RED);
			}
			else if(objArray[i].isBall != 0)
			{
				makeBox(
					&M_color,
					objArray[i].box[0],
					objArray[i].box[1],
					objArray[i].box[2],
					objArray[i].box[3],
					GREEN);
			}
		}

//		imshow("a", M);
		imshow("a", M_color);
        waitKey(10);

		// only do anything here if we're given a folder name to store files
		if(argc == 2)
		{
			std::ostringstream fileName;
			fileName << folderName << "/" << currentImageNumber << ".png";
			//imwrite(fileName.str(), M_color);
			imwrite(fileName.str(), M);
			printf("Stored in %s\n", fileName.str().c_str());
			currentImageNumber++;
		}
		else // not saving frames
		{
        	printf("Frame recieved!\n");
		}
       
 
/* IF NO OBJECTS, COMMENT THIS SETION OUT */
		indexObjects = 0;
	    for(int i = 0; i < sizeObjects; i++)
    	{
        	objectBuffer[i] = 0;
		}	
/**/
	}

    RS232_CloseComport(COM_PORT);
    std::cout << "Done!" << std::endl;

    return 0;
}
