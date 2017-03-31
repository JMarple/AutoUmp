#!/bin/bash

# ./aump ...../images 01

# /bin/bash /home/tbadams45/sdp17/removeResultsFolders.sh $test_name

# make this YOUR absolute path to the BallFilterTest/
# bf_fp=/home/jmarple/XMOS/autoump/BallFilterTest/
bf_fp=/home/tbadams45/XMOS/autoump/BallFilterTest
echo "$bf_fp"
exe_fp=$bf_fp/build/bftest

echo "$exe_fp"

# remove/replace results folders

for d in $bf_fp/images/*/ # for each folder that contains images to operate on
do
	cd "$d"
	rm -r computed
	mkdir computed
	#export NUM_PNG=($(ls -d *.png | wc -l))
	export TOP_DIR="$(dirname $PWD)"
	export TEST_DIR=`basename $PWD`
	echo "-------- Test Number: $TEST_DIR --------"
	$exe_fp $TOP_DIR $TEST_DIR
	
	cd "$TOP_DIR" # going back to the top 
done 
