cmake_minimum_required(VERSION 3.15)

add_subdirectory(88lib)

# The player decides itself which formats to build from the USE_* switches;
# with none of them enabled it creates no targets.
if(${CMAKE_PROJECT_NAME}_BUILD_JUCEPLUGIN)
	add_subdirectory(88emuplayer)
endif()
