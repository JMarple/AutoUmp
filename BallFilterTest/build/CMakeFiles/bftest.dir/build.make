# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.5

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /usr/bin/cmake

# The command to remove a file.
RM = /usr/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/tbadams45/XMOS/autoump/BallFilterTest

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/tbadams45/XMOS/autoump/BallFilterTest/build

# Include any dependencies generated for this target.
include CMakeFiles/bftest.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/bftest.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/bftest.dir/flags.make

CMakeFiles/bftest.dir/src/main.cpp.o: CMakeFiles/bftest.dir/flags.make
CMakeFiles/bftest.dir/src/main.cpp.o: ../src/main.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/tbadams45/XMOS/autoump/BallFilterTest/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/bftest.dir/src/main.cpp.o"
	/usr/bin/c++   $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/bftest.dir/src/main.cpp.o -c /home/tbadams45/XMOS/autoump/BallFilterTest/src/main.cpp

CMakeFiles/bftest.dir/src/main.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/bftest.dir/src/main.cpp.i"
	/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/tbadams45/XMOS/autoump/BallFilterTest/src/main.cpp > CMakeFiles/bftest.dir/src/main.cpp.i

CMakeFiles/bftest.dir/src/main.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/bftest.dir/src/main.cpp.s"
	/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/tbadams45/XMOS/autoump/BallFilterTest/src/main.cpp -o CMakeFiles/bftest.dir/src/main.cpp.s

CMakeFiles/bftest.dir/src/main.cpp.o.requires:

.PHONY : CMakeFiles/bftest.dir/src/main.cpp.o.requires

CMakeFiles/bftest.dir/src/main.cpp.o.provides: CMakeFiles/bftest.dir/src/main.cpp.o.requires
	$(MAKE) -f CMakeFiles/bftest.dir/build.make CMakeFiles/bftest.dir/src/main.cpp.o.provides.build
.PHONY : CMakeFiles/bftest.dir/src/main.cpp.o.provides

CMakeFiles/bftest.dir/src/main.cpp.o.provides.build: CMakeFiles/bftest.dir/src/main.cpp.o


CMakeFiles/bftest.dir/src/algs.c.o: CMakeFiles/bftest.dir/flags.make
CMakeFiles/bftest.dir/src/algs.c.o: ../src/algs.c
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/tbadams45/XMOS/autoump/BallFilterTest/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Building C object CMakeFiles/bftest.dir/src/algs.c.o"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -o CMakeFiles/bftest.dir/src/algs.c.o   -c /home/tbadams45/XMOS/autoump/BallFilterTest/src/algs.c

CMakeFiles/bftest.dir/src/algs.c.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing C source to CMakeFiles/bftest.dir/src/algs.c.i"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -E /home/tbadams45/XMOS/autoump/BallFilterTest/src/algs.c > CMakeFiles/bftest.dir/src/algs.c.i

CMakeFiles/bftest.dir/src/algs.c.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling C source to assembly CMakeFiles/bftest.dir/src/algs.c.s"
	/usr/bin/cc  $(C_DEFINES) $(C_INCLUDES) $(C_FLAGS) -S /home/tbadams45/XMOS/autoump/BallFilterTest/src/algs.c -o CMakeFiles/bftest.dir/src/algs.c.s

CMakeFiles/bftest.dir/src/algs.c.o.requires:

.PHONY : CMakeFiles/bftest.dir/src/algs.c.o.requires

CMakeFiles/bftest.dir/src/algs.c.o.provides: CMakeFiles/bftest.dir/src/algs.c.o.requires
	$(MAKE) -f CMakeFiles/bftest.dir/build.make CMakeFiles/bftest.dir/src/algs.c.o.provides.build
.PHONY : CMakeFiles/bftest.dir/src/algs.c.o.provides

CMakeFiles/bftest.dir/src/algs.c.o.provides.build: CMakeFiles/bftest.dir/src/algs.c.o


# Object files for target bftest
bftest_OBJECTS = \
"CMakeFiles/bftest.dir/src/main.cpp.o" \
"CMakeFiles/bftest.dir/src/algs.c.o"

# External object files for target bftest
bftest_EXTERNAL_OBJECTS =

bftest: CMakeFiles/bftest.dir/src/main.cpp.o
bftest: CMakeFiles/bftest.dir/src/algs.c.o
bftest: CMakeFiles/bftest.dir/build.make
bftest: /usr/local/lib/libopencv_shape.so.3.2.0
bftest: /usr/local/lib/libopencv_stitching.so.3.2.0
bftest: /usr/local/lib/libopencv_superres.so.3.2.0
bftest: /usr/local/lib/libopencv_videostab.so.3.2.0
bftest: /usr/local/lib/libopencv_objdetect.so.3.2.0
bftest: /usr/local/lib/libopencv_calib3d.so.3.2.0
bftest: /usr/local/lib/libopencv_features2d.so.3.2.0
bftest: /usr/local/lib/libopencv_flann.so.3.2.0
bftest: /usr/local/lib/libopencv_highgui.so.3.2.0
bftest: /usr/local/lib/libopencv_ml.so.3.2.0
bftest: /usr/local/lib/libopencv_photo.so.3.2.0
bftest: /usr/local/lib/libopencv_video.so.3.2.0
bftest: /usr/local/lib/libopencv_videoio.so.3.2.0
bftest: /usr/local/lib/libopencv_imgcodecs.so.3.2.0
bftest: /usr/local/lib/libopencv_imgproc.so.3.2.0
bftest: /usr/local/lib/libopencv_core.so.3.2.0
bftest: CMakeFiles/bftest.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/tbadams45/XMOS/autoump/BallFilterTest/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_3) "Linking CXX executable bftest"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/bftest.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/bftest.dir/build: bftest

.PHONY : CMakeFiles/bftest.dir/build

CMakeFiles/bftest.dir/requires: CMakeFiles/bftest.dir/src/main.cpp.o.requires
CMakeFiles/bftest.dir/requires: CMakeFiles/bftest.dir/src/algs.c.o.requires

.PHONY : CMakeFiles/bftest.dir/requires

CMakeFiles/bftest.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/bftest.dir/cmake_clean.cmake
.PHONY : CMakeFiles/bftest.dir/clean

CMakeFiles/bftest.dir/depend:
	cd /home/tbadams45/XMOS/autoump/BallFilterTest/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/tbadams45/XMOS/autoump/BallFilterTest /home/tbadams45/XMOS/autoump/BallFilterTest /home/tbadams45/XMOS/autoump/BallFilterTest/build /home/tbadams45/XMOS/autoump/BallFilterTest/build /home/tbadams45/XMOS/autoump/BallFilterTest/build/CMakeFiles/bftest.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/bftest.dir/depend

