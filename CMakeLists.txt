cmake_minimum_required(VERSION 3.16)

project(AnimeManager VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Sql QuickControls2 QuickDialogs2)

qt_add_executable(AnimeManager
    src/main.cpp
    src/DatabaseManager.cpp
    src/AnimeListModel.cpp
    src/ReviewListModel.cpp
    src/AnimeController.cpp
    resources.qrc
)

target_include_directories(AnimeManager PRIVATE src)

target_link_libraries(AnimeManager PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Sql
    Qt6::QuickControls2
    Qt6::QuickDialogs2
)

if(WIN32)
    set_target_properties(AnimeManager PROPERTIES WIN32_EXECUTABLE TRUE)
endif()

install(TARGETS AnimeManager RUNTIME DESTINATION bin)
