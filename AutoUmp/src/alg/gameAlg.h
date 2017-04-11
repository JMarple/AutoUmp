#ifndef _GAME_H_
#define _GAME_H_

#include <stdint.h>
#include "io.h"
#include "interfaces.h"
#include "objectTrackerAlg.h"

#define STACK_SIZE 100

struct gameState
{
    uint8_t balls;
    uint8_t strikes;
    uint8_t outs;
    uint8_t height;
    uint8_t inning;
    uint8_t isBottom;
    uint8_t home;
    uint8_t away;
    float lastBallx;
    float lastBally;
    float kzoneTop;
    float kzoneBot;
};

struct Stack
{
    struct gameState states[STACK_SIZE];
    int32_t top;
    int32_t numElem;
};

void initGameState(
        struct gameState* unsafe gs);

void copyGameState(
        struct gameState* unsafe new,
        struct gameState* unsafe old);

void stackInit(
        struct Stack* unsafe stack);

void stackPush(
        struct Stack* unsafe stack,
        struct gameState* unsafe state);

int8_t stackPop(
        struct Stack* unsafe stack,
        struct gameState* unsafe state);

void sendGameStatus(
        interface BluetoothInter client btInter,
        struct gameState* unsafe currentGameState,
        uint16_t* unsafe intersections);

void getGameStatus(
        streaming chanend x,
        struct Stack* unsafe stack,
        struct gameState* unsafe currentGameStatus);

void GameThread(
        interface ObjectTrackerToGameInter server ot2g,
        interface BluetoothInter client btInter);

#endif
