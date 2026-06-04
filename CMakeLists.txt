cmake_minimum_required(VERSION 3.16)

project(EWR_Manager VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Network Qml Quick Sql QuickControls2 QuickDialogs2 Svg Multimedia)

qt_add_executable(EWR_Manager
    src/main.cpp
    src/DatabaseManager.cpp
    src/AnimeListModel.cpp
    src/ReviewListModel.cpp
    src/AnimeController.cpp
    src/GameListModel.cpp
    src/GameReviewListModel.cpp
    src/GameController.cpp
    src/BangumiClient.cpp
    src/RawgClient.cpp
    src/MusicController.cpp
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
    Qt6::Multimedia
)

if(WIN32)
    set_target_properties(EWR_Manager PROPERTIES WIN32_EXECUTABLE TRUE)

    get_target_property(_qt_core_location Qt6::Core IMPORTED_LOCATION_RELEASE)
    if(NOT _qt_core_location)
        get_target_property(_qt_core_location Qt6::Core IMPORTED_LOCATION)
    endif()
    get_filename_component(QT6_BIN_DIR "${_qt_core_location}" DIRECTORY)
    get_filename_component(QT6_INSTALL_PREFIX "${QT6_BIN_DIR}/.." ABSOLUTE)
    find_program(WINDEPLOYQT_EXECUTABLE windeployqt HINTS "${QT6_BIN_DIR}")

    if(WINDEPLOYQT_EXECUTABLE)
        get_filename_component(MINGW_BIN_DIR "${CMAKE_CXX_COMPILER}" DIRECTORY)
        add_custom_command(TARGET EWR_Manager POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:EWR_Manager>/platforms"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${QT6_INSTALL_PREFIX}/plugins/platforms/qwindows.dll"
                "$<TARGET_FILE_DIR:EWR_Manager>/platforms/qwindows.dll"
            COMMAND ${CMAKE_COMMAND} -E env
                "PATH=${QT6_BIN_DIR};${MINGW_BIN_DIR}"
                "QT_PLUGIN_PATH=${QT6_INSTALL_PREFIX}/plugins"
                "${WINDEPLOYQT_EXECUTABLE}"
                --release
                --no-translations
                --qmldir "${CMAKE_SOURCE_DIR}/qml"
                "$<TARGET_FILE:EWR_Manager>"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${MINGW_BIN_DIR}/libgcc_s_seh-1.dll"
                "$<TARGET_FILE_DIR:EWR_Manager>/libgcc_s_seh-1.dll"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${MINGW_BIN_DIR}/libstdc++-6.dll"
                "$<TARGET_FILE_DIR:EWR_Manager>/libstdc++-6.dll"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${MINGW_BIN_DIR}/libwinpthread-1.dll"
                "$<TARGET_FILE_DIR:EWR_Manager>/libwinpthread-1.dll"
            COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:EWR_Manager>/sqldrivers"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${QT6_INSTALL_PREFIX}/plugins/sqldrivers/qsqlite.dll"
                "$<TARGET_FILE_DIR:EWR_Manager>/sqldrivers/qsqlite.dll"
            COMMAND ${CMAKE_COMMAND} -E make_directory "$<TARGET_FILE_DIR:EWR_Manager>/imageformats"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${QT6_INSTALL_PREFIX}/plugins/imageformats/qjpeg.dll"
                "$<TARGET_FILE_DIR:EWR_Manager>/imageformats/qjpeg.dll"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${QT6_INSTALL_PREFIX}/plugins/imageformats/qgif.dll"
                "$<TARGET_FILE_DIR:EWR_Manager>/imageformats/qgif.dll"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${QT6_INSTALL_PREFIX}/plugins/imageformats/qsvg.dll"
                "$<TARGET_FILE_DIR:EWR_Manager>/imageformats/qsvg.dll"
            COMMENT "Deploying Qt runtime next to EWR_Manager.exe"
        )
    endif()
endif()

install(TARGETS EWR_Manager RUNTIME DESTINATION bin)
