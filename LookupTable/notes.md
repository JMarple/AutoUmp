
This is when there's no object in there.
Is data moving from one core to another?

Clock ticks (@100Mhz) = 687511
Clock ticks (@100Mhz) = 6078106

-------

These are the numbers that we see from one camera or the other when we comment out  "ff1 <: bitImage1;" or vice versa. Basically, we're only seeing the issue when we're performing floodfill on two different pictures.
711178
687364



------
Need to make the lookup table


------ 
Need to do the math of the intersection code, accounting for tilt

------ 
Need to deal with the distortion that we're seeing.



--- 
Errors I've gotten: 
xrun: Program received signal ET_LOAD_STORE, Memory access exception.
      [Switching to tile[1] core[3] (dual issue)]
      0x000407e8 in getBitInByte () at ../src/cameras/detect_objects.xc:228

      228	    uint8_t val = ((byte & mask) >> bitLoc) & 1;

xrun: Program received signal ET_ECALL, ../src/cameras/detect_objects.xc:150:12: error: out of bounds array or pointer access
          while((objectArray[i].id != EMPTY_OBJECT_ID) && (i < length))
                 ^~~~~~~~~~~~~~
      .
      [Switching to tile[1] core[3] (dual issue)]
      0x00040b6c in computeCenters (length=255 '�', objectArray=<value optimized out>, centerArray=<value optimized out>) at ../src/cameras/detect_objects.xc:150
      150	    while((objectArray[i].id != EMPTY_OBJECT_ID) && (i < length))
