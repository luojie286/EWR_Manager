cmake_minimum_required(VERSION 3.16)

project(EWR_Manager VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Network Qml Quick Sql QuickControls2 QuickDialogs2 Svg)

qt_add_executable(EWR_Manager
    src/main.cpp
    src/DatabaseManager.cpp
    src/AnimeListModel.cpp
    src/ReviewListModel.cpp
    src/AnimeController.cpp
    src/BangumiClient.cpp
    resources.qrc
)

target_include_directories(EWR_Manager PRIVATE src)

target_link_libraries(EWR_Manager PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Network
    Qt6::Qml
    Qt6::Quick
    Qt6::Sql
    Qt6::QuickControls2
    Qt6::QuickDialogs2
    Qt6::Svg
)

if(WIN32)
    set_target_properties(EWR_Manager PROPERTIES WIN32_EXECUTABLE TRUE)
endif()

install(TARGETS EWR_Manager RUNTIME DESTINATION bin)
