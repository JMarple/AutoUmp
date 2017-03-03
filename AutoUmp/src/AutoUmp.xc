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
    BluetoothThread(bluetoothChan);
}

// "Camera" tile
void Tile1(chanend bluetoothChan)
{ unsafe {

    printf("Booting AutoUmp...\n");

    OV07740_InitCameras();
    OV07740_ConfigureCameras();

    streaming chan cmdStream1, cmdStream2;
    chan ffStream1, ffStream2;

    par
    {
        OV07740_MasterThread(
            cmdStream1, cmdStream2,
            ffStream1, ffStream2,
            bluetoothChan);

        OV07740_GatherDataThread(cmdStream1,
            (port* unsafe)&cam1DATA);

        OV07740_GatherDataThread(cmdStream2,
            (port* unsafe)&cam2DATA);

        FloodFillThread(ffStream1);

        FloodFillThread(ffStream2);
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
