#include <stdint.h>
#include <stdio.h>
#include <timer.h>
#include "io.h"
#include "gameAlg.h"

void GameThread(
    interface ObjectTrackerToGameInter server ot2g,
    interface BluetoothInter client btInter)
{ unsafe {

    printf("Game Thread\n");
    struct gameState currentGameState;
    struct Stack stack;

    stackInit(&stack);
    initGameState((struct gameState* unsafe)(&currentGameState));

    currentGameState.height = 72;
    currentGameState.kzoneTop = 50.0;
    currentGameState.kzoneBot = 20.0;

    struct gameState* unsafe tmpState = (struct gameState* unsafe)&currentGameState;


    float coords[5][2];
    // 24, 35
    // 12, 12
    // 36, 66
    // 16.5, 44
    // 29.5, 28
    coords[0][0] = 24.0;
    coords[0][1] = 35.0;
    coords[1][0] = 12.0;
    coords[1][1] = 12.0;
    coords[2][0] = 36.0;
    coords[2][1] = 66.0;
    coords[3][0] = 16.5;
    coords[3][1] = 44.0;
    coords[4][0] = 29.5;
    coords[4][1] = 28.0;

    uint8_t tmpBuffer[250*9];

    int32_t i = 0;
    while(1==1)
    {
        select
        {
            case ot2g.forwardBuffer(uint8_t buffer[], int n):
                for(int j = 0; j < 250*9; j++)
                {
                    tmpBuffer[j] = buffer[j];
                }
                btInter.sendBuffer(tmpBuffer, 250*9);
                break;

            case ot2g.forwardIntersection(uint8_t buffer[], int n):
                for(int j = 0; j < n; j++)
                {
                    tmpBuffer[j] = buffer[j];
                }
                btInter.sendBuffer(tmpBuffer, n);
                break;
        }

        /*
        currentGameState.lastBallx = coords[i][0];
        currentGameState.lastBally = coords[i][1];
        sendGameStatus(btInter, &currentGameState);
        delay_milliseconds(4000);
        i = (i + 1) % 5;*/
    }
}}




/* Format: B_S_O_HH_XX.XXX_YY.YYY_HS_AS_II_T_KT.KT_KB.KB
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
 *  KT.KT. is KZone top from look up table
 *  KB.KB is KZone bottom from lookup table
 */
void sendGameStatus(interface BluetoothInter client btInter, struct gameState* unsafe currentGameState)
{ unsafe {
    char output[46];

    char topOrBot;
    if(currentGameState->isBottom)
    {
        topOrBot = 'b';

    }
    else
    {
        topOrBot = 't';
    }
    snprintf(output, 46, "%01d %01d %01d %02d %06.3f %06.3f %02d %02d %02d %c %05.2f %05.2f\n",
            currentGameState->balls,
            currentGameState->strikes,
            currentGameState->outs,
            currentGameState->height,
            currentGameState->lastBallx,
            currentGameState->lastBally,
            currentGameState->home,
            currentGameState->away,
            currentGameState->inning,
            topOrBot,
            currentGameState->kzoneTop,
            currentGameState->kzoneBot);


    printf("sending %s\n", output);

    btInter.sendBuffer(output, 46);
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
void getGameStatus(streaming chanend x, struct Stack* unsafe stack, struct gameState* unsafe currentGameState)
{ unsafe {
    // Parse message.
    char input[46];

    for (int i = 0; i < 46; i++)
    {
       x :> input[i];
       if (input[i] == '!') break;
    }

    // update information
    switch(input[1])
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
}}



void initGameState(struct gameState* unsafe  gs)
{ unsafe {
    gs->balls     = 0;
    gs->strikes   = 0;
    gs->outs      = 0;
    gs->height    = 0;
    gs->inning    = 0;
    gs->isBottom  = 0;
    gs->home      = 0;
    gs->away      = 0;
    gs->lastBallx = 0.0;
    gs->lastBally = 0.0;
    gs->kzoneTop  = 0.0;
    gs->kzoneBot  = 0.0;
}}


void copyGameState(struct gameState* unsafe new, struct gameState* unsafe old)
{ unsafe {
    new->balls     = old->balls;
    new->strikes   = old->strikes;
    new->outs      = old->outs;
    new->height    = old->height;
    new->inning    = old->inning;
    new->isBottom  = old->isBottom;
    new->home      = old->home;
    new->away      = old->away;
    new->lastBallx = old->lastBallx;
    new->lastBally = old->lastBally;
    new->kzoneTop  = old->kzoneTop;
    new->kzoneBot  = old->kzoneBot;
}}

void stackInit(struct Stack* unsafe stack)
{ unsafe {
    for(int i = 0; i < STACK_SIZE; i++)
    {
        initGameState(&stack->states[i]);
    }
    stack->top = -1;
    stack->numElem = 0;
}}

// overwrites the oldest state
void stackPush(struct Stack* unsafe stack, struct gameState* unsafe state)
{ unsafe {
    stack->top = (stack->top + 1) % STACK_SIZE; // index
    copyGameState(&stack->states[stack->top], state);
    if(stack->numElem < STACK_SIZE) // if it's greater, than we're overwriting right now.
    {
        stack->numElem++;
    }
}}

int8_t stackPop(struct Stack* unsafe stack, struct gameState* unsafe state)
{ unsafe {
    if(stack->numElem == 0)
    {
        return -1; // error, nothing in queue
    }

    copyGameState(state, &stack->states[stack->top]);

    if(stack->top == 0)
    {
        stack->top = STACK_SIZE - 1;
    }
    else
    {
        stack->top--;
    }
    stack->numElem--;
    return 0;
}}

