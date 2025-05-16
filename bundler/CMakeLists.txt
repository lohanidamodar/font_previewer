cmake_minimum_required(VERSION 3.10)
project(FlutterBundler)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set output directory
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)

# Include directories
include_directories(${CMAKE_SOURCE_DIR})

# Add resource compiler file
configure_file(resources.rc.in ${CMAKE_BINARY_DIR}/resources.rc @ONLY)

# Add source files
add_executable(FlutterBundler 
    main.cpp
    resource_extractor.cpp
    ${CMAKE_BINARY_DIR}/resources.rc
)

# Set output name
set_target_properties(FlutterBundler PROPERTIES OUTPUT_NAME "FontPreviewer")

# Link libraries
target_link_libraries(FlutterBundler PRIVATE)

# Copy release files for testing
add_custom_command(TARGET FlutterBundler POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${CMAKE_BINARY_DIR}/test_extraction"
)
