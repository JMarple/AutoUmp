cmake_minimum_required(VERSION 2.8)
SET(CMAKE_CXX_FLAGS "-std=c++11")
add_compile_options(-std=c++11)
project (auview)
find_package (OpenCV REQUIRED)
add_executable (auview src/main.cpp src/serial/rs232.c)
target_link_libraries (auview ${OpenCV_LIBS})
