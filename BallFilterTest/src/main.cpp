extern "C"
{
	#include <dirent.h>
	#include "algs.h"
	#include "detect_objects.h"
    #include "object_tracker.h"
	#include "queue.h"
}
#include <iostream>
#include <stdio.h>
#include <stdint.h>
#include <opencv2/opencv.hpp>
#include <string>
#include <sstream>
#include <algorithm>
#include <termios.h>
#include <unistd.h>
#include "main.hpp"

using namespace cv;

#define RED 0 
#define GREEN 1
#define BLUE 2
#define YELLOW 3

int32_t getNumFilesWithExtension(
	const char* folderPath, 
	const char* fileExt);

int mygetch(void);

void DenoiseInitLookup(
	struct DenoiseLookup* lu);

void denoise(
	uint8_t* img, 
	struct DenoiseLookup* lu);

void makeLine(
	Mat* colorImage, 
	uint16_t rowOrColumn, 
	uint16_t color, 
	uint16_t isVertical);

void makeBox(
    Mat* colorImage,
    int32_t minX,
    int32_t maxX,
    int32_t minY,
    int32_t maxY, 
    int32_t color);

int _clip(int val, int max)
{
    if (val > max) return max;
    if (val < 0) return 0;
    return val;
}

/* 
Takes in a folder, reads through background subtracted images.
Converted to bit images, then denoised/floodfilled.
Using waitkey, it'd be helpful to be able to step through frames.
Draw boxes on a new, resulting image (after floodfill)
Provide a function to also draw lines for tracking
*/
int main(int argc, char** argv)
{
	// args: ./bftest <absolute file path to "images" folder> <specific test case folder name> 
	// we're assuming <SOME_PATH>/images/01, <SOME_PATH>/images/02, etc.
	if(argc != 4)
	{
		std::cout << "Four arguments needed, please." << std::endl;
		std::cout << "./bftest <absolute file path to 'images' folder> <specific test case folder name> <'f', if you want to step through frame by frame'" << std::endl;
		return -1;
	}
 
	std::ostringstream folderPathOss;
	folderPathOss << argv[1] << "/" << argv[2] << "/";
	std::string folderPath = folderPathOss.str();
	

	int32_t numPng = getNumFilesWithExtension(folderPath.c_str(), ".png");

	int32_t maxNumObjects = 0;
	int32_t maxNumMerged = 0;
	int32_t maxNumInterestingObjects = 0;
	int32_t maxNumSquarish = 0;
	int32_t maxNumFull = 0;
	int32_t maxNumFullImg = 0; // which picture did maxNumFull appear?

	struct ObjectTracker tracker;
    ObjectTrackerInit(&tracker);


	for(int32_t i = 0; i < numPng; i++)
	{
		std::cout << "---------------- File " << i << " ----------------" << std::endl;
		//construct file paths for images
		std::ostringstream imgReadFp; 
		std::ostringstream imgWriteFp;
		imgReadFp << folderPath << i << ".png";
		imgWriteFp << folderPath << "computed/" << i << ".png";

		// read image
		Mat readImage;
		readImage = imread(imgReadFp.str().c_str(), IMREAD_GRAYSCALE);
		uint8_t* byteImg = readImage.data;

		for(int j = 0; j < IMG_HEIGHT*IMG_WIDTH; j++)
		{
			byteImg[j] = byteImg[j]/255; // convert to 0s and 1s;
		}

		// convert to bit image
		int32_t bitImgSize = IMG_HEIGHT*IMG_WIDTH/8;
		uint8_t bitImg[bitImgSize];
		
		for(int j = 0; j < bitImgSize; j++)
		{
			bitImg[j] = 0; // clear
		}
	
		for(int j = 0; j < bitImgSize; j++)
		{
			for(int k = 0; k < 8; k++)
			{
				// this assumes that first pixel is stored in LSB.
				bitImg[j] |= (byteImg[j*8 + k] & 0b1) << k;
			}
		}

		// denoise
    	struct DenoiseLookup* lu = (struct DenoiseLookup*) malloc(sizeof(struct DenoiseLookup));
    	if (lu == 0) printf("Lookup table out of memory!");
    	DenoiseInitLookup(lu);
		denoise(bitImg, lu);
		free(lu);

		// convert back to byte image here so we can draw later
		uint8_t newByteImg[IMG_HEIGHT*IMG_WIDTH];
		for(int j = 0; j < IMG_HEIGHT*IMG_WIDTH; j++)
		{
			newByteImg[j] = 0; // clear
		}

		for(int j = 0; j < bitImgSize; j++)
		{
			uint8_t data = bitImg[j];
			for(int k = 0; k < 8; k++)
			{
				// assumes first pixel (pixel 0)  is in LSB
				newByteImg[j*8 + k] = ((data >> k) & 0b1)*255;
			}
		}

		// floodfill (on bit image)
		struct Object objArray[OBJECT_ARRAY_LENGTH];
		initObjectArray(objArray, OBJECT_ARRAY_LENGTH);
		
		struct Queue queue;
		queueInit(&queue);

		int32_t numObjects = scanPic(objArray, &queue, bitImg);
		if(numObjects == -1) // we hit more objects than we had space for and ended floodfill early
		{
			// TODO: handle exception
			numObjects = OBJECT_ARRAY_LENGTH;
		}

		if(numObjects > maxNumObjects)
		{
			 maxNumObjects = numObjects;
		}

		int32_t numMerged = mergeObjects(objArray, numObjects);
		if(numMerged > maxNumMerged)
		{
			maxNumMerged = numMerged;
		}

		int32_t numInterestingObjects = filterLarge(objArray, numObjects);
		if(numInterestingObjects > maxNumInterestingObjects)
		{
			maxNumInterestingObjects = numInterestingObjects;
		}



/*
		int32_t numSquarish = filterSquare(objArray, numObjects);
		if(numSquarish > maxNumSquarish)
		{
			maxNumSquarish = numSquarish;
		}
*/

/*		int32_t numFull = filterFull(objArray, numObjects);
		if(numFull > maxNumFull) 
		{
			maxNumFull = numFull;
			maxNumFullImg = i;	
		}
*/



		// draw boxes on image from floodfill
		Mat newImg(IMG_HEIGHT, IMG_WIDTH,  CV_8UC1, newByteImg);
		Mat newColorImg;
		cvtColor(newImg, newColorImg, cv::COLOR_GRAY2BGR);

		/*for(int j = 0; j < numObjects; j++)
		{
			if (objArray[j].isBall == 1)
			{
				makeBox(
					&newColorImg,
					objArray[j].box[0]-1 , // + 8? 
					objArray[j].box[1]+1, // + 8? 
					objArray[j].box[2]-1,
					objArray[j].box[3]+1,
					RED);
			}
			else if(objArray[j].isBall == 2)
			{
				makeBox(
					&newColorImg,
					objArray[j].box[0]-1, // + 8?
					objArray[j].box[1]+1, // + 8?
					objArray[j].box[2]-1,
					objArray[j].box[3]+1,
					BLUE);
			}
			else if(objArray[j].isBall == 3)
			{
				makeBox(
					&newColorImg,
					objArray[j].box[0]-1, // + 8?
					objArray[j].box[1]+1, // + 8?
					objArray[j].box[2]-1,
					objArray[j].box[3]+1,
					YELLOW);	
			}
		}*/

	    // Convert array into something the tracker can use
        struct ObjectArray objects;
        ObjectArrayInit(&objects);
        for (int i = 0; i < numObjects; i++)
        {
            if (objArray[i].isBall == 0) continue;
            printf("objArray.isball = %d\n", objArray[i].isBall);

            ObjectArrayAdd(&objects,
                objArray[i].box[0],
                objArray[i].box[2],
                objArray[i].box[1],
                objArray[i].box[3]);
        }
        ObjectArrayPrint(&objects);

        // trajectories
        // Compute cost matrix
        ObjectTrackerComputeCosts(&tracker, &objects);
        ObjectTrackerPrint(&tracker);

        // Associate Data
        ObjectTrackerAssociateData(&tracker, &objects);

        int q;
	    for (int q = 0; q < OBJECTS_NUM; q++)
	    {
	        if (tracker.tracks[q].inUse == 0) continue;

	        const int BOX_PADDING = 10;
	        const int LITTLE_BOX_PADDING = 3;
	        makeBox(
                &newColorImg,
                _clip(tracker.tracks[q].filter.x_pos - BOX_PADDING, 319),
                _clip(tracker.tracks[q].filter.x_pos + BOX_PADDING, 319),
                _clip(tracker.tracks[q].filter.y_pos - BOX_PADDING, 239),
                _clip(tracker.tracks[q].filter.y_pos + BOX_PADDING, 239),
                tracker.tracks[q].id % 6);

	        for (int w = 0; w < tracker.tracks[q].totalFramesCount; w++)
	        {
                makeBox(
                    &newColorImg,
                    _clip(tracker.tracks[q].history[w].x_pos - LITTLE_BOX_PADDING, 319),
                    _clip(tracker.tracks[q].history[w].x_pos + LITTLE_BOX_PADDING, 319),
                    _clip(tracker.tracks[q].history[w].y_pos - LITTLE_BOX_PADDING, 239),
                    _clip(tracker.tracks[q].history[w].y_pos + LITTLE_BOX_PADDING, 239),
                    tracker.tracks[q].id % 6);
	        }
	    }

		/*for(int j = 0; j < numObjects; j++)
		{
			if(objArray[j].isBall != -2)
			{
				std::cout << "Object " << j << ", (x1, y1) = (" 
					<< objArray[j].box[0] << ", " << objArray[j].box[2] << "). (x2, y2) = ("
					<< objArray[j].box[1] << ", " << objArray[j].box[3] << ")." << std::endl;
			}
		}*/


		// step through frame by frame, if user asked for it
		if(argv[3][0] == 'f')
		{
			imshow("a", newColorImg);
			waitKey(10);
			mygetch();
			//getchar();
		}

		imwrite(imgWriteFp.str().c_str(), newColorImg);	
	}
	
//	std::cout << "All Objects:         " << maxNumObjects << std::endl;
	std::cout << "Interesting Objects: " << maxNumInterestingObjects << std::endl;
	//std::cout << "Num Squarish:        " << maxNumSquarish << std::endl;
	std::cout << "Num Full             " << maxNumFull << "  (img " << maxNumFullImg << " )" << std::endl;
}

