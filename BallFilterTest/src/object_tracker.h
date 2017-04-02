#ifndef __OBJECT_TRACKER_H__
#define __OBJECT_TRACKER_H__

#include <stdint.h>

#define OBJECTS_NUM 100
#define OBJECTS_MAX_TRACK_LEN 20

struct ObjectTrack
{
    // Unique ID assigned to this track
    uint32_t id;

    // If track is currently used, inUse = 1, otherwise 0
    uint8_t inUse;

    // Frames in use.
    uint32_t totalFramesCount;

    // Alpha-beta filter constants
    float alpha, beta;

    // Alpha-beta states
    float x_pos, y_pos, x_vel, y_vel;
};

struct ObjectTracker
{
    struct ObjectTrack tracks[OBJECTS_NUM];
    float cost_matrix[OBJECTS_NUM + 1][OBJECTS_NUM + 1];
};


#endif
