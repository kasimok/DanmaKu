#!/bin/bash
# Build script for DanmakuFactory library
# Usage: ./build.sh [platform] [build_type]
#   platform: macos, ios, ios-sim, all (default: macos)
#   build_type: Debug, Release (default: Release)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
PLATFORM="${1:-macos}"
BUILD_TYPE="${2:-Release}"

echo "=== DanmakuFactory Build Script ==="
echo "Platform: ${PLATFORM}"
echo "Build Type: ${BUILD_TYPE}"
echo ""

build_macos() {
    echo ">>> Building for macOS..."
    mkdir -p "${BUILD_DIR}/macos"
    cd "${BUILD_DIR}/macos"
    
    cmake ../.. \
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
        -DDANMAKU_BUILD_SHARED=ON \
        -DDANMAKU_BUILD_STATIC=ON \
        -DDANMAKU_BUILD_CLI=ON \
        -DDANMAKU_BUILD_FRAMEWORK=ON
    
    cmake --build . --config ${BUILD_TYPE} -j$(sysctl -n hw.ncpu)
    echo ">>> macOS build complete: ${BUILD_DIR}/macos"
}

build_ios() {
    echo ">>> Building for iOS (device)..."
    mkdir -p "${BUILD_DIR}/ios-device"
    cd "${BUILD_DIR}/ios-device"
    
    cmake ../.. \
        -G Xcode \
        -DCMAKE_TOOLCHAIN_FILE="${SCRIPT_DIR}/cmake/ios.toolchain.cmake" \
        -DPLATFORM=OS64 \
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
        -DDANMAKU_BUILD_SHARED=OFF \
        -DDANMAKU_BUILD_STATIC=ON \
        -DDANMAKU_BUILD_CLI=OFF \
        -DDANMAKU_BUILD_FRAMEWORK=OFF
    
    cmake --build . --config ${BUILD_TYPE} -j$(sysctl -n hw.ncpu)
    echo ">>> iOS device build complete: ${BUILD_DIR}/ios-device"
}

build_ios_simulator() {
    echo ">>> Building for iOS Simulator..."
    mkdir -p "${BUILD_DIR}/ios-simulator"
    cd "${BUILD_DIR}/ios-simulator"
    
    cmake ../.. \
        -G Xcode \
        -DCMAKE_TOOLCHAIN_FILE="${SCRIPT_DIR}/cmake/ios.toolchain.cmake" \
        -DPLATFORM=SIMULATOR64 \
        -DCMAKE_BUILD_TYPE=${BUILD_TYPE} \
        -DDANMAKU_BUILD_SHARED=OFF \
        -DDANMAKU_BUILD_STATIC=ON \
        -DDANMAKU_BUILD_CLI=OFF \
        -DDANMAKU_BUILD_FRAMEWORK=OFF
    
    cmake --build . --config ${BUILD_TYPE} -j$(sysctl -n hw.ncpu)
    echo ">>> iOS simulator build complete: ${BUILD_DIR}/ios-simulator"
}

create_xcframework() {
    echo ">>> Creating XCFramework..."
    
    FRAMEWORK_NAME="DanmakuFactory"
    OUTPUT_DIR="${BUILD_DIR}/xcframework"
    mkdir -p "${OUTPUT_DIR}"
    
    # Create XCFramework from static libraries
    xcodebuild -create-xcframework \
        -library "${BUILD_DIR}/ios-device/lib/libDanmakuFactory.a" \
        -headers "${SCRIPT_DIR}/src" \
        -library "${BUILD_DIR}/ios-simulator/lib/libDanmakuFactory.a" \
        -headers "${SCRIPT_DIR}/src" \
        -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
    
    echo ">>> XCFramework created: ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
}

case "${PLATFORM}" in
    macos)
        build_macos
        ;;
    ios)
        build_ios
        ;;
    ios-sim)
        build_ios_simulator
        ;;
    ios-all)
        build_ios
        build_ios_simulator
        create_xcframework
        ;;
    all)
        build_macos
        build_ios
        build_ios_simulator
        create_xcframework
        ;;
    clean)
        echo ">>> Cleaning build directory..."
        rm -rf "${BUILD_DIR}"
        echo ">>> Clean complete"
        ;;
    *)
        echo "Unknown platform: ${PLATFORM}"
        echo "Usage: $0 [macos|ios|ios-sim|ios-all|all|clean] [Debug|Release]"
        exit 1
        ;;
esac

echo ""
echo "=== Build Complete ==="