void denoise(uint8_t* img, struct DenoiseLookup* lu){
 for (int i = 2; i < IMG_HEIGHT; i++)
    {
        DenoiseRow(
            (uint32_t*)&img[(i-2)*IMG_WIDTH/8],
            (uint32_t*)&img[(i-1)*IMG_WIDTH/8],
            (uint32_t*)&img[i*IMG_WIDTH/8],
            lu);
    }

    // finish up the denoise: make the top and bottom rows 0.
    for (int i = 0; i < IMG_WIDTH/8; i++)
    {
        img[i] = 0;
        img[(IMG_HEIGHT-1)*IMG_WIDTH/8 + i] = 0;
    }

    // Make the left and right columns 0
    for (int i = 0; i < IMG_HEIGHT; i++)
    {
        img[i * IMG_WIDTH/8] = 0;
        img[(i+1)*IMG_WIDTH/8-1] = 0;
    }
}


static void _DenoiseInitElement(uint8_t* output, uint8_t cur, uint8_t bot, uint8_t top)
{
    uint8_t result = 0;

    for (int i = 0; i < 4; i++)
    {
        int count = 0;
        int curBit = (cur & 0b000010) > 0;

        count += (cur & 0b000001);
        count += (cur & 0b000100) > 0;
        count += (top & 0b0001);
        count += (bot & 0b0001);

        //printf("count=%d ", count);
        if (count >= 2) result |= ((1*curBit) << i);

        top >>= 1;
        bot >>= 1;
        cur >>= 1;
    }

    //printf("%x %x %x, %x\n", cur, bot, top, result);
    *output = result;
}

