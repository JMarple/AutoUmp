#include <xs1.h>
#include <platform.h>
#include <stdint.h>
#include <string.h>
#include "io.h"
#include "hwlock.h"

// Contains BT_TX, LED4, LED5 on bit 0, 2, 3 respectively
on tile[0]: out port IOPortOut1 = XS1_PORT_4F;
const uint8_t AU_BT_TX = 0b0001;
const uint8_t AU_LED4  = 0b0100;
const uint8_t AU_LED5  = 0b1000;

on tile[0]: out port AU_LED6 = XS1_PORT_1O;

// Contains Button1, Button2, BT_RX on bit 0, 1, 2 respectively
on tile[0]: in port IOPortIn1 = XS1_PORT_4E;

// XTAG UART Stream
on tile[0]: out port X_TX = XS1_PORT_1M;
on tile[0]: in port X_RX = XS1_PORT_1N;

// LED's are controlled via SDI interface
on tile[0]: out port LED_SDI = XS1_PORT_1J;

// Battery status port, 1 = battery is fine, 0 = battery is low
on tile[0]: in port BAT_STATUS = XS1_PORT_1L;

// Timing used for LED_SDI
uint32_t t_cycle = 2500;

// There is only one instance of an io port on each xmos board
// so it's represented as a "singleton" here.
uint32_t baudRate = 9600;
uint8_t ioPortByte = 0x00;
hwlock_t ioPortLock;
timer ioPortTimer;
uint32_t ioPortTime;

void turnOnLED6(int val)
{
    AU_LED6 <: val;
}

// Thread safe code for turning on certain bits on a port.
static void _assignIoOutPort(uint8_t mask, uint8_t value)
{
    hwlock_acquire(ioPortLock);

    if (value == 1)
        ioPortByte |= mask;
    else
        ioPortByte &= ~mask;

    IOPortOut1 <: ioPortByte;
    hwlock_release(ioPortLock);
}

void turnOnLED5(int val)
{
    _assignIoOutPort(AU_LED5, val);
}

void turnOnLED4(int val)
{
    _assignIoOutPort(AU_LED4, val);
}

static void _uartWait()
{
    const uint32_t waitAmount = BT_CLOCK_TICKS;
    ioPortTime += waitAmount;
    ioPortTimer when timerafter(ioPortTime) :> void;
}

void BluetoothInit()
{
    ioPortLock = hwlock_alloc();
}

void BluetoothDeinit()
{
    hwlock_free(ioPortLock);
}

// Blocking
void BluetoothSendByte(uint8_t data)
{
    // Start bit
    _assignIoOutPort(AU_BT_TX, 0);
    ioPortTimer :> ioPortTime;
    _uartWait();

    // Data bits
    for (int i = 0; i < 8; i++)
    {
        int output = (data >> i) & 0b1;
        _assignIoOutPort(AU_BT_TX, output);
        _uartWait();
    }

    // Stop bit
    _assignIoOutPort(AU_BT_TX, 1);
    _uartWait();
}

// Blocking
void BluetoothSendBuffer(uint8_t* buf, int length)
{
    for (int i = 0; i < length; i++)
        BluetoothSendByte(buf[i]);
}

void BluetoothThread(interface BluetoothInter server inter)
{
    BluetoothInit();

    uint8_t buffer[320*240/8];
    int len;

    while (1)
    {
        select
        {
            case inter.sendBuffer(uint8_t tmpbuffer[], int n):
                memcpy(buffer, tmpbuffer, n*sizeof(uint8_t));
                len = n;
                break;
        }

        int i;
        for (i = 0; i < len;)
        {
            select
            {
                default:
                    BluetoothSendByte(buffer[i]);
                    i++;
                    break;
            }
        }
    }
}

uint8_t LED0 = 0;
uint8_t LED1 = 0;
uint8_t LED2 = 0;

#define FALLING_SDI 0
#define RISING_BIT 1
#define FALLING_BIT 2
#define RISING_SDI 3
#include <stdio.h>
void TLC59731Thread()
{
    timer tlcTimer;
    int mode = RISING_SDI;
    int counter = 0;

    uint32_t start_time;
    tlcTimer :> start_time;
    start_time += t_cycle;

    uint32_t data;
    data = 0x3A000000;

    while (1)
    {
        select
        {
            case tlcTimer when timerafter(start_time) :> void:
                switch (mode)
                {
                    // Rising edge that occurs for every bit
                    case RISING_SDI:
                        LED_SDI <: 1;
                        start_time += t_cycle * 0.1;
                        mode = FALLING_SDI;
                        break;

                    // Falling edge that occurs for every bit
                    case FALLING_SDI:
                        LED_SDI <: 0;
                        start_time += t_cycle * 0.3;
                        mode = RISING_BIT;
                        break;

                    // If data bit is 1, have a rising edge.
                    // Otherwise stay zero
                    case RISING_BIT:
                        LED_SDI <: (data >> (31-counter)) & 0b1;
                        counter++;
                        start_time += t_cycle * 0.2;
                        mode = FALLING_BIT;
                        break;

                    // If the data bit was high, go low.
                    case FALLING_BIT:
                        LED_SDI <: 0;
                        mode = RISING_SDI;
                        if (counter >= 32)
                        {
                            counter = 0;
                            start_time += t_cycle * 9.0;
                            LED0++;
                            LED1++;
                            LED2++;
                            data = (0x3A << 24) | (LED0 << 16) | (LED1 << 8) | (LED2);
                        }
                        else
                        {
                            start_time += t_cycle * 0.4;
                        }
                        break;
                }
                break;
        }
    }
}
