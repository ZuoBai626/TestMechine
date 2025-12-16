cmake_minimum_required(VERSION 3.16)

project(Test_Mechine VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOMOC ON)


find_package(Qt6 REQUIRED COMPONENTS Quick Charts Core SerialBus)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)
find_package(Qt6 REQUIRED COMPONENTS Core)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(Test_Mechine
    main.cpp
)

qt_add_qml_module(Test_Mechine
    URI Test_Mechine
    QML_FILES
        Main.qml
        SOURCES threadmanager.h threadmanager.cpp
        SOURCES modbuscontrol.h modbuscontrol.cpp
        QML_FILES SystemParameters.qml
        SOURCES readwritecsv.h readwritecsv.cpp
        QML_FILES A_TextInput.qml
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
# If you are developing for iOS or macOS you should consider setting an
# explicit, fixed bundle identifier manually though.
set_target_properties(Test_Mechine PROPERTIES
#    MACOSX_BUNDLE_GUI_IDENTIFIER com.example.Test_Mechine
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(Test_Mechine
    PRIVATE Qt6::Quick
    PRIVATE Qt6::Charts
    PRIVATE Qt6::Core
    PRIVATE Qt6::SerialBus
)
target_link_libraries(Test_Mechine PRIVATE Qt6::Core)
target_link_libraries(Test_Mechine PRIVATE Qt6::Core)
target_link_libraries(Test_Mechine PRIVATE Qt6::Core)

include(GNUInstallDirs)
install(TARGETS Test_Mechine
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)