void DenoiseInitLookup(struct DenoiseLookup* lu)
{
    for (int cur = 0; cur < 64; cur++)
    {
        for (int bot = 0; bot < 16; bot++)
        {
            for (int top = 0; top < 16; top++)
            {
                _DenoiseInitElement(
                    &lu->cur[cur].bot[bot].top[top],
                    cur, bot, top);
            }
        }
    }

    // Example
    //printf("Example = %d\n", lu->cur[0].bot[0].top[0]);
}

// example folderPath: "/tmp". example fileExt: ".png"
int32_t getNumFilesWithExtension(const char* folderPath, const char* fileExt)
{
    int32_t len;
    int32_t numFiles = 0;
    struct dirent *pDirent;
    DIR *pDir;

    pDir = opendir(folderPath);
    if (pDir != NULL) {
        while ((pDirent = readdir(pDir)) != NULL) {
            len = strlen (pDirent->d_name);
            if (len >= 4) {
                if (strcmp (fileExt, &(pDirent->d_name[len - 4])) == 0) {
                    numFiles++;
                }   
            }   
        }   
        closedir (pDir);
    }   

    return numFiles;
}


int mygetch ( void ) 
{
  int ch;
  struct termios oldt, newt;

  tcgetattr ( STDIN_FILENO, &oldt );
  newt = oldt;
  newt.c_lflag &= ~( ICANON | ECHO );
  tcsetattr ( STDIN_FILENO, TCSANOW, &newt );
  ch = getchar();
  tcsetattr ( STDIN_FILENO, TCSANOW, &oldt );

  return ch;
}


// makes a horitzontal or vertical line
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
        bgr.val[0] = 0xFF; // blue
        bgr.val[1] = 0xF2; // green
        bgr.val[2] = 0x00; // red     
    }  

    else if(color == YELLOW)
    {
        bgr.val[0] = 0x00;
        bgr.val[1] = 0xD8;
        bgr.val[2] = 0xFF; 
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
    int32_t minX,
    int32_t maxX,
    int32_t minY,
    int32_t maxY, 
    int32_t color)
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
        bgr.val[0] = 0xFF; // blue
        bgr.val[1] = 0xF2; // green
        bgr.val[2] = 0x00; // red     
    }

	else if(color == YELLOW)
	{
		bgr.val[0] = 0x00;
		bgr.val[1] = 0xD8;
		bgr.val[2] = 0xFF;
	}
	else if (color == 4)
	{
	    bgr.val[0] = 0xFF;
	    bgr.val[1] = 0x00;
	    bgr.val[2] = 0xFF;
	}
    else if (color == 5)
	{
	    bgr.val[0] = 0xCC;
	    bgr.val[1] = 0xCC;
	    bgr.val[2] = 0xCC;
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

