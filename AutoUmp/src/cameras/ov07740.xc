// Auto-Ump specific implementation for the OV07740 camera
#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>
#include "assert.h"

#include "ov07740.h"
#include "sccb.h"
#include "floodFillAlg.h"

// All clocks used by the cameras
on tile[1]: clock camCLK = XS1_CLKBLK_1;
on tile[1]: clock sccb1CLK = XS1_CLKBLK_2;
on tile[1]: clock sccb2CLK = XS1_CLKBLK_3;
on tile[1]: clock pclk1CLK = XS1_CLKBLK_4;
on tile[1]: clock pclk2CLK = XS1_CLKBLK_5;

// Ports used by both cameras
on tile[1]: out port camRESET = XS1_PORT_1L;
on tile[1]: out port camSFIN = XS1_PORT_4C;
on tile[1]: in  port camSYNC  = XS1_PORT_8D;

// Camera 1 Ports
on tile[1]: out port cam1XCLK = XS1_PORT_1B;
on tile[1]: in  port cam1PCLK = XS1_PORT_1A;
on tile[1]:     port cam1SCL  = XS1_PORT_1N;
on tile[1]:     port cam1SDA  = XS1_PORT_1M;
on tile[1]: in buffered port:32 cam1DATA = XS1_PORT_8A;

// Camera 2 ports
on tile[1]: out port cam2XCLK = XS1_PORT_1D;
on tile[1]: in  port cam2PCLK = XS1_PORT_1C;
on tile[1]:     port cam2SCL  = XS1_PORT_1P;
on tile[1]:     port cam2SDA  = XS1_PORT_1O;
on tile[1]: in buffered port:32 cam2DATA = XS1_PORT_8C;

void OV07740_GetFrame(
    streaming chanend cam1, streaming chanend cam2,
    uint8_t* unsafe image1, uint8_t* unsafe image2,
    uint8_t* unsafe bitimage1, uint8_t* unsafe bitimage2);

static void delay(uint32_t delay_amount)
{
    timer t;
    uint32_t start_time;
    t :> start_time;
    t when timerafter(start_time + delay_amount) :> void;
}

void waitForVSync(uint8_t x, uint8_t vsync_bits)
{
    uint32_t cur;
    camSYNC :> cur;
    while (1)
    {
       select
       {
           case camSYNC when pinsneq(cur) :> cur:
               if ((cur & vsync_bits) == x) return;
               break;
       }
    }
}

static inline unsigned waitForHREF(uint8_t x, uint8_t href_bits)
{
    uint32_t cur;
    unsigned count;
    camSYNC :> cur;
    while (1)
    {
        select
        {
           case camSYNC when pinsneq(cur) :> cur @ count :
               if ((cur & href_bits) == x) return count;
               break;
        }
    }

    return 0;
}

void sendToBluetooth(chanend uart1, uint8_t* unsafe buf, int length)
{ unsafe {
    for (int i = 0; i < length; i++)
    {
        uart1 <: buf[i];
    }
}}

uint8_t gblImage1[320*240];
uint8_t gblImage2[320*240];
uint8_t gblBitImage1[320*240/8];
uint8_t gblBitImage2[320*240/8];

void OV07740_MasterThread(
    streaming chanend cams[],
    interface MasterToFloodFillInter client m2ff_tile1[],
    interface MasterToFloodFillInter client m2ff_tile0[])
{ unsafe {

    //printf("Master Thread\n");

    // First frame init
    OV07740_GetFrame(cams[0], cams[1], gblImage1, gblImage2, gblBitImage1, gblBitImage2);
    OV07740_GetFrame(cams[0], cams[1], gblImage1, gblImage2, gblBitImage1, gblBitImage2);
    OV07740_GetFrame(cams[0], cams[1], gblImage1, gblImage2, gblBitImage1, gblBitImage2);
    OV07740_GetFrame(cams[0], cams[1], gblImage1, gblImage2, gblBitImage1, gblBitImage2);
    OV07740_GetFrame(cams[0], cams[1], gblImage1, gblImage2, gblBitImage1, gblBitImage2);


    while (1)
    {
        OV07740_GetFrame(cams[0], cams[1], gblImage1, gblImage2, gblBitImage1, gblBitImage2);
        m2ff_tile1[0].sendBitBuffer(gblBitImage1, 320*240/8);
        m2ff_tile1[1].sendBitBuffer(gblBitImage2, 320*240/8);

        //delay_milliseconds(50);

        OV07740_GetFrame(cams[0], cams[1], gblImage1, gblImage2, gblBitImage1, gblBitImage2);
        m2ff_tile0[0].sendBitBuffer(gblBitImage1, 320*240/8);
        m2ff_tile0[1].sendBitBuffer(gblBitImage2, 320*240/8);

//        delay_milliseconds(50);

        OV07740_GetFrame(cams[0], cams[1], gblImage1, gblImage2, gblBitImage1, gblBitImage2);
        m2ff_tile0[2].sendBitBuffer(gblBitImage1, 320*240/8);
        m2ff_tile0[3].sendBitBuffer(gblBitImage2, 320*240/8);
//        delay_milliseconds(50);

    }
}}

