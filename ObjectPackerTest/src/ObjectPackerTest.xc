#include <xs1.h>
#include <platform.h>
#include <stdio.h>
#include <stdint.h>

struct Object
{
    uint8_t  isBall; // -1 = not checked, 0 = no, 1 = yes
    uint16_t id; // id representing object
    uint16_t minX, maxX, minY, maxY; // lower/uppper bounds of object
    uint16_t centX, centY;
    uint16_t distanceFromCenter;
};

void initObjectArray(struct Object* objArray, uint16_t length)
{
    for (int i = 0; i < length; i ++)
    {
        objArray[i].id = 0;
        objArray[i].minX = 0;
        objArray[i].maxX = 0;
        objArray[i].minY = 0;
        objArray[i].maxY = 0;
    }
}

void printObjectArray(struct Object* objArray, uint16_t length)
{
    uint16_t i = 0;
    while(i < length)
    {
        printf("id: %i; minX: %i; maxX: %i; minY: %i; maxY: %i; centX: %i; centY: %i \n",
            objArray[i].id,
            objArray[i].minX,
            objArray[i].maxX,
            objArray[i].minY,
            objArray[i].maxY,
            objArray[i].centX,
            objArray[i].centY);
        i++;
    }
    printf("\n");
}


// pack the center data to be used for sending over uart
void packCenters(
    struct Object* objArray,
    uint8_t* buffer,
    uint16_t numObjects)
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
    if(numObjects < 250) // send a code: we're done with our objects
    {
        for(int i = 0; i < 4; i++)
        {
            buffer[numObjects*4 + i] = 0xFF;
        }
    }
}

void unpackCenters(
    struct Object* objArray,
    uint8_t* buffer,
    uint16_t bufferLength)
{
    for(int i = 0; i < bufferLength; i+=4)
    {
        printf("%i ", i);
        uint8_t xLower = buffer[i];
        uint8_t xUpper = buffer[i+1];
        uint8_t yLower = buffer[i+2];
        uint8_t yUpper = buffer[i+3];

        objArray[i/4].centX = (xUpper << 8) | xLower;
        objArray[i/4].centY = (yUpper << 8) | yLower;
    }
}

int main()
{ unsafe {

    struct Object objArrayBefore[20];
    struct Object objArrayAfter[21];
    initObjectArray(objArrayBefore, 20);
    initObjectArray(objArrayAfter, 21);
    uint8_t buffer[84];

    for(int i = 0; i < 84; i++)
    {
        buffer[i] = 0;
    }

    for(int i = 0; i < 20; i++)
    {
        objArrayBefore[i].centX = 4*i;
        objArrayBefore[i].centY = 12*i;
    }
    printf("Object Array 1:\n");
    printObjectArray(objArrayBefore, 20);

    packCenters(objArrayBefore, buffer, 20);
    unpackCenters(objArrayAfter, buffer, 84);

    printf("--------------\nObject Array 2\n");
    printObjectArray(objArrayAfter, 21);

    return 0;
}}
