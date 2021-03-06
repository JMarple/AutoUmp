// #ifndef __OBJECT_TRACKER_H__
// #define __OBJECT_TRACKER_H__

// #include <stdint.h>

// #define OBJECTS_NUM 10
// #define OBJECTS_HISTORY 10
// #define OBJECTS_MAX_TRACK_LEN 20

// struct AlphaBetaFilter
// {
//     // Alpha-beta filter constants
//     float alpha, beta;

//     // Alpha-beta states
//     float x_pos, y_pos, x_vel, y_vel;
// };

// struct ObjectTrack
// {
//     // Unique ID assigned to this track
//     uint32_t id;

//     // If track is currently used, inUse = 1, otherwise 0
//     uint8_t inUse;

//     // Frames in use.
//     uint32_t totalFramesCount;

//     uint32_t deadFrames;

//     struct AlphaBetaFilter history[OBJECTS_HISTORY];
//     struct AlphaBetaFilter filter;
// };

// struct ObjectTracker
// {
//     struct ObjectTrack tracks[OBJECTS_NUM];
//     float cost_matrix[OBJECTS_NUM+1][OBJECTS_NUM+1];
// };

// struct FoundObject
// {
//     uint32_t box[4];
//     uint16_t centX, centY;
// };

// struct ObjectArray
// {
//     uint32_t objectNum;
//     struct FoundObject objects[OBJECTS_NUM];
// };

// void ObjectTrackerInit(struct ObjectTracker* tracker);
// void ObjectArrayInit(struct ObjectArray* array);
// int ObjectArrayAdd(struct ObjectArray* array, int topx, int topy, int botx, int boty);
// void ObjectTrackerComputeCosts(struct ObjectTracker* tracker, struct ObjectArray* objects);
// int ObjectTrackerAssociateData(struct ObjectTracker* tracker, struct ObjectArray* objects);
// void ObjectArrayPrint(struct ObjectArray* array);
// void ObjectTrackerPrint(struct ObjectTracker* tracker);
// int ObjectTrackerAddTrack(struct ObjectTracker* tracker, int xpos, int ypos);
// int ObjectTrackerUpdateTrack(struct ObjectTracker* tracker, int n, int xpos, int ypos, float dT);
// int ObjectTrackerDeleteTrack(struct ObjectTracker* tracker, int n);
// #endif
