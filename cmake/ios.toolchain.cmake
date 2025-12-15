# iOS Toolchain for CMake
# Usage: cmake -DCMAKE_TOOLCHAIN_FILE=cmake/ios.toolchain.cmake -DPLATFORM=OS64 ..

set(CMAKE_SYSTEM_NAME iOS)
set(CMAKE_OSX_DEPLOYMENT_TARGET "12.0" CACHE STRING "Minimum iOS version")

# Platform options: OS64, SIMULATOR64, OS64COMBINED
if(NOT DEFINED PLATFORM)
    set(PLATFORM "OS64" CACHE STRING "Target platform")
endif()

if(PLATFORM STREQUAL "OS64")
    set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE STRING "Build architecture")
    set(CMAKE_OSX_SYSROOT "iphoneos" CACHE STRING "SDK")
elseif(PLATFORM STREQUAL "SIMULATOR64")
    set(CMAKE_OSX_ARCHITECTURES "x86_64;arm64" CACHE STRING "Build architecture")
    set(CMAKE_OSX_SYSROOT "iphonesimulator" CACHE STRING "SDK")
elseif(PLATFORM STREQUAL "OS64COMBINED")
    # For building universal frameworks (device + simulator)
    set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE STRING "Build architecture")
    set(CMAKE_OSX_SYSROOT "iphoneos" CACHE STRING "SDK")
endif()

# Ensure we use the correct compilers
set(CMAKE_C_COMPILER_WORKS TRUE)
set(CMAKE_CXX_COMPILER_WORKS TRUE)

# Skip unsupported flags
set(CMAKE_C_FLAGS_INIT "-fembed-bitcode")
set(CMAKE_CXX_FLAGS_INIT "-fembed-bitcode")

# Skip programs that don't work on iOS
set(CMAKE_MACOSX_BUNDLE YES)
set(CMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH NO)
