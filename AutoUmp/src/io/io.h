#ifndef __IO_H__
#define __IO_H__

interface BluetoothInter
{
    void sendBuffer(uint8_t buffer[], int n);
};

interface LEDInter
{
    void setLED(uint8_t r, uint8_t g, uint8_t b);
    void setR(uint8_t r);
    void setG(uint8_t g);
    void setB(uint8_t b);
};

// UART
#define BAUD_RATE 921600

// BLUETOOTH
//#define BAUD_RATE 9600
#define BT_CLOCK_TICKS (100000000 / BAUD_RATE)

void BluetoothTxThread(interface BluetoothInter server inter);

[[combinable]]
void BluetoothRxThread(streaming chanend dataOut);

[[combinable]]
 void TLC59731Thread(interface LEDInter server led);

void turnOnLED6(int val);
void turnOnLED5(int val);
void turnOnLED4(int val);
#endif
