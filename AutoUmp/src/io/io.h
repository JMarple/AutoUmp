#ifndef __IO_H__
#define __IO_H__

interface BluetoothInter
{
    void sendBuffer(uint8_t buffer[], int n);
};

void BluetoothThread(interface BluetoothInter server inter);

void turnOnLED6(int val);
void turnOnLED5(int val);
void turnOnLED4(int val);
#endif
