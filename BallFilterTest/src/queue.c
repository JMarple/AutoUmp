/*
    Implements a queue (FIFO) using a circular buffer.
*/
#include <stdint.h>
#include "queue.h"

void dummy2(uint32_t* pointer)
{
    pointer[0] = 1;
}

void dummyQueue(struct Queue* q)
{
    q-> head = 0;
    q-> tail = 1;
    q-> numElem = 2;
    q->arr[0] = 3;
}

void queueInit(struct Queue* q)
{
    q->head    = 0;
    q->tail    = 0;
    q->numElem = 0;
    int i;
    for(i = 0; i < BUFFER_SIZE; i++)
    {
        q->arr[i] = 0;
    }
}

void queueReset(struct Queue* q)
{
    q->head    = 0;
    q->tail    = 0;
    q->numElem = 0;
}

uint32_t queueEnqueue(struct Queue* q, uint32_t val)
{
    if(q->numElem == BUFFER_SIZE)
    {
        return QUEUE_FULL;
    }

    q->arr[q->tail] = val;
    q->tail = (q->tail + 1) % BUFFER_SIZE;
    q->numElem++;

    return 0;
}

uint32_t queueDequeue(struct Queue* q)
{
    if(q->numElem <= 0)
    {
        return NO_ELEM_IN_QUEUE;
    }

    uint32_t temp = q->arr[q->head];
    q->head = (q->head + 1) % BUFFER_SIZE;
    q->numElem--;
    return temp;
}

uint32_t queuePeek(struct Queue* q)
{
    if(q->numElem <= 0)
    {
        return NO_ELEM_IN_QUEUE;
    }

    return q->arr[q->head];
}

uint8_t queueIsEmpty(struct Queue* q)
{
    if(q->numElem == 0)
    {
        return 1;
    }
    else return 0;
}
