#ifndef __IO_H__
#define __IO_H__

#define BAUD_RATE 57600
#define BT_CLOCK_TICKS (100000000 / BAUD_RATE)

void BluetoothTxThread(chanend dataIn);
void BluetoothRxThread(streaming chanend dataOut);

#endif
