#include "simple_object_tracker.h"
#include "detect_objects.h"
#include "main.hpp"
#include <stdint.h>
#include <stdio.h>

void ObjectArrayInit(struct ObjectArray* array)
{
    array->objectNum = 0;
}

void ObjectTrackInit(struct ObjectTrack* track, uint32_t id)
{
    track->id = id;
    track->totalFramesCount = 0;
    track->head = 0;
    track->deadFrames = 0;
	track->lastFrame = -1;
}


// Return -1 if error
int ObjectArrayAdd(struct ObjectArray* array, int topLx, int topLy, int botRx, int botRy)
{
    if (array->objectNum >= OBJECTS_NUM) return -1;

    array->objects[array->objectNum].box[0] = topLx;
    array->objects[array->objectNum].box[1] = topLy;
    array->objects[array->objectNum].box[2] = botRx;
    array->objects[array->objectNum].box[3] = botRy;

    array->objects[array->objectNum].centX = (topLx + botRx) / 2;
    array->objects[array->objectNum].centY = (topLy + botRy) / 2;

    array->objectNum++;

    return 0;
}

// filter out any object that's not in the middle of the image
// (i.e., a quarter of the image away from the center in every direction)
int filterToMiddle(struct Object* objArray, struct ObjectArray* newObjArray, int32_t length)
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
            objArray[i].isBall = 3;
            continue;
        }

        int32_t centY = (objArray[i].box[2] + objArray[i].box[3]) / 2;
        if(centY < IMG_HEIGHT/4 || centY > 3*IMG_HEIGHT/4)
        {
            objArray[i].isBall = 3;
            continue;
        }

        // if you get here, that means it's in the middle.
        // weird indexing of "box" here because we're switching
        // from minX, maxX, minY, maxY convention to topLx, topLy, botRx, botRy
        ObjectArrayAdd(newObjArray, objArray[i].box[0], objArray[i].box[2], objArray[i].box[1], objArray[i].box[3]);

    }

    return 0;
}



//select the object that best matches the current track/a ball
//int result = updateTrack(&trackLeft, &objArrayLeft);

//if result == 0, then track updated fine (either we add a new object to it or count a dead frame)
//else if result == 1, then object has been missing for 3 frames and we need to calulate intersection and reinit track


int updateTrack(struct ObjectTrack* track, struct ObjectArray* objectArray, uint32_t trackID)
{
	// check for empty array
	if(objectArray->objectNum == 0)
	{
		track->deadFrames++;
	}
	else if(objectArray->objectNum == 1)
	{
		if(track->totalFramesCount == 0)
		{
			addToHistory(track, &objectArray->objects[0]);
			//printTrack(track);
		}
		else
		{
			// check: is it a valid object?
			// valid is defined as: moved to the right, and less than 20 pixels change in y
		    if(isValid(&track->history[track->lastFrame], &objectArray->objects[0]))
			{
				// add to history
				addToHistory(track, &objectArray->objects[0]);
				//printTrack(track);
			}
			else 
			{
				track->deadFrames++;
			}
		}
	}
	else { // more than one object in objectArray
		struct FoundObject bestObject;
		struct FoundObject tmpObject;
		int32_t bestObjectIndex = -1;

		// find the best object 
		for(int i = 0; i < objectArray->objectNum; i++)
		{
			tmpObject = objectArray->objects[i];
			if(isValid(&track->history[track->lastFrame], &tmpObject))
			{
				if(bestObjectIndex == -1) 
				{
					bestObject = tmpObject;
					bestObjectIndex = i;
				}
				else
				{
					if(tmpObject.centX > bestObject.centX)
					{
						bestObject = tmpObject;
						bestObjectIndex = i;
					}
				}
			}
		}

		if(bestObjectIndex == -1) track->deadFrames++;
		else
		{
			addToHistory(track, &bestObject);
			//printTrack(track);
		}	
	}

	if(track->deadFrames > 2)
	{
		ObjectTrackInit(track, trackID);
	}

	// decide if we need to calculate the intersection
	int32_t idx = track->lastFrame - 1;
	int32_t twoFramesAgo = (idx % OBJECTS_HISTORY + OBJECTS_HISTORY) % OBJECTS_HISTORY;
	if(track->lastFrame >= 0 &&
        track->totalFramesCount >= 2 &&
        track->history[track->lastFrame].centX > IMG_WIDTH/2 &&
        track->history[twoFramesAgo].centX <= IMG_WIDTH/2 &&
        track->history[track->lastFrame].centX - track->history[twoFramesAgo].centX > 0)
	{
		return 1;
	}

	return 0;
}

// returns 1 if obj2 has moved to the right of obj1 and has less than 20 pixel change in y
// 0 otherwise
int32_t isValid(struct FoundObject* obj1, struct FoundObject* obj2)
{
	if((obj2->centX - obj1->centX > 0) &&
		((obj2->centY - obj1->centY < 20) || (obj1->centY - obj2->centY < 20)))
	{
		return 1;
	}
	else return 0;
}

int32_t addToHistory(struct ObjectTrack* track, struct FoundObject* obj)
{
	track->history[track->head] = *obj;
	if(track->totalFramesCount < OBJECTS_HISTORY) track->totalFramesCount++;
	track->head = (track->head + 1) % OBJECTS_HISTORY;
	track->lastFrame = (track->lastFrame + 1) % OBJECTS_HISTORY;
}

float calculateIntersection(struct ObjectTrack* track)
{
    int32_t lastFrameIndex = track->lastFrame;
    int32_t twoFramesAgoIndex = ((lastFrameIndex - 1) % OBJECTS_HISTORY + OBJECTS_HISTORY) % OBJECTS_HISTORY;
	struct FoundObject f0 = track->history[twoFramesAgoIndex];
	struct FoundObject f1 = track->history[lastFrameIndex];

	printf("f0.centX %i, f0.centY %i, f1.centX %i, f1.centY %i\n", f0.centX, f0.centY, f1.centX, f1.centY);

	float interX = (double)IMG_WIDTH / 2.0;
	float m = ((float)f1.centY - (float)f0.centY) / ((float)f1.centX - f0.centX);
	float interY = (float)f0.centY + m * (interX - (float)f0.centX);

	return interY;
}


void printTrack(struct ObjectTrack* track)
{
	int i = track->totalFramesCount;
	int idx = track->lastFrame;
	printf("Printing %i objects in track in reverse order. (idx = %i)\n", i, idx);
	while(i > 0)
	{
		struct FoundObject f = track->history[idx];
		printf("x: %i, y: %i\n", f.centX, f.centY);
		idx = ((idx - 1) % OBJECTS_HISTORY + OBJECTS_HISTORY) % OBJECTS_HISTORY;
		printf("(idx = %i)\n", idx);
		i--;
	}
} 
