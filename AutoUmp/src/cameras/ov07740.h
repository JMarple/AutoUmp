#ifndef __OV07740_H__
#define __OV07740_H__

#include <stdint.h>
#include "floodFillAlg.h"
#include "interfaces.h"

#define BACKGROUND_SUBTRACTION_THRESHOLD 10

// Establishes communication with the cameras
// Returns 3 if both cameras are connected
//         1 or 2 if only one camera is connected
//         0 if an error
int OV07740_InitCameras();

// Configures settings over sccb with cameras.
// Returns 0 if an error occured
int OV07740_ConfigureCameras();

void launchCameras(chanend uart1);

void OV07740_MasterThread(
    streaming chanend cams[],
    interface MasterToFloodFillInter client m2ff_tile1[],
    interface MasterToFloodFillInter client m2ff_tile0[]);

void OV07740_GatherDataThread(
    streaming chanend cmdStream,
    port* unsafe camDATA);

void computeBackgroundSub(
    uint8_t* unsafe tmp,
    uint8_t* unsafe old,
    uint8_t* unsafe bit,
    int threshold);

struct SCCBPairs
{
    uint8_t reg;
    uint8_t value;
};

#define CAM_SCCB_ID 0x21

// Product ID = 0x7740
#define CAM_PRODUCT_MSB 0x0A
#define CAM_PRODUCT_LSB 0x0B

#define CAM_HAEC 0x0F // Exposure msb
#define CAM_AEC 0x10 // Exposure lsb

// AutoUmp RevA specific port bit's
// This is needed since the HREF/VSYNC's share the same
// 8-bit port for both cameras.
#define AU_HREF1  (1 << 4)
#define AU_VSYNC1 (1 << 5)
#define AU_HREF2  (1 << 6)
#define AU_VSYNC2 (1 << 7)

/*static struct SCCBPairs OV7740_QVGA[] =
{
    // Activates HOUTSIZE, VOUTSIZE.  IDK why.
    {0x12, 0x00},

    // Turns off AEC/AGC algorithms
    {0x13, 0x00},

    // Set Gain
    {0x00, 0xFF}, // LSB [0:7]
    {0x15, 0x02}, // MSB [0:1]

    // Set Image Size to 320x240
    // Set HOUTSIZE to 80, which when bit shifted
    //      twice due to REG34, will return 320
    //{0x31, 0x50},

    // Set VOUTSIZE to 120, which when bit shifted
    //      once due to REG34, will return 240
    {0x32, 0x78},

    //{0x0C, 0x42},

    // Turn on Test Pattern
    //{0x38, 0x17},
    //{0x84, 0x02},
};*/


static struct SCCBPairs OV7740_QVGA[] =
{
    {0x13, 0x00},

    {0x55, 0x40},//div
    {0x11, 0x00},
    {0x12, 0x00},
    {0xd5, 0x10},
    {0x0c, 0x42},
    {0x16, 0x11},

    {0x0d, 0x34},
    {0x17, 0x25},
    {0x18, 0xa0},
    {0x19, 0x03},
    {0x1a, 0xf0},
    {0x1b, 0x89},
    {0x22, 0x03},
    {0x29, 0x17},
    {0x2b, 0xf8},
    {0x2c, 0x01},

    // Sets image size to 320x240
    {0x31, 0x50},
    {0x32, 0x78},
    {0x33, 0xc4},
    {0x35, 0x05},
    {0x36, 0x3f},

    // Set Gain
    /*{0x00, 0xFF}, // LSB [0:7]
    {0x15, 0x02}, // MSB [0:1]*/

    {0x04, 0x60},
    {0x27, 0x80},
    {0x3d, 0x0f},
    {0x3e, 0x82},
    {0x3f, 0x40},
    {0x40, 0x7f},
    {0x41, 0x6a},
    {0x42, 0x29},
    {0x44, 0xe5},
    {0x45, 0x41},
    {0x47, 0x42},
    {0x48, 0x00},
    {0x49, 0x61},
    {0x4a, 0xa1},
    {0x4b, 0x46},
    {0x4c, 0x18},
    {0x4d, 0x50},
    {0x4e, 0x13},
    {0x64, 0x00},
    {0x67, 0x88},
    {0x68, 0x1a},

    {0x14, 0x38},
    {0x24, 0x3c},
    {0x25, 0x30},
    {0x26, 0x72},
    {0x50, 0x97},
    {0x51, 0x7e},
    {0x52, 0x00},
    {0x53, 0x00},
    {0x20, 0x00},
    {0x21, 0x23},
    {0x38, 0x14},
    {0xe9, 0x00},
    {0x56, 0x55},
    {0x57, 0xff},
    {0x58, 0xff},
    {0x59, 0xff},
    {0x5f, 0x04},
    {0xec, 0x00},
    {0x13, 0xff},

    {0x80, 0x7d},
    {0x81, 0x3f},
    {0x82, 0x3f},
    {0x83, 0x01},
    {0x38, 0x11},
    {0x84, 0x70},
    {0x85, 0x00},
    {0x86, 0x03},
    {0x87, 0x01},
    {0x88, 0x05},
    {0x89, 0x30},
    {0x8d, 0x30},
    {0x8f, 0x85},
    {0x93, 0x30},
    {0x95, 0x85},
    {0x99, 0x30},
    {0x9b, 0x85},
};


#endif
