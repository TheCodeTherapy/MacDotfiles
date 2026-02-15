cmake_minimum_required(VERSION 3.16)

get_filename_component(PROJECT_NAME ${CMAKE_SOURCE_DIR} NAME)
project(${PROJECT_NAME} LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

include(FetchContent)

FetchContent_Declare(
    raylib
    GIT_REPOSITORY https://github.com/raysan5/raylib.git
    GIT_TAG 5.5
)
FetchContent_MakeAvailable(raylib)

if (APPLE)
    # Add Objective-C++ file for macOS screen capture
    add_executable(${PROJECT_NAME} src/main.cpp src/macos_capture.mm)
    target_link_libraries(${PROJECT_NAME} PRIVATE raylib "-framework OpenGL" "-framework Cocoa" "-framework IOKit" "-framework CoreVideo" "-framework ScreenCaptureKit" "-framework CoreGraphics" "-framework Foundation")
else()
    add_executable(${PROJECT_NAME} src/main.cpp)
    target_link_libraries(${PROJECT_NAME} PRIVATE raylib m pthread dl GL X11)
endif()
