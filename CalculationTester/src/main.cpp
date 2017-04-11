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
#include <fstream>

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

#define PI 3.14159265359

struct PointThar 
{
	float x, y;
};


float deg2rad(float deg)
{
    return deg * PI / 180.0;
}


struct PointThar kZoneLocation(float intersectionLeft, float intersectionRight)
{
    float cameraSeparationIn = 13.25; // inches, for protoype board
    float fieldOfViewDeg = 80.0; // degrees
    float resolution = 240.0; // pixels
    float camHeightM = 0.065; // mm. for protoype board, 25.0mm + 40.0mm

    float inToM = 0.0254; // inches to meters multiplication factor
    float mToIn = 1.0/inToM;

    // define camera locations in meters. Origin is in the iddle of the plate. We're assuming they're equal distances away from the center.
    struct PointThar camL, camR;
    camL.x = 0-inToM*cameraSeparationIn/2;
    camL.y = camHeightM; // (25.0 mm + )
    camR.x = camL.x + (cameraSeparationIn*inToM);
    camR.y = camHeightM;

    float offsetRadLeft  = deg2rad(((180.0 - fieldOfViewDeg) / 2.0) - 15.0);
    float offsetRadRight = deg2rad(((180.0 - fieldOfViewDeg) / 2.0) + 15.0);
    float eachpixelrad = deg2rad(fieldOfViewDeg / resolution);
    float r = 1.5;

    // find line for left camera
    float LX0 = camL.x;
    float LX1 = camL.y + r * cos((eachpixelrad * intersectionLeft) + offsetRadLeft);
    float LY0 = camL.x;
    float LY1 = camL.y + r * sin((eachpixelrad * intersectionLeft) + offsetRadLeft);

    // find line for right camera
    float RX0 = camR.x;
    float RX1 = camR.x + r * cos((eachpixelrad * intersectionRight) + offsetRadRight);
    float RY0 = camR.y;
    float RY1 = camR.x + r * sin((eachpixelrad * intersectionRight) + offsetRadRight);

    // find intersection between lines
    float leftSlope  = (LY1 - LY0) / (LX1 - LX0);
    float rightSlope = (RY1 - RY0) / (RX1 - RX0);

    struct PointThar result;
    result.x = (leftSlope * LX0 - LY0 - rightSlope * RX0 + RY0) / (leftSlope - rightSlope);
    result.y = rightSlope * (result.x - RX0) + RY0;

    // convert to inches
    result.x = result.x * mToIn;
    result.y = result.y * mToIn;

    return result;
}


int main(int argc, char** argv)
{
   	std::ofstream file;
	file.open("../intersection_possibilities.csv");
	file << "left_pix, right_pix, x_calc, y_calc\n";
	for(int i = 0; i < 240; i++)
	{
		int iLeft = i;
		for(int j = 0; j < 240; j++)
		{
			int iRight = j;
			struct PointThar p = kZoneLocation(i, j);
			file << i << "," << j << "," << p.x << "," << p.y << "\n";
		}
	} 
	file.close();
	return 0;
}
