#include "simple_object_tracker.h"
#include "main.hpp"

void filterToMiddle(struct Object* objArray, int32_t length)
{
    for(int i = 0; i < length; i++)
    {
        if(objArray[i].isBall == 0)
        {
            continue;
        }

        int32_t centX = (objArray[i].box[0] + objArray[i].box[1]) / 2;
        if(centX < IMG_WIDTH/4 || centX > 3*IMG_WIDTH/4)
        {
            objArray[i].isBall = 0;
            continue;
        }

        int32_t centY = (objArray[i].box[2] + objArray[i].box[3]) / 2;
        if(centY < IMG_HEIGHT/4 || centY > 3*IMG_HEIGHT/4)
        {
            objArray[i].isBall = 0;
            continue;
        }

    }
}
