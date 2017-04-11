#ifndef __IO_H__
#define __IO_H__

interface BluetoothInter
{
    void sendBuffer(uint8_t buffer[], int n);
};

// BLUETOOTH
//#define BAUD_RATE 57600

// UART
#define BAUD_RATE 921600
#define BT_CLOCK_TICKS (100000000 / BAUD_RATE)

void BluetoothTxThread(interface BluetoothInter server inter);

[[combinable]]
void BluetoothRxThread(streaming chanend dataOut);

[[combinable]]
void TLC59731Thread();

void turnOnLED6(int val);
void turnOnLED5(int val);
void turnOnLED4(int val);
#endif
