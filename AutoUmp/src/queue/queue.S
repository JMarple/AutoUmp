	.globl optDetObj
	.align 4
	.globl optDetObj.nstackwords
	.linkset optDetObj.nstackwords, 10
	.issue_mode dual

	#define queueArray   r0
	#define queueTail    r1
	#define queueNumElem r2
	#define indexCurrent r3
	#define bitPicture   r4
	#define box	         r5

	#define tmp1         r7
	#define tmp2         r8
	#define tmp3         r9

optDetObj:
	{dualentsp 10; nop}

	stw r4, sp[2]
	stw r5, sp[3]
	stw r6, sp[4]
	stw r7, sp[5]
	stw r8, sp[6]
	stw r9, sp[7]
	stw r10, sp[8]
	stw r11, sp[9]

	ldw bitPicture, sp[11]
	ldw box, sp[12]

	ldc r10, 320

    // arr[tail] = indexCurrent;
	stw indexCurrent, queueArray[queueTail]

	// tail = (tail + 1) % BUFFER_SIZE;	//numElem++;`
	{add queueTail, queueTail, 0x01; add queueNumElem, queueNumElem, 0x01}
	remu queueTail, queueTail, r10

	//uint32_t byteIndex = bitIndex/8; <- same as shift right by 3 right?
    //uint8_t bitNum = bitIndex & 0b111;
    {ldc tmp2, 7; ldc tmp3, 1}
    {shr tmp1, indexCurrent, 3; and tmp2, indexCurrent, tmp2}

	//bitPicture[byteIndex] = (bitPicture[byteIndex] & ~(1 << bitNum));
	{ld8u tmp3, bitPicture[tmp1]; shl tmp2, tmp3, tmp2}
	not tmp2, tmp2
	and tmp3, tmp3, tmp2
	st8 tmp3, bitPicture[tmp1]

	//uint16_t newY = indexCurrent / IMG_WIDTH; // goes along rows/height of image
	divu tmp1, indexCurrent, r10

	//uint16_t newX = (indexCurrent % IMG_WIDTH); // goes along columns/width of image
	remu tmp2, indexCurrent, r10

	//if(newX < box[0]) box[0] = newX;
	newXLTbox0:
		ldw tmp3, box[0]
		lsu tmp3, tmp2, tmp3
		bf tmp3, newXGTbox1
		stw tmp2, box[0]

	//if(newX > box[1]) box[1] = newX;
	newXGTbox1:
		ldw tmp3, box[1]
		lsu tmp3, tmp3, tmp2
		bf tmp3, newYLTbox2
		stw tmp2, box[1]

	//if(newY < box[2]) box[2] = newY;
	newYLTbox2:
		ldw tmp3, box[2]
		lsu tmp3, tmp1, tmp3
		bf tmp3, newYGTbox3
		stw tmp1, box[2]

	//if(newY > box[3]) box[3] = newY;
	newYGTbox3:
		ldw tmp3, box[3]
		lsu tmp3, tmp3, tmp1
		bf tmp3, exit_det_obj
		stw tmp1, box[3]

	exit_det_obj:

	ldw r4, sp[2]
	ldw r5, sp[3]
	ldw r6, sp[4]
	ldw r7, sp[5]
	ldw r8, sp[6]
	ldw r9, sp[7]
	ldw r10, sp[8]
	ldw r11, sp[9]

	retsp 10

/*	.globl assembQueueEnqueue
	.align 4
	.issue_mode dual

// registers r0, r1..., r3 will be the first four arguments.

// if I have a struct how do I access a member of that struct?
// how do I modulo?
// how do I access a constant like buffer size or queue_full? (#include?)
//
assembQueueEnqueue:
	dualentsp SOME_NUMBER_OF_TEMP_VARS

	std
*/
