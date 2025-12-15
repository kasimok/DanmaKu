# CMakeLists.txt for DanmakuFactory Library
# Converts XML/JSON danmaku files to ASS subtitle format

cmake_minimum_required(VERSION 3.15)
project(DanmakuFactory
    VERSION 2.0.0
    LANGUAGES C
    DESCRIPTION "Danmaku to ASS subtitle converter library"
)

set(CMAKE_C_STANDARD 11)
set(CMAKE_C_STANDARD_REQUIRED ON)

# Options
option(DANMAKU_BUILD_SHARED "Build shared library" ON)
option(DANMAKU_BUILD_STATIC "Build static library" ON)
option(DANMAKU_BUILD_CLI "Build command-line executable" OFF)
option(DANMAKU_BUILD_FRAMEWORK "Build as macOS/iOS framework" OFF)

# Find PCRE2 (required for regex blacklist feature)
find_package(PkgConfig QUIET)
if(PkgConfig_FOUND)
    pkg_check_modules(PCRE2 QUIET libpcre2-8)
endif()

if(NOT PCRE2_FOUND)
    find_path(PCRE2_INCLUDE_DIRS pcre2.h
        HINTS
            ${PCRE2_ROOT}/include
            $ENV{PCRE2_ROOT}/include
            /usr/local/include
            /opt/homebrew/include
    )
    find_library(PCRE2_LIBRARIES
        NAMES pcre2-8 pcre2-8-static
        HINTS
            ${PCRE2_ROOT}/lib
            $ENV{PCRE2_ROOT}/lib
            /usr/local/lib
            /opt/homebrew/lib
    )
    if(PCRE2_INCLUDE_DIRS AND PCRE2_LIBRARIES)
        set(PCRE2_FOUND TRUE)
    endif()
endif()

if(NOT PCRE2_FOUND)
    message(FATAL_ERROR "PCRE2 library not found. Please install pcre2 or set PCRE2_ROOT.")
endif()

message(STATUS "PCRE2 include: ${PCRE2_INCLUDE_DIRS}")
message(STATUS "PCRE2 library: ${PCRE2_LIBRARIES}")

# Library source files (excluding main.c which is CLI only)
set(DANMAKU_LIB_SOURCES
    src/JsonFile.c
    src/XmlFile.c
    src/AssFile/AssFile.c
    src/AssFile/AssStringProcessing.c
    src/Config/Config.c
    src/List/DanmakuFactoryList.c
    src/String/DanmakuFactoryString.c
    src/TemplateFile/TemplateFile.c
)

# Public headers (exposed to users of the library)
# These are the clean public API headers with proper include paths for framework usage
set(DANMAKU_PUBLIC_HEADERS
    include/DanmakuFactory/DanmakuFactory.h
    include/DanmakuFactory/DanmakuDef.h
    include/DanmakuFactory/Status.h
    include/DanmakuFactory/Config.h
    include/DanmakuFactory/DanmakuFactoryList.h
    include/DanmakuFactory/AssFile.h
    include/DanmakuFactory/DanmakuFactoryString.h
)

# Private headers
set(DANMAKU_PRIVATE_HEADERS
    src/Define/CLIDef.h
    src/AssFile/AssStringProcessing.h
    src/TemplateFile/TemplateFile.h
)

# Common compile definitions and includes
function(configure_danmaku_target target)
    target_include_directories(${target}
        PUBLIC
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include/DanmakuFactory>
            $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/src>
            $<INSTALL_INTERFACE:include/DanmakuFactory>
        PRIVATE
            ${PCRE2_INCLUDE_DIRS}
    )
    if(PCRE2_LIBRARY_DIRS)
        target_link_directories(${target} PRIVATE ${PCRE2_LIBRARY_DIRS})
    endif()
    target_link_libraries(${target} PRIVATE ${PCRE2_LIBRARIES})

    # Platform-specific settings
    if(APPLE)
        target_compile_definitions(${target} PRIVATE __APPLE__)
    elseif(WIN32)
        target_compile_definitions(${target} PRIVATE _WIN32)
    endif()

    # Set public headers for framework builds
    set_target_properties(${target} PROPERTIES
        PUBLIC_HEADER "${DANMAKU_PUBLIC_HEADERS}"
        VERSION ${PROJECT_VERSION}
        SOVERSION ${PROJECT_VERSION_MAJOR}
    )
endfunction()

# Static library
if(DANMAKU_BUILD_STATIC)
    add_library(DanmakuFactory_static STATIC ${DANMAKU_LIB_SOURCES})
    configure_danmaku_target(DanmakuFactory_static)
    set_target_properties(DanmakuFactory_static PROPERTIES
        OUTPUT_NAME DanmakuFactory
        ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
    )
    add_library(DanmakuFactory::static ALIAS DanmakuFactory_static)
