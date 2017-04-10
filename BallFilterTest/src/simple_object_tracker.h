#ifndef _SIMPLE_OBJECT_TRACKER_H_
#define _SIMPLE_OBJECT_TRACKER_H_

#include <stdint.h>
#include "detect_objects.h"

#define OBJECTS_NUM 10
#define OBJECTS_HISTORY 10
#define OBJECTS_MAX_TRACK_LEN 20

struct FoundObject
{
    uint32_t box[4];
    uint16_t centX, centY;
};

struct ObjectArray
{
    uint32_t objectNum;
    struct FoundObject objects[OBJECTS_NUM];
};

struct ObjectTrack
{
    // Unique ID assigned to this track
    uint32_t id;

    // If track is currently used, inUse = 1, otherwise 0
    uint8_t inUse;

    // Frames in use.
    uint32_t totalFramesCount;

    uint32_t head; // place to insert next frame in history: circular buffer
	int32_t lastFrame; 

    uint32_t deadFrames;


    // TODO: ALPHA/BETA FILTER
    struct FoundObject history[OBJECTS_HISTORY];
};

void ObjectArrayInit(struct ObjectArray* array);
int ObjectArrayAdd(struct ObjectArray* array, int topx, int topy, int botx, int boty);
void ObjectTrackInit(struct ObjectTrack* track, uint32_t id);
int filterToMiddle(struct Object* objArray, struct ObjectArray* newObjArray, int32_t length);
int updateTrack(struct ObjectTrack* track, struct ObjectArray* objectArray, uint32_t trackID);
int32_t isValid(struct FoundObject* obj1, struct FoundObject* obj2);
int32_t addToHistory(struct ObjectTrack* track, struct FoundObject* obj);

#endif
