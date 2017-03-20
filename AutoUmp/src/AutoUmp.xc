#include <xs1.h>
#include <platform.h>
#include <stdio.h>

#include "ov07740.h"
#include "io.h"
#include "algs.h"

extern in buffered port:32 cam1DATA;
extern in buffered port:32 cam2DATA;

// "UI" tile
void Tile0(chanend bluetoothChan)
{
    par
    {
        BluetoothThread(bluetoothChan);
    }
}

// "Camera" tile
void Tile1(chanend bluetoothChan)
{ unsafe {

    printf("Booting AutoUmp...\n");

    OV07740_InitCameras();
    OV07740_ConfigureCameras();

    streaming chan cmdStream1, cmdStream2;
    chan ffStream1, ffStream2;
    chan doStream1, doStream2; // detected objects

    struct Object objArray1[OBJECT_ARRAY_LENGTH];
    struct Object objArray2[OBJECT_ARRAY_LENGTH];

    initObjectArray(objArray1, OBJECT_ARRAY_LENGTH);
    initObjectArray(objArray2, OBJECT_ARRAY_LENGTH);

    struct Queue queue1;
    struct Queue queue2;
    queueInit(&queue1);
    queueInit(&queue2);


    // used to send information over via bluetooth
    uint8_t objInfo1[OBJECT_ARRAY_LENGTH*12];
    uint8_t objInfo2[OBJECT_ARRAY_LENGTH*12];
    for (int i = 0; i < OBJECT_ARRAY_LENGTH*12; i++)
    {
        objInfo1[i] = 0;
        objInfo2[i] = 0;
    }

    par
    {
        OV07740_MasterThread(
            cmdStream1, cmdStream2,
            ffStream1, ffStream2,
            bluetoothChan,
            (uint8_t* unsafe)objInfo1, (uint8_t* unsafe)objInfo2);

        OV07740_GatherDataThread(cmdStream1,
            (port* unsafe)&cam1DATA);

        OV07740_GatherDataThread(cmdStream2,
            (port* unsafe)&cam2DATA);

        FloodFillThread(ffStream1, objArray1, &queue1, (uint8_t* unsafe)objInfo1);

        FloodFillThread(ffStream2, objArray2, &queue2, (uint8_t* unsafe)objInfo2);
    }
}}

int main()
{
    chan bluetoothChan;

    par
    {
        on tile[0]: Tile0(bluetoothChan);
        on tile[1]: Tile1(bluetoothChan);
    }
    return 0;
}
