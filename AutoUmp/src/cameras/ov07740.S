	//.globl ov7670_capturerow.nstackwords
	//.linkset ov7670_capturerow.nstackwords, 10
	.globl computeBackgroundSub
	.globl computeBackgroundSub.nstackwords
	.linkset computeBackgroundSub.nstackwords, 10
	.align 4
	.issue_mode dual

// Computes Background Subtraction
// r0 is tmpBuffer
// r1 is saved old data
// r2 is the bit buffer
// r3 is threshold
computeBackgroundSub:
	dualentsp 12

	stw r2, sp[2]
	stw r3, sp[3]
	stw r4, sp[4]
	stw r5, sp[5]
	stw r6, sp[6]
	stw r7, sp[7]
	stw r8, sp[8]
	stw r9, sp[9]
	stw r10, sp[10]
	stw r11, sp[11]

	#define tmpBufPtr r0
	#define oldBufPtr r1
	#define bitBufPtr r2
	#define threshold r3
	#define loopCutoff r4
	#define x r5
	#define lNewData r6
	#define rNewData r7
	#define lOldData r8
	#define rOldData r9
	#define bitData r10
	#define bitIndex r11

	#define lBitResult r6
	#define rBitResult r7

	ldc x, 0x00
	ldc loopCutoff, 319
	ldc bitIndex, 0x00

	computeloop:

		// -- ROUND 1 --
		// Load new data
		{ld8u lNewData, tmpBufPtr[x]; add x, x, 1}
		{ld8u rNewData, tmpBufPtr[x]; sub x, x, 1}

		// Load old data
		{ld8u lOldData, oldBufPtr[x]; add x, x, 1}
		{ld8u rOldData, oldBufPtr[x]; add x, x, 1}

		// Background subtraction
		{sub lOldData, lOldData, lNewData; sub rOldData, rOldData, rNewData}
		{neg lNewData, lOldData; neg rNewData, rOldData}
		{lss lOldData, threshold, lOldData; lss rOldData, threshold, rOldData}
		{lss lNewData, threshold, lNewData; lss rNewData, threshold, rNewData}
		{or lBitResult, lOldData, lNewData; or rBitResult, rOldData, rNewData}
		// End BS

		{add bitData, lBitResult, 0; shl rBitResult, rBitResult, 1}
		{or bitData, bitData, rBitResult; nop}
		// -------------



		// -- ROUND 2 --
		{ld8u lNewData, tmpBufPtr[x]; add x, x, 1}
		{ld8u rNewData, tmpBufPtr[x]; sub x, x, 1}

		// Load old data
		{ld8u lOldData, oldBufPtr[x]; add x, x, 1}
		{ld8u rOldData, oldBufPtr[x]; add x, x, 1}

		// Background subtraction
		{sub lOldData, lOldData, lNewData; sub rOldData, rOldData, rNewData}
		{neg lNewData, lOldData; neg rNewData, rOldData}
		{lss lOldData, threshold, lOldData; lss rOldData, threshold, rOldData}
		{lss lNewData, threshold, lNewData; lss rNewData, threshold, rNewData}
		{or lBitResult, lOldData, lNewData; or rBitResult, rOldData, rNewData}
		// End BS

		{shl lBitResult, lBitResult, 2; shl rBitResult, rBitResult, 3}
		{or bitData, bitData, lBitResult; nop}
		{or bitData, bitData, rBitResult; nop}
		// -------------



		// -- ROUND 3 --
		{ld8u lNewData, tmpBufPtr[x]; add x, x, 1}
		{ld8u rNewData, tmpBufPtr[x]; sub x, x, 1}

		// Load old data
		{ld8u lOldData, oldBufPtr[x]; add x, x, 1}
		{ld8u rOldData, oldBufPtr[x]; add x, x, 1}

		// Background subtraction
		{sub lOldData, lOldData, lNewData; sub rOldData, rOldData, rNewData}
		{neg lNewData, lOldData; neg rNewData, rOldData}
		{lss lOldData, threshold, lOldData; lss rOldData, threshold, rOldData}
		{lss lNewData, threshold, lNewData; lss rNewData, threshold, rNewData}
		{or lBitResult, lOldData, lNewData; or rBitResult, rOldData, rNewData}
		// End BS

		{shl lBitResult, lBitResult, 4; shl rBitResult, rBitResult, 5}
		{or bitData, bitData, lBitResult; nop}
		{or bitData, bitData, rBitResult; nop}
		// -------------



		// -- ROUND 4 --
		{ld8u lNewData, tmpBufPtr[x]; add x, x, 1}
		{ld8u rNewData, tmpBufPtr[x]; sub x, x, 1}

		// Load old data
		{ld8u lOldData, oldBufPtr[x]; add x, x, 1}
		{ld8u rOldData, oldBufPtr[x]; add x, x, 1}

		// Background subtraction
		{sub lOldData, lOldData, lNewData; sub rOldData, rOldData, rNewData}
		{neg lNewData, lOldData; neg rNewData, rOldData}
		{lss lOldData, threshold, lOldData; lss rOldData, threshold, rOldData}
		{lss lNewData, threshold, lNewData; lss rNewData, threshold, rNewData}
		{or lBitResult, lOldData, lNewData; or rBitResult, rOldData, rNewData}
		// End BS

		{shl lBitResult, lBitResult, 6; shl rBitResult, rBitResult, 7}
		{or bitData, bitData, lBitResult; nop}
		{or bitData, bitData, rBitResult; nop}
		// -------------

		// Save bit info
		st8 bitData, bitBufPtr[bitIndex]
		add bitIndex, bitIndex, 1

		lss lNewData, x, loopCutoff
		bt lNewData, computeloop

	// Copy buffers
	// Repetition to speed up process
	// (no reason to branch on non multiples of 4)
	ldc x, 0;
	ldc loopCutoff, 39
	copyNewDataToOldBuffer:
		ldd lNewData, rNewData, tmpBufPtr[x]
		std lNewData, rNewData, oldBufPtr[x]
		add x, x, 1;
		ldd lNewData, rNewData, tmpBufPtr[x]
		std lNewData, rNewData, oldBufPtr[x]
		add x, x, 1;
		ldd lNewData, rNewData, tmpBufPtr[x]
		std lNewData, rNewData, oldBufPtr[x]
		add x, x, 1;
		ldd lNewData, rNewData, tmpBufPtr[x]
		std lNewData, rNewData, oldBufPtr[x]
		{add x, x, 1; lss lNewData, x, loopCutoff}

		bt lNewData, copyNewDataToOldBuffer

	ldw r2, sp[2]
	ldw r3, sp[3]
	ldw r4, sp[4]
	ldw r5, sp[5]
	ldw r6, sp[6]
	ldw r7, sp[7]
	ldw r8, sp[8]
	ldw r9, sp[9]
	ldw r10, sp[10]
	ldw r11, sp[11]
	retsp 12


