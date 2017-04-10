cmake_minimum_required(VERSION 2.8)
SET(CMAKE_CXX_FLAGS "-std=c++11")
add_compile_options(-std=c++11)
project(bftest)
find_package(OpenCV REQUIRED)
add_executable(bftest src/main.cpp src/algs.c src/detect_objects.c src/queue.c src/object_tracker.c src/hungarian.c src/simple_object_tracker.c)
target_link_libraries(bftest ${OpenCV_LIBS})
target_link_libraries(bftest m)
#add_executable(testmain src/testmain.c src/object_tracker.c src/hungarian.c)
#target_link_libraries(testmain m)

add_executable(denoisemain src/denoisemain.c src/algs.c)

