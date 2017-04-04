#include "object_tracker.h"
#include "detect_objects.h"
#include <math.h>

void ObjectTrackerInit(struct ObjectTracker* tracker)
{
    int i;
    for (i = 0; i < OBJECTS_NUM; i++)
    {
        tracker->tracks[i].inUse = 0;
    }
}

inline static float _computeCost(struct ObjectTrack* track, struct Object* object)
{
    // Cost is distance between objects
    return sqrt(
        pow(track->x_pos - object->centX, 2) +
        pow(track->y_pos - object->centY, 2));
}

void ObjectTrackerComputeCosts(struct ObjectTracker* tracker, struct Object* objects)
{
    // Computes entire NxN cost matrix for
    int x, y;
    for (x = 0; x < OBJECTS_NUM; x++)
    {
        for (y = 0; y < OBJECTS_NUM; y++)
        {
            tracker->cost_matrix[x][y] =
                _computeCost(&tracker->tracks[x], &objects[y]);
        }
    }

    const int NEW_TRACK_COST = 1.0;

    for (x = 0; x < OBJECTS_NUM; x++)
    {
        tracker->cost_matrix[OBJECTS_NUM+1][x] = NEW_TRACK_COST;
        tracker->cost_matrix[y][OBJECTS_NUM+1] = NEW_TRACK_COST;
    }
}

void ObjectTrackerAssociateData(struct ObjectTracker* tracker, struct Object* objects)
{

}
