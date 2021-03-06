// #include "object_tracker.h"
// #include <math.h>
// #include <string.h>
// #include <stdio.h>
// #include <limits.h>

// void AlphaBetaFilterInit(struct AlphaBetaFilter* filter,
//     float x_pos, float y_pos)
// {
//     filter->alpha = 0.95;
//     filter->beta = 0.3;
//     filter->x_pos = x_pos;
//     filter->y_pos = y_pos;
//     filter->x_vel = 0;
//     filter->y_vel = 0;
// }

// void AlphaBetaFilterPredict(struct AlphaBetaFilter* filter, float dT)
// {
//     filter->x_pos = filter->x_pos + filter->x_vel * dT;
//     filter->y_pos = filter->y_pos + filter->y_vel * dT;
// }

// void AlphaBetaFilterUpdate(struct AlphaBetaFilter* filter, float newX, float newY, float dT)
// {
//     float rx = newX - filter->x_pos;
//     float ry = newY - filter->y_pos;

//     filter->x_pos += filter->alpha * rx;
//     filter->x_vel += (filter->beta * rx) / dT;

//     filter->y_pos += filter->alpha * ry;
//     filter->y_vel += (filter->beta * ry) / dT;
// }

// void ObjectTrackerInit(struct ObjectTracker* tracker)
// {
//     int i;
//     for (i = 0; i < OBJECTS_NUM; i++)
//     {
//         tracker->tracks[i].inUse = 0;
//     }
// }

// // Returns -1 if track buffer is full
// int ObjectTrackerAddTrack(struct ObjectTracker* tracker, int xpos, int ypos)
// {
//     static int idCounter = 1;
//     int i;
//     for (i = 0; i < OBJECTS_NUM; i++)
//     {
//         if (tracker->tracks[i].inUse == 0)
//         {
//             // TODO: Create Unique ID generator
//             tracker->tracks[i].id = idCounter++;
//             tracker->tracks[i].deadFrames = 0;
//             tracker->tracks[i].inUse = 1;
//             tracker->tracks[i].totalFramesCount = 0;
//             AlphaBetaFilterInit(&tracker->tracks[i].filter, xpos, ypos);
//             return i;
//         }
//     }

//     return -1;
// }

// int ObjectTrackerPredictTracks(struct ObjectTracker* tracker, float dT)
// {
//     int i;
//     for (i = 0; i < OBJECTS_NUM; i++)
//     {
//         if (tracker->tracks[i].inUse == 0) continue;

//         AlphaBetaFilterPredict(&tracker->tracks[i].filter, dT);
//     }
// }

// int ObjectTrackerUpdateTrack(struct ObjectTracker* tracker, int n, int xpos, int ypos, float dT)
// {
//     if (n >= OBJECTS_NUM) return -1;
//     if (tracker == 0) return -1;
//     if (tracker->tracks[n].inUse == 0) return -1;

//     struct AlphaBetaFilter* f =
//         &tracker->tracks[n].history[tracker->tracks[n].totalFramesCount % OBJECTS_HISTORY];

//     f->x_pos = tracker->tracks[n].filter.x_pos;
//     f->y_pos = tracker->tracks[n].filter.y_pos;

//     tracker->tracks[n].deadFrames = 0;
//     tracker->tracks[n].totalFramesCount++;

//     AlphaBetaFilterUpdate(&tracker->tracks[n].filter, xpos, ypos, dT);
// }

// int ObjectTrackerDeleteTrack(struct ObjectTracker* tracker, int n)
// {
//     if (n >= OBJECTS_NUM) return -1;
//     if (tracker == 0) return -1;

//     tracker->tracks[n].inUse = 0;
//     return 0;
// }

// void ObjectArrayInit(struct ObjectArray* array)
// {
//     array->objectNum = 0;
// }

// // Return -1 if error
// int ObjectArrayAdd(struct ObjectArray* array, int topx, int topy, int botx, int boty)
// {
//     if (array->objectNum >= OBJECTS_NUM) return -1;

