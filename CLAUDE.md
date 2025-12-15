# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

DanmakuFactory is a C library for converting danmaku (bullet comment) files between formats (XML, JSON, ASS subtitles). It supports Bilibili-style danmaku including special/animated danmaku, and can be used as a library for iOS/macOS/tvOS apps or as a CLI tool.

## Build Commands

### Prerequisites
```bash
brew install pcre2 cmake
```

### Build with Script
```bash
./build.sh macos      # Build for macOS (shared + static + CLI + framework)
./build.sh ios        # Build for iOS device (static library)
./build.sh ios-sim    # Build for iOS simulator
./build.sh ios-all    # Build iOS + create XCFramework
./build.sh all        # Build everything
./build.sh clean      # Clean build directory
```

### Build Manually (macOS with CLI)
```bash
mkdir build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DDANMAKU_BUILD_CLI=ON
cmake --build . -j$(sysctl -n hw.ncpu)
```

### CMake Options
- `DANMAKU_BUILD_SHARED` (ON) - Build shared/dynamic library
- `DANMAKU_BUILD_STATIC` (ON) - Build static library
- `DANMAKU_BUILD_CLI` (OFF) - Build command-line executable
- `DANMAKU_BUILD_FRAMEWORK` (OFF) - Build macOS/iOS framework

## Architecture

### Core Components (src/)
- **CDanmakuFactory.h** - Main public header, includes all library APIs
- **XmlFile.c** - XML danmaku parser (Bilibili format)
- **JsonFile.c** - JSON danmaku parser
- **AssFile/** - ASS subtitle generation and parsing
- **Config/** - Configuration management (resolution, font, opacity, blocking rules)
- **List/** - Danmaku linked list data structure
- **String/** - String utilities
- **TemplateFile/** - Custom template support
- **Define/** - Type definitions (DANMAKU struct, STATUS, CLIDef)

### Data Flow
1. Read input file → `readXml()` or `readJson()` → builds DANMAKU linked list
2. Process → `sortList()`, `blockByType()`, `normFontSize()`
3. Write output → `writeAss()`, `writeXml()`, or `writeJson()`

### Key Types
- `DANMAKU` - Linked list node containing danmaku data (time, text, color, type, position)
- `CONFIG` - Output configuration (resolution, font settings, display area, blocking mode)
- `STATUS` - Statistics tracking (counts by type, blocked count)

## Swift Integration

See `examples/swift/DanmakuConverter.swift` for a complete Swift wrapper. Use the bridging header at `examples/swift/DanmakuFactory-Bridging-Header.h`.

## File Format Support
- **.ass** - Read/Write (normal + special danmaku)
- **.xml** - Read/Write (normal + special danmaku)
- **.json** - Read/Write (normal danmaku only)
