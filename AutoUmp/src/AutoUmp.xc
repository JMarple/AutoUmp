#include <xs1.h>
#include <platform.h>

#include "ov07740.h"
#include "io.h"


// "UI" tile
void Tile0(chanend bluetoothChan)
{
    BluetoothThread(bluetoothChan);
}

// "Camera" tile
void Tile1(chanend bluetoothChan)
{ unsafe {

    //printf("Booting AutoUmp...\n");

    initCams();
    configureCams();
    launchCameras(bluetoothChan);
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