endif()

# Shared library
if(DANMAKU_BUILD_SHARED)
    add_library(DanmakuFactory_shared SHARED ${DANMAKU_LIB_SOURCES})
    configure_danmaku_target(DanmakuFactory_shared)
    set_target_properties(DanmakuFactory_shared PROPERTIES
        OUTPUT_NAME DanmakuFactory
        LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib
    )
    add_library(DanmakuFactory::shared ALIAS DanmakuFactory_shared)
endif()

# macOS/iOS Framework
if(DANMAKU_BUILD_FRAMEWORK AND APPLE)
    add_library(DanmakuFactory_framework SHARED ${DANMAKU_LIB_SOURCES})
    configure_danmaku_target(DanmakuFactory_framework)
    set_target_properties(DanmakuFactory_framework PROPERTIES
        FRAMEWORK TRUE
        FRAMEWORK_VERSION A
        MACOSX_FRAMEWORK_IDENTIFIER org.tikm.DanmakuFactory
        OUTPUT_NAME DanmakuFactory
        XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY ""
        XCODE_ATTRIBUTE_INSTALL_PATH "@rpath"
    )
    add_library(DanmakuFactory::framework ALIAS DanmakuFactory_framework)
endif()

# CLI executable (optional)
if(DANMAKU_BUILD_CLI)
    add_executable(DanmakuFactoryCLI src/main.c)
    target_include_directories(DanmakuFactoryCLI PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src
        ${PCRE2_INCLUDE_DIRS}
    )
    if(PCRE2_LIBRARY_DIRS)
        target_link_directories(DanmakuFactoryCLI PRIVATE ${PCRE2_LIBRARY_DIRS})
    endif()
    if(TARGET DanmakuFactory_static)
        target_link_libraries(DanmakuFactoryCLI PRIVATE DanmakuFactory_static ${PCRE2_LIBRARIES})
    else()
        target_link_libraries(DanmakuFactoryCLI PRIVATE DanmakuFactory_shared ${PCRE2_LIBRARIES})
    endif()
    set_target_properties(DanmakuFactoryCLI PROPERTIES
        OUTPUT_NAME DanmakuFactory
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin
    )
endif()

# Installation
include(GNUInstallDirs)

# Determine which library target to install
set(INSTALL_TARGETS)
if(TARGET DanmakuFactory_static)
    list(APPEND INSTALL_TARGETS DanmakuFactory_static)
endif()
if(TARGET DanmakuFactory_shared)
    list(APPEND INSTALL_TARGETS DanmakuFactory_shared)
endif()
if(TARGET DanmakuFactory_framework)
    list(APPEND INSTALL_TARGETS DanmakuFactory_framework)
endif()
if(TARGET DanmakuFactoryCLI)
    list(APPEND INSTALL_TARGETS DanmakuFactoryCLI)
endif()

install(TARGETS ${INSTALL_TARGETS}
    EXPORT DanmakuFactoryTargets
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    FRAMEWORK DESTINATION ${CMAKE_INSTALL_LIBDIR}
    PUBLIC_HEADER DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/DanmakuFactory
)

# Export targets for find_package support
install(EXPORT DanmakuFactoryTargets
    FILE DanmakuFactoryTargets.cmake
    NAMESPACE DanmakuFactory::
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/DanmakuFactory
)

# Generate config file
include(CMakePackageConfigHelpers)
configure_package_config_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/DanmakuFactoryConfig.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/DanmakuFactoryConfig.cmake
    INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/DanmakuFactory
)

write_basic_package_version_file(
    ${CMAKE_CURRENT_BINARY_DIR}/DanmakuFactoryConfigVersion.cmake
    VERSION ${PROJECT_VERSION}
    COMPATIBILITY SameMajorVersion
)

install(FILES
    ${CMAKE_CURRENT_BINARY_DIR}/DanmakuFactoryConfig.cmake
    ${CMAKE_CURRENT_BINARY_DIR}/DanmakuFactoryConfigVersion.cmake
    DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/DanmakuFactory
)

# Print configuration summary
message(STATUS "")
message(STATUS "DanmakuFactory ${PROJECT_VERSION} Configuration:")
message(STATUS "  Build shared library: ${DANMAKU_BUILD_SHARED}")
message(STATUS "  Build static library: ${DANMAKU_BUILD_STATIC}")
message(STATUS "  Build CLI executable: ${DANMAKU_BUILD_CLI}")
message(STATUS "  Build framework:      ${DANMAKU_BUILD_FRAMEWORK}")
message(STATUS "")
