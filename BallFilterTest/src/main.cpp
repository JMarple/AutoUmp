extern "C"
{
	#include <dirent.h>
	#include "algs.h"
}
#include<iostream>
#include<stdio.h>
#include<stdint.h>
#include<opencv2/opencv.hpp>
#include<string>
#include<sstream>
#include<algorithm>

using namespace cv;

#define RED 0 
#define GREEN 1
#define BLUE 2
#define IMG_WIDTH 320
#define IMG_HEIGHT 240

struct DenoiseRowLU2
{
    uint8_t top[16];
};

struct DenoiseRowLU
{
    struct DenoiseRowLU2 bot[16];
};

struct DenoiseLookup
{
    struct DenoiseRowLU cur[64];
};

int32_t getNumFilesWithExtension(const char* folderPath, const char* fileExt);
void DenoiseInitLookup(struct DenoiseLookup* lu);
void denoise(uint8_t* img, struct DenoiseLookup* lu);


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
	if(argc != 3)
	{
		std::cout << "Three and only three arguments needed, please." << std::endl;
		std::cout << "./bftest <absolute file path to 'images' folder> <specific test case folder name>" << std::endl;
		return -1;
	}
 
	std::ostringstream folderPathOss;
	folderPathOss << argv[1] << "/" << argv[2] << "/";
	std::string folderPath = folderPathOss.str();
	

	int32_t numPng = getNumFilesWithExtension(folderPath.c_str(), ".png");

	for(int32_t i = 0; i < numPng; i++)
	{
		//construct file paths for images
		std::ostringstream imgReadFp; 
		std::ostringstream imgWriteFp;
		imgReadFp << folderPath << i << ".png";
		imgWriteFp << folderPath << "computed/" << i << ".png";

		// read image
		Mat readImage;
		readImage = imread(imgReadFp.str().c_str(), IMREAD_GRAYSCALE);
		uint8_t* byteImg = readImage.data;

		for(int i = 0; i < IMG_HEIGHT*IMG_WIDTH; i++)
		{
			byteImg[i] = byteImg[i]/255; // convert to 0s and 1s;
		}

		// convert to bit image
		int32_t bitImgSize = IMG_HEIGHT*IMG_WIDTH/8;
		uint8_t bitImg[bitImgSize];
		
		for(int i = 0; i < bitImgSize; i++)
		{
			bitImg[i] = 0; // clear
		}
	
		for(int i = 0; i < bitImgSize; i++)
		{
			for(int j = 0; j < 8; j++)
			{
				// first pixel is in MSB. I think this is the same as XMOS.
				bitImg[i] |= (byteImg[i*8 + j] & 0b1) << (7-j); 
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
		for(int i = 0; i < IMG_HEIGHT*IMG_WIDTH; i++)
		{
			newByteImg[i] = 0; // clear
		}

		for(int i = 0; i < bitImgSize; i++)
		{
			uint8_t data = bitImg[i];
			for(int j = 0; j < 8; j++)
			{
				newByteImg[i*8+ j] = ((data >> j) & 0b1)*255;
			}
		}

		// floodfill (on bit image)
		int32_t numObjects = scanPic(objArray, queue, newBitBuffer);
		if(numObjects == -1) // we hit more objects than we had space for and ended floodfill early
		{
			// TODO: handle exception
			numObjects = OBJECT_ARRAY_LENGTH;
		}
		// trajectories

		// draw boxes on image from floodfill
		Mat newImg(IMG_HEIGHT, IMG_WIDTH,  CV_8UC1, newByteImg);

		imwrite(imgWriteFp.str().c_str(), newImg);	
		
		// draw arrows on image from trajectories
	}
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



