#!/bin/bash

# won't work in the scripts folder as anticipated. put it in the parent directory.
x=0

for j in images/*/ 
do
	cd $j
	echo $PWD
	for i in `ls *.png | sort -V`
	do 
		mv $i $x.png
		x=$[$x+1]
	done
	x=0
	cd ..
	cd ..
done
