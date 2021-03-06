// #include "object_tracker.h"
// #include <stdio.h>
// #include "hungarian.h"
// int main()
// {
//     struct ObjectTracker tracker;
//     ObjectTrackerInit(&tracker);

//     // New Objects to associate with tracker.
//     struct ObjectArray objects;
//     ObjectArrayInit(&objects);
//     ObjectArrayAdd(&objects, 5, 5, 20, 20);
//     ObjectArrayAdd(&objects, 50, 53, 40, 30);
//     ObjectArrayAdd(&objects, 100, 78, 120, 108);
//     ObjectArrayAdd(&objects, 200, 78, 200, 108);
//     ObjectArrayAdd(&objects, 500, 0, 39, 0);
//     ObjectArrayPrint(&objects);

//     // Compute Cost Matrix
//     ObjectTrackerComputeCosts(&tracker, &objects);
//     ObjectTrackerPrint(&tracker);

//     // Associate Data
//     ObjectTrackerAssociateData(&tracker, &objects);

//     printf("Test object_tracker.c\n");
//     return 0;
// }
