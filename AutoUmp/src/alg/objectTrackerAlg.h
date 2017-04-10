#ifndef _OBJECT_TRACKER_ALG_H
#define _OBJECT_TRACKER_ALG_H

#include "interfaces.h"
#include "detect_objects.h"

#define OBJECTS_NUM 10
#define OBJECTS_HISTORY 10
#define OBJECTS_MAX_TRACK_LEN 20
#define FRAME_SKIP 20


#define round(x) ((x)>=0?(uint16_t)((x)+0.5):(uint16_t)((x)-0.5))

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

void ObjectTracker(
    interface ObjectTrackerToGameInter client ot2g,
    interface FloodFillToObjectInter server tile0FF2OT[4],
    interface FloodFillToObjectInter server tile1FF2OT[4]);

void ObjectArrayInit(struct ObjectArray* unsafe array);
int ObjectArrayAdd(struct ObjectArray* unsafe array, int32_t topx, int32_t topy, int32_t botx, int32_t boty);
void ObjectTrackInit(struct ObjectTrack* unsafe track, uint32_t id);
int filterToMiddle(struct Object* unsafe objArray, struct ObjectArray* unsafe newObjArray, int32_t length);
int updateTrack(struct ObjectTrack* unsafe track, struct ObjectArray* unsafe objectArray, uint32_t trackID);
int32_t isValid(struct FoundObject* unsafe obj1, struct FoundObject* unsafe obj2);
int32_t addToHistory(struct ObjectTrack* unsafe track, struct FoundObject* unsafe obj);
float calculateIntersection(struct ObjectTrack* unsafe track);


#endif