//     array->objects[array->objectNum].box[0] = topx;
//     array->objects[array->objectNum].box[1] = topy;
//     array->objects[array->objectNum].box[2] = botx;
//     array->objects[array->objectNum].box[3] = boty;

//     array->objects[array->objectNum].centX = (topx + botx) / 2;
//     array->objects[array->objectNum].centY = (topy + boty) / 2;

//     array->objectNum++;
// }

// void ObjectArrayPrint(struct ObjectArray* array)
// {
//     printf("Array Size = %d\n", array->objectNum);

//     int x;
//     for (x = 0; x < array->objectNum; x++)
//     {
//         struct FoundObject* obj = &array->objects[x];

//         printf(" - Box: {%d, %d}, {%d %d} -> {%d, %d}\n",
//             obj->box[0], obj->box[1], obj->box[2], obj->box[3],
//             obj->centX, obj->centY);
//     }
// }

// void ObjectTrackerPrint(struct ObjectTracker* tracker)
// {
//     printf("Cost Matrix: \n");
//     int x, y;
//     for (x = 0; x < OBJECTS_NUM+1; x++)
//     {
//         for (y = 0; y < OBJECTS_NUM+1; y++)
//         {
//             printf("%010f ", tracker->cost_matrix[x][y]);
//         }
//         printf("\n");
//     }

//     /*printf("Tracks pos\n");
//     int x;
//     for (x = 0; x < OBJECTS_NUM; x++)
//     {
//         if (tracker->tracks[x].inUse == 0) continue;

//         printf("Track %d: {%f %f} {%f %f}\n", x,
//             tracker->tracks[x].filter.x_pos,
//             tracker->tracks[x].filter.y_pos,
//             tracker->tracks[x].filter.x_vel,
//             tracker->tracks[x].filter.y_vel);
//     }*/
// }

// inline static float _computeCost(struct ObjectTrack* track, struct FoundObject* object)
// {
//     // Cost is distance between objects
//     return
//         pow(track->filter.x_pos - object->centX, 2) +
//         pow(track->filter.y_pos - object->centY, 2);
// }

// void ObjectTrackerComputeCosts(struct ObjectTracker* tracker, struct ObjectArray* objects)
// {
//     const float SLACK_VALUE = 4000.00;

//     // Computes entire NxN cost matrix for
//     int x, y;
//     for (x = 0; x < OBJECTS_NUM; x++)
//     {
//         printf("Tracks %d %d\n", x, tracker->tracks[x].inUse);
//         if (tracker->tracks[x].inUse == 0)
//         {
//             for (y = 0; y < OBJECTS_NUM; y++)
//                 tracker->cost_matrix[x][y] = INFINITY;
//         }
//         else
//         {
//             for (y = 0; y < objects->objectNum; y++)
//             {
//                 tracker->cost_matrix[x][y] =
//                     _computeCost(&tracker->tracks[x], &objects->objects[y]);

//                 if (tracker->cost_matrix[x][y] > SLACK_VALUE) tracker->cost_matrix[x][y] = INFINITY;
//             }
//             for (y = objects->objectNum; y < OBJECTS_NUM; y++)
//                 tracker->cost_matrix[x][y] = INFINITY;
//         }
//     }

//     for (x = 0; x < OBJECTS_NUM; x++)
//     {
//         tracker->cost_matrix[x][OBJECTS_NUM] = SLACK_VALUE;
//         tracker->cost_matrix[OBJECTS_NUM][x] = SLACK_VALUE;
//     }

// }

// void dfsPrintPath(uint8_t path[], int len)
// {
//     printf("Path = ");
//     int i;
//     for (i = 0; i < len; i++)
//     {
//         printf("%d ", path[i]);
//     }
//     printf("\n");
// }

// // Depth First Search of the graph.  Calculate min cost.
// // Graph is the cost matrix
// // Col is the current col in the matrix being observered
// // seen[] is the true/false flag for if each row has an observed object yet
// // Note: The bottom row can have as many objects as it wants it's used next tickets to LA, or even Canada - that would be nice  as a "slack"
// // path[] is the current path being taken.
// static void _dfs(float graph[OBJECTS_NUM+1][OBJECTS_NUM+1],
//     int col, float cost_sum, float* bestCost,
//     uint8_t seen[], uint8_t cur_path[], uint8_t best_path[])
// {
//     // Go through each row
//     int i;
//     for (i = 0; i < OBJECTS_NUM+1; i++)
//     {
//         // Check if this row has been used in previous columns.
//         if (seen[i] != 0 && i < OBJECTS_NUM) continue;

