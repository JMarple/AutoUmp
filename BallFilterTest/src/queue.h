/*
 * queue.h
 *
 *  Created on: Mar 6, 2017
 *      Author: tbadams45
 */


#ifndef QUEUE_H_
#define QUEUE_H_

#define BUFFER_SIZE 320
#define NO_ELEM_IN_QUEUE 2147483647 // 2^31-1
#define QUEUE_FULL 2147483646

struct Queue
{
    uint32_t arr[BUFFER_SIZE]; // data
    uint16_t head;             // read index
    uint16_t tail;             // write index
    uint16_t numElem;          // to check for buffer overflow
};


/*{uint32_t, uint32_t, uint32_t} optDetObj(
    uint32_t* arr,
    uint32_t tail,
    uint32_t numElem,
    uint32_t indexCurrent,
    uint8_t* unsafe bitPicture,
    uint32_t* box);
*/
void dummyQueue(struct Queue* q);
void dummy2(uint32_t* pointer);

void queueInit(struct Queue* q);

void queueReset(struct Queue* q);

uint32_t queueEnqueue(struct Queue* q, uint32_t val);

uint32_t queueDequeue(struct Queue* q);

uint32_t queuePeek(struct Queue* q);

uint8_t queueIsEmpty(struct Queue* q);


#endif /* QUEUE_H_ */