// The thread that gathers all the data when
// instructed to do so by the sync thread
void OV07740_GatherDataThread(
    streaming chanend cmdStream,
    port* unsafe camDATA)
{ unsafe {

    uint32_t count, tmpData, x;
    uint8_t* unsafe bit;
    uint8_t* unsafe buf;
    uint8_t tmpBuffer[320];

    while (1==1)
    {
        x = 0;

        // Blocking statements that will wait until
        // the data is passed to it.
        cmdStream :> buf;
        cmdStream :> bit;
        cmdStream :> count;

        // Waits until the port counter for camDATA is
        // the value of `count`.  This ensures the program
        // samples at the first pixels correctly.
        (*camDATA) @ count :> tmpData;

        // Gather all pixels
        do
        {
            // The data comes in as "YUYV" and our program
            // only cares about the "Y" (aka grayscale) component
            // of the image.
            tmpBuffer[x++] = ((tmpData >> 8) & 0xFF);
            tmpBuffer[x++] = ((tmpData >> 24) & 0xFF);

            // Blocking until `camDATA` has a full buffer
            (*camDATA) :> tmpData;
        } while (x < 320);

        // Subtract the old background row with the new data
        computeBackgroundSub(tmpBuffer, buf, bit, BACKGROUND_SUBTRACTION_THRESHOLD);

        // Reports back to the sync core that this process is done.
        cmdStream <: 0;
    }
}}

void OV07740_GetFrame(
    streaming chanend cam1, streaming chanend cam2,
    uint8_t* unsafe image1, uint8_t* unsafe image2,
    uint8_t* unsafe bitimage1, uint8_t* unsafe bitimage2)
{ unsafe {

    // Sync both cameras
    camSFIN <: 0;
    delay(1000);
    camSFIN <: 1;

    waitForVSync(AU_VSYNC2, AU_VSYNC2);

    int i = 0;
    uint32_t tmpData;

    for (int y = 0; y < 240; y++)
    {
        // Send current byte row to threads
        cam1 <: (uint32_t)&((uint8_t* unsafe)image1)[y*320];
        cam2 <: (uint32_t)&((uint8_t* unsafe)image2)[y*320];

        // Send current bit row to threads.
        cam1 <: (uint32_t)&((uint8_t* unsafe)bitimage1)[y*40];
        cam2 <: (uint32_t)&((uint8_t* unsafe)bitimage2)[y*40];

        unsigned count = waitForHREF(AU_HREF2, AU_HREF2);

        count += 11;

        cam1 <: count;
        cam2 <: count;

        // Wait for cameras to finish computing data.
        int x;
        cam1 :> x;
        cam2 :> x;
    }
}}

int OV07740_InitCameras()
{ unsafe {

    // Configure output clock to both cameras.
    configure_clock_rate(camCLK, 100, 4);
    configure_port_clock_output(cam1XCLK, camCLK);
    configure_port_clock_output(cam2XCLK, camCLK);
    start_clock(camCLK);

    // Configured pixel input clock
    configure_clock_src(pclk1CLK, cam1PCLK);
    configure_in_port(cam1DATA, pclk1CLK);
    configure_in_port(cam2DATA, pclk1CLK);
    configure_in_port(camSYNC, pclk1CLK);
    start_clock(pclk1CLK);

    configure_clock_src(pclk2CLK, cam2PCLK);
    start_clock(pclk2CLK);

    // Take the cameras out of reset
    camRESET <: 1;

    // Initialize SCCB Bus for both cameras
    sccb_init(cam1SDA, cam1SCL, sccb1CLK);
    sccb_init(cam2SDA, cam2SCL, sccb2CLK);

    // First `scccb_rd` always returns 0xFF for some reason.
    // TODO: Fix this bug
    sccb_rd(CAM_SCCB_ID, 0x00, cam1SCL, cam1SDA);

    // Get Product ID from cam1
    int msb1 = sccb_rd(CAM_SCCB_ID, CAM_PRODUCT_MSB, cam1SCL, cam1SDA);
    int lsb1 = sccb_rd(CAM_SCCB_ID, CAM_PRODUCT_LSB, cam1SCL, cam1SDA);

    // Get Product ID from cam2
    int msb2 = sccb_rd(CAM_SCCB_ID, CAM_PRODUCT_MSB, cam2SCL, cam2SDA);
    int lsb2 = sccb_rd(CAM_SCCB_ID, CAM_PRODUCT_LSB, cam2SCL, cam2SDA);

    int returnVal = 0;

    if (msb1 == 0x77 && lsb1 == 0x40) returnVal += 0b01;
    if (msb2 == 0x77 && lsb2 == 0x40) returnVal += 0b10;

    return returnVal;
}}

int OV07740_ConfigureCameras()
{ unsafe {

    // Reset all registers to default values.
    sccb_wr(CAM_SCCB_ID, 0x12, 0b10000000, cam1SCL, cam1SDA);
    sccb_wr(CAM_SCCB_ID, 0x12, 0b10000000, cam2SCL, cam2SDA);

    // Allow the sensor to reset, delays for 50ms
    delay(5000000);

    // Iterate through the register/value pairs and write them
    // to the sensor.
    for (int i = 0; i < sizeof(OV7740_QVGA)/sizeof(struct SCCBPairs); i++)
    {
        sccb_wr(CAM_SCCB_ID,
            OV7740_QVGA[i].reg,
            OV7740_QVGA[i].value,
            cam1SCL, cam1SDA);

        sccb_wr(CAM_SCCB_ID,
            OV7740_QVGA[i].reg,
            OV7740_QVGA[i].value,
            cam2SCL, cam2SDA);
    }

    // Delay to let allow a few frames to go by
    delay(500000000);

    // Turn off AEC/AGC
    sccb_wr(CAM_SCCB_ID, 0x13, 0b00000000, cam1SCL, cam1SDA);
    sccb_wr(CAM_SCCB_ID, 0x13, 0b00000000, cam2SCL, cam2SDA);

    return 1;
}}