//         // If a spot on the matrix is set to INF, it can not be chosen
//         float tmpCost = graph[i][col];
//         if (tmpCost == INFINITY) continue;

//         float thisCost = cost_sum + tmpCost;
//         cur_path[col] = i;

//         // If we reach the last column, calculate costs.
//         if (col + 1 >= OBJECTS_NUM)
//         {
//             // Add costs for not having certain rows being matched.
//             int s;
//             for (s = 0; s < OBJECTS_NUM; s++)
//             {
//                 if (seen[s] == 0) thisCost += graph[s][OBJECTS_NUM];
//             }

//             printf("Cost = %f ... ", thisCost);
//             dfsPrintPath(cur_path, 10);

//             // Update best cost/path if this current path is the best path.
//             if (thisCost < *bestCost)
//             {
//                 *bestCost = thisCost;
//                 memcpy(best_path, cur_path, OBJECTS_NUM+1);
//             }
//         }
//         // Branches here if there are more columns to search.
//         else
//         {
//             seen[i] = 1;
//             _dfs(graph,
//                 col+1, thisCost, bestCost, seen, cur_path, best_path);
//             seen[i] = 0;
//         }
//     }
// }

// int ObjectTrackerAssociateData(struct ObjectTracker* tracker, struct ObjectArray* objects)
// {
//     printf("Entering Object Tracker Data\n");
//     float bestCost = INFINITY;
//     uint8_t tmpPath[OBJECTS_NUM+1];
//     uint8_t bestPath[OBJECTS_NUM+1];
//     uint8_t seen[OBJECTS_NUM+1];

//     memset(bestPath, 0, OBJECTS_NUM+1);
//     memset(seen, 0, OBJECTS_NUM+1);

//     // 60fps
//     const float dT = 0.016;
//     ObjectTrackerPredictTracks(tracker, dT);

//     printf("Start DFS\n");

//     // Search for minimal cost path.
//     _dfs(tracker->cost_matrix,
//         0, 0, &bestCost, seen, tmpPath, bestPath);

//     printf("End DFS\n");

//     if (bestCost == INFINITY)
//     {
//         printf("A solution couldn't be found, should never happen!\n");
//         return -1;
//     }

//     int i;

//     // Delete tracks
//     for (i = 0; i < OBJECTS_NUM; i++)
//     {
//         // See if the best path contains this 'i' value
//         int j, trackFound = 0;
//         for (j = 0; j < OBJECTS_NUM; j++)
//         {
//             if (bestPath[j] == i)
//             {
//                 trackFound = 1;
//                 break;
//             }
//         }

//         if (!trackFound && tracker->tracks[i].inUse == 1)
//         {
//             printf("Deleting track! %d\n", i);
//             if (tracker->tracks[i].totalFramesCount > 1 && tracker->tracks[i].deadFrames < 2)
//             {
//                 tracker->tracks[i].deadFrames++;
//             }
//             else
//             {
//                 ObjectTrackerDeleteTrack(tracker, i);
//             }
//         }
//     }

//     for (i = 0; i < objects->objectNum; i++)
//     {
//         // Add New Track
//         if (bestPath[i] == OBJECTS_NUM)
//         {
//             printf("Adding track! %d\n", i);
//             ObjectTrackerAddTrack(tracker,
//                 objects->objects[i].centX, objects->objects[i].centY);
//         }
//         // Update Track
//         else
//         {
//             printf("Updating track! %d\n", i);
//             ObjectTrackerUpdateTrack(tracker, bestPath[i],
//                 objects->objects[i].centX, objects->objects[i].centY, dT);
//         }
//     }


//     printf("Best Cost = %f\n", bestCost);
//     dfsPrintPath(bestPath, OBJECTS_NUM);
// }
