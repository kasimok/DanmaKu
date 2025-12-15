# DanmakuFactory CMake Build

This project has been converted to CMake for building as a library (suitable for iOS/macOS).

## Quick Build

### macOS (with CLI)
```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DDANMAKU_BUILD_CLI=ON
cmake --build . -j$(sysctl -n hw.ncpu)
```

### macOS Library Only
```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release
cmake --build . -j$(sysctl -n hw.ncpu)
```

### iOS Device (Static Library)
```bash
mkdir build-ios && cd build-ios
cmake .. -G Xcode \
    -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake \
    -DPLATFORM=OS64 \
    -DDANMAKU_BUILD_SHARED=OFF \
    -DDANMAKU_BUILD_STATIC=ON
cmake --build . --config Release
```

### iOS Simulator
```bash
mkdir build-ios-sim && cd build-ios-sim
cmake .. -G Xcode \
    -DCMAKE_TOOLCHAIN_FILE=../cmake/ios.toolchain.cmake \
    -DPLATFORM=SIMULATOR64 \
    -DDANMAKU_BUILD_SHARED=OFF \
    -DDANMAKU_BUILD_STATIC=ON
cmake --build . --config Release
```

## Build Script
A convenience script is provided:
```bash
./build.sh macos      # Build for macOS
./build.sh ios        # Build for iOS device
./build.sh ios-sim    # Build for iOS simulator
./build.sh ios-all    # Build for iOS + create XCFramework
./build.sh all        # Build everything
./build.sh clean      # Clean build directory
```

## CMake Options

| Option | Default | Description |
|--------|---------|-------------|
| `DANMAKU_BUILD_SHARED` | ON | Build shared/dynamic library |
| `DANMAKU_BUILD_STATIC` | ON | Build static library |
| `DANMAKU_BUILD_CLI` | OFF | Build command-line executable |
| `DANMAKU_BUILD_FRAMEWORK` | OFF | Build macOS/iOS framework |

## Dependencies

- **PCRE2**: Required for regex blacklist feature

Install on macOS:
```bash
brew install pcre2
```

Or specify custom location:
```bash
cmake .. -DPCRE2_ROOT=/path/to/pcre2
```

## Using in Swift/Xcode

### 1. Add the static library to your Xcode project
- Add `libDanmakuFactory.a` to your target
- Add `libpcre2-8.a` (or link dynamically)

### 2. Create a bridging header
```c
// DanmakuFactory-Bridging-Header.h
#include "CDanmakuFactory.h"
```

### 3. Add header search paths
Add the `src/` directory to your Header Search Paths in Xcode.

### 4. Use from Swift
See `examples/swift/` for example Swift wrapper code.

## Library API

The main functions you'll use for XML → ASS conversion:

```c
// Read XML danmaku file
int readXml(const char *ipFile, DANMAKU **head, const char *mode, 
            float timeShift, STATUS *status);

// Sort danmaku by time
int sortList(DANMAKU **listHead, STATUS *status);

// Block certain types of danmaku
void blockByType(DANMAKU *head, int mode, char **keyStrings, BOOL regexEnabled);

// Normalize font sizes
void normFontSize(DANMAKU *head, CONFIG config);

// Write ASS subtitle file
int writeAss(const char *fileName, DANMAKU *head, CONFIG config,
             const ASSFILE *subPart, STATUS *status);

// Free danmaku list memory
void freeList(DANMAKU *listHead);
```
