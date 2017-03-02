// Auto-Ump specific implementation for the OV07740 camera

#include <xs1.h>
#include <platform.h>
#include <stdlib.h>
#include <stdio.h>

#include "ov07740.h"
#include "sccb.h"

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

const uint8_t CAM_SCCB_ID = 0x21;

// Product ID = 0x7740
const uint8_t CAM_PRODUCT_MSB = 0x0A;
const uint8_t CAM_PRODUCT_LSB = 0x0B;

const uint8_t CAM_HAEC = 0x0F; // Exposure msb
const uint8_t CAM_AEC = 0x10; // Exposure lsb

// AutoUmp RevA specific port bit's
// This is needed since the HREF/VSYNC's share the same
// 8-bit port for both cameras.
const uint8_t AU_HREF1 = (1 << 4);
const uint8_t AU_VSYNC1 = (1 << 5);
const uint8_t AU_HREF2 = (1 << 6);
const uint8_t AU_VSYNC2 = (1 << 7);

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

void floodFill(chanend stream)
{
    while (1==1)
    {
        uint32_t starttime, endtime;
        timer t;

        t :> starttime;

        // Tim your code goes here.

        t :> endtime;
        printf("Clock ticks (@100Mhz) = %d\n", (endtime - starttime));
    }
}

void gatherDataThread(
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

        cmdStream :> buf;
        cmdStream :> bit;
        cmdStream :> count;

        (*camDATA) @ count :> tmpData;

        // Gather data
        do
        {
           tmpBuffer[x++] = ((tmpData >> 8) & 0xFF);
           tmpBuffer[x++] = ((tmpData >> 24) & 0xFF);
           (*camDATA) :> tmpData;
        } while (x < 320);

        computeOV7670Data(tmpBuffer, buf, bit, 5);

        cmdStream <: 0;
    }
}}

void ov07740_denoise(
    uint32_t* unsafe top,
    uint32_t* unsafe cur,
    uint32_t* unsafe bot)
{ unsafe {
    for (int byte = 9; byte >= 0; byte--)
    {
        // Bytes
        uint32_t topByte = top[byte];
        uint32_t curByte = cur[byte];
        uint32_t botByte = bot[byte];

        // Bits
        uint32_t topBit, botBit;
        uint32_t leftBit, curBit, rightBit;

        // Final byte to save back
        uint32_t toSaveByte = 0;

        rightBit = curByte & 0x1;
        curByte = curByte >> 1;
        curBit = curByte & 0x1;

        for (int bit = 1; bit < 31; bit++)
        {
            curByte = curByte >> 1;
            leftBit = curByte & 0x1;

            // Top Byte
            topByte = topByte >> 1;
            topBit  = topByte & 0x1;

            // Bottom Byte
            botByte = botByte >> 1;
            botBit  = botByte & 0x1;

            uint32_t count;
            count = rightBit + leftBit + topBit + botBit;
            //count *= curBit;
            //count = (count > 2);
            count = curBit;
            count = count << 31;
            toSaveByte |= count;
            toSaveByte = toSaveByte >> 1;

            rightBit = curBit;
            curBit = leftBit;
        }

        toSaveByte = toSaveByte >> 1;
        cur[byte] = toSaveByte;
    }
}}

uint32_t testrow[242*320/4];
uint32_t testrow2[242*320/4];
uint32_t bitimage[242*40/4];
uint32_t bitimage2[242*40/4];

void getFrame(streaming chanend cam1, streaming chanend cam2)
{ unsafe {
    // Sync Frames
    camSFIN <: 0;
    delay(1000);
    camSFIN <: 1;

    waitForVSync(AU_VSYNC2, AU_VSYNC2);

    int i = 0;
    uint32_t tmpData;

    for (int y = 0; y < 240; y++)
    {
        // Send current byte row to threads
        cam1 <: &((uint8_t* unsafe)testrow)[y*320];
        cam2 <: &((uint8_t* unsafe)testrow2)[y*320];

        // Send current bit row to threads.
        cam1 <: &((uint8_t* unsafe)bitimage)[y*40];
        cam2 <: &((uint8_t* unsafe)bitimage2)[y*40];

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

void ov07740_capture(streaming chanend cam1, streaming chanend cam2, chanend uart1)
{ unsafe {
    uint8_t data, vsync = 1;
    timer t;
    uint32_t starttime, endtime;

    int lc = 0;

    while (1)
    {
        timer t;
        uint32_t st, en;

        t :> st;
        getFrame(cam1, cam2);
        getFrame(cam1, cam2);
        getFrame(cam1, cam2);
        t :> en;

        //sendToBluetooth(uart1, (uint8_t* unsafe)testrow, 240*320);
        //sendToBluetooth(uart1, (uint8_t* unsafe)testrow2, 240*320);
        //sendToBluetooth(uart1, (uint8_t* unsafe)bitimage, 240*40);
        sendToBluetooth(uart1, (uint8_t* unsafe)bitimage2, 240*40);
        printf("Sent Frame! %d clk ticks\n", (en-st));
    }

    //printf("Done!\n");
    while (1);
}}

void launchCameras(chanend uart1)
{ unsafe {
    void* unsafe sync = (void* unsafe)&camSYNC;

    streaming chan cmdStream1, cmdStream2;

    par
    {
        gatherDataThread(cmdStream1,
            (port* unsafe)&cam1DATA);

        gatherDataThread(cmdStream2,
            (port* unsafe)&cam2DATA);

        ov07740_capture(cmdStream1, cmdStream2, uart1);
    }

    while (1==1);
}}

int configureCams()
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
    delay(100000000);

    // Turn off AEC/AGC
    sccb_wr(CAM_SCCB_ID, 0x13, 0b00000000, cam1SCL, cam1SDA);
    sccb_wr(CAM_SCCB_ID, 0x13, 0b00000000, cam2SCL, cam2SDA);

    return 1;
}}

int initCams()
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