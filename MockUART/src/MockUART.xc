#include "io.h"
#include <stdio.h>
#include <timer.h>
#include <stdint.h>

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
};

void initGameState(struct gameState* unsafe  gs)
{ unsafe {
    gs->balls    = 0;
    gs->strikes  = 0;
    gs->outs     = 0;
    gs->height   = 0;
    gs->inning   = 0;
    gs->isBottom = 0;
    gs->home     = 0;
    gs->away     = 0;
    gs->lastBallx = 0;
    gs->lastBally = 0;
}}

void copyGameState(struct gameState* unsafe new, struct gameState* unsafe old)
{ unsafe {
    new->balls    = old->balls;
    new->strikes  = old->strikes;
    new->outs     = old->outs;
    new->height   = old->height;
    new->inning   = old->inning;
    new->isBottom = old->isBottom;
    new->home     = old->home;
    new->away     = old->away;
    new->lastBallx = old->lastBallx;
    new->lastBally = old->lastBally;
}}

/* stack definition */
#define STACK_SIZE 100

struct Stack {
    struct gameState commandStack[STACK_SIZE];
    int16_t top;
};

void initStack(struct Stack* stack)
{ unsafe {
    stack->top = -1;
    for(int i = 0; i < STACK_SIZE; i++)
    {
        initGameState((struct gameState* unsafe)&(stack->commandStack[i]));
    }
}}

// overwrites the oldest state
void stackPush(struct Stack* unsafe stack, struct gameState* unsafe state)
{ unsafe {
    stack->top++; // do this first because we start at -1;
    copyGameState(&(stack->commandStack[stack->top]), state);
}}

// fills state with value of top of stack
int8_t stackPop(struct Stack* unsafe stack, struct gameState* unsafe state)
{ unsafe {
    if(stack->top == -1)
    {
        return -1; // error, nothing in queue
    }

    copyGameState(state, &(stack->commandStack[stack->top]));
    stack->top--;
    return 0;
}}
/* end stack definition */

void sendGameStatus(chanend x, struct gameState* unsafe currentGameState)
{ unsafe {
    char output[40];

    /* Format: B_S_O_HH_XX.XXX_YY.YYY_HS_AS_II_T
     * Where:
     *  B is ball count
     *  S is strike count
     *  O is out count
     *  HH is height in inches
     *  XX.XXX is x coordinate of ball
     *  YY.YYY is y coordinate of ball
     *  HS is home score
     *  AS is away score
     *  IIT is inning number of "t" or "b" for top/bottom
     */
    char topOrBot;
    if(currentGameState->isBottom)
    {
        topOrBot = 'b';

    }
    else
    {
        topOrBot = 't';
    }
    snprintf(output, 40, "%01d %01d %01d %02d %06.3f %06.3f %02d %02d %02d %c!",
            currentGameState->balls,
            currentGameState->strikes,
            currentGameState->outs,
            currentGameState->height,
            currentGameState->lastBallx,
            currentGameState->lastBally,
            currentGameState->home,
            currentGameState->away,
            currentGameState->inning,
            topOrBot);

    for (int i = 0; i < 40; i++)
    {
        x <: output[i];

        if (output[i] == '!') break;
    }

    //printf("sending %s\n", output);
}}



/*
 * Gets and updates game/batter data, as sent by the app.
 *
 * The XMOS will receive the following 5 byte string:
 * "C_HH\n"
 * HH is an integer between 00-99, and represents the height of the batter in inches.
 * C is an integer between 0-8, and represents the command the user has executed.
 * Commands:
 *  0: change height
 *  1: balls increment
 *  2: strikes increment
 *  3: outs increment
 *  4: clear count
 *  5: undo last command
 *  6: home score increment
 *  7: inning increment
 *  8: away score increment
 */
void getGameStatus(streaming chanend x, struct gameState* unsafe currentGameState, struct Stack* unsafe stack)
{ unsafe {
    // Parse message.
    char input[40];

    for (int i = 0; i < 39; i++)
    {
       x :> input[i];
       if (input[i] == '!')
       {
           input[i+1] = 0x00;
           break;
       }
    }

    char realInput[6];
    for(int i = 0; i < 6; i++)
    {
        realInput[i] = input[i];
    }

    printf("receiving %s\n", input);

//    char dummyInput[6];
//    dummyInput[0] = '6';
//    dummyInput[1] = ' ';
//    dummyInput[2] = '0';
//    dummyInput[3] = '0';
//    dummyInput[4] = '\n';
//    dummyInput[5] = 0x00;

    //printf("dummy %s\n", dummyInput);


    // update information
    switch(input[1]) // input[0] is SOH
    {
        case '0': // change height
            stackPush(stack, currentGameState);
            uint8_t high = input[3] - '0';
            uint8_t low  = input[4] - '0';
            currentGameState->height = high*10 + low;
            break;

        case '1': // ball increment
            stackPush(stack, currentGameState);
            currentGameState->balls = (currentGameState->balls + 1) % 4;
            break;

        case '2': // strike increment
            stackPush(stack, currentGameState);
            currentGameState->strikes = (currentGameState->strikes + 1) % 3;
            break;

        case '3': // out increment
            stackPush(stack, currentGameState);
            currentGameState->outs = (currentGameState->outs + 1) % 3;
            break;

        case '4': // clear count
            stackPush(stack, currentGameState);
            currentGameState->balls   = 0;
            currentGameState->strikes = 0;
            break;

        case '5': // undo
            int16_t err = stackPop(stack, currentGameState);
            /*if(err) // stack empty
            {
                break;
            }*/
            break;

        case '6': // home score increment
            stackPush(stack, currentGameState);
            currentGameState->home++;
            break;

        case '7': // inning increment
            stackPush(stack, currentGameState);
            if(currentGameState->isBottom)
            {
                currentGameState->isBottom = 0; // set to top of inning
                currentGameState->inning++;
            }
            else
            {
                currentGameState->isBottom = 1;
            }
            break;

        case '8': // away score increment
            stackPush(stack, currentGameState);
            currentGameState->away++;
            break;

        default:
            break;
    }

/*
    char topOrBot;
    if(currentGameState->isBottom)
    {
        topOrBot = 'b';

    }
    else
    {
        topOrBot = 't';
    }
    sscanf(input, "%01d %01d %01d %02d %06.3f %06.3f %02d %02d %02d %c\n",
            currentGameState->balls,
            currentGameState->strikes,
            currentGameState->outs,
            currentGameState->height,
            lastBallx,
            lastBally,
            currentGameState->home,
            currentGameState->away,
            currentGameState->inning,
            topOrBot);
            */
}}

void testing(chanend x, struct gameState* unsafe currentGameState)
{ unsafe {
    while (1==1)
    {
        sendGameStatus(x, currentGameState);
        delay_milliseconds(1000);
    }
}}

void receivedData(streaming chanend y, struct gameState* unsafe currentGameState, struct Stack* unsafe stack)
{ unsafe {
    while (1==1)
    {
        getGameStatus(y, currentGameState, stack);
        //printf("DtaOut = %c\n", input);
    }
}}

int main()
{ unsafe {
    printf("--- UART Tester ---\n");
    chan x;
    streaming chan y;
    struct gameState currentGameState;
    struct Stack undoStack;

    initStack(&undoStack);

    initGameState((struct gameState* unsafe)(&currentGameState));
    currentGameState.balls = 2;
    currentGameState.strikes = 1;
    currentGameState.height = 72;
    currentGameState.lastBallx = 50.000;
    currentGameState.lastBally = 50.000;

    struct gameState* unsafe tmpState = (struct gameState* unsafe)&currentGameState;
    struct Stack* unsafe tmpStack = (struct Stack* unsafe)&undoStack;

    par
    {
        BluetoothTxThread(x);
        testing(x, tmpState);
        receivedData(y, tmpState, tmpStack);
        BluetoothRxThread(y);
    }
    return 0;
}}
