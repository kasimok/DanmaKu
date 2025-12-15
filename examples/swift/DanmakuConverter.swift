import Foundation

/// Swift wrapper for DanmakuFactory C library
/// Converts XML/JSON danmaku files to ASS subtitle format
public class DanmakuConverter {
    
    /// Default configuration for ASS output
    public struct Configuration {
        public var resolutionWidth: Int32 = 1920
        public var resolutionHeight: Int32 = 1080
        public var displayArea: Float = 1.0
        public var scrollArea: Float = 1.0
        public var scrollTime: Float = 12.0
        public var fixTime: Float = 5.0
        public var density: Int32 = 0
        public var lineSpacing: Int32 = 0
        public var fontSize: Int32 = 38
        public var fontName: String = "Microsoft YaHei"
        public var opacity: Int32 = 180
        public var outline: Float = 0
        public var shadow: Float = 1
        public var bold: Bool = false
        public var blockMode: Int32 = 0
        
        public init() {}
    }
    
    /// Convert XML danmaku file to ASS subtitle
    /// - Parameters:
    ///   - inputPath: Path to input XML file
    ///   - outputPath: Path for output ASS file
    ///   - configuration: Optional configuration (uses defaults if nil)
    ///   - timeShift: Time offset in seconds (default: 0)
    /// - Returns: Result with success or error
    public static func convertXMLToASS(
        inputPath: String,
        outputPath: String,
        configuration: Configuration? = nil,
        timeShift: Float = 0.0
    ) -> Result<Int, DanmakuError> {
        
        let config = configuration ?? Configuration()
        
        // Create C config struct
        var cConfig = createCConfig(from: config)
        
        // Status for tracking progress
        var status = STATUS()
        status.totalNum = 0
        
        // Danmaku linked list head
        var danmakuHead: UnsafeMutablePointer<DANMAKU>? = nil
        
        // Read XML file
        let readResult = inputPath.withCString { inputCStr in
            readXml(inputCStr, &danmakuHead, "a", timeShift, &status)
        }
        
        guard readResult == 0 else {
            return .failure(.readError(code: readResult))
        }
        
        guard danmakuHead != nil else {
            return .failure(.emptyFile)
        }
        
        // Sort danmaku by time
        let sortResult = sortList(&danmakuHead, nil)
        guard sortResult == 0 else {
            freeList(danmakuHead)
            return .failure(.sortError(code: sortResult))
        }
        
        // Apply blocking rules
        blockByType(danmakuHead, config.blockMode, nil, 0)
        
        // Normalize font size
        normFontSize(danmakuHead, cConfig)
        
        // Write ASS file
        let writeResult = outputPath.withCString { outputCStr in
            writeAss(outputCStr, danmakuHead, cConfig, nil, nil)
        }
        
        // Free memory
        freeList(danmakuHead)
        
        guard writeResult == 0 else {
            return .failure(.writeError(code: writeResult))
        }
        
        return .success(Int(status.totalNum))
    }
    
    /// Convert JSON danmaku file to ASS subtitle
    public static func convertJSONToASS(
        inputPath: String,
        outputPath: String,
        configuration: Configuration? = nil,
        timeShift: Float = 0.0
    ) -> Result<Int, DanmakuError> {
        
        let config = configuration ?? Configuration()
        var cConfig = createCConfig(from: config)
        var status = STATUS()
        status.totalNum = 0
        var danmakuHead: UnsafeMutablePointer<DANMAKU>? = nil
        
        let readResult = inputPath.withCString { inputCStr in
            readJson(inputCStr, &danmakuHead, "a", timeShift, &status)
        }
        
        guard readResult == 0 else {
            return .failure(.readError(code: readResult))
        }
        
        guard danmakuHead != nil else {
            return .failure(.emptyFile)
        }
        
        let sortResult = sortList(&danmakuHead, nil)
        guard sortResult == 0 else {
            freeList(danmakuHead)
            return .failure(.sortError(code: sortResult))
        }
        
        blockByType(danmakuHead, config.blockMode, nil, 0)
        normFontSize(danmakuHead, cConfig)
        
        let writeResult = outputPath.withCString { outputCStr in
            writeAss(outputCStr, danmakuHead, cConfig, nil, nil)
        }
        
        freeList(danmakuHead)
        
        guard writeResult == 0 else {
            return .failure(.writeError(code: writeResult))
        }
        
        return .success(Int(status.totalNum))
    }
    
    // MARK: - Private Helpers
    
    private static func createCConfig(from config: Configuration) -> CONFIG {
        var cConfig = CONFIG()
        
        cConfig.resolution.x = config.resolutionWidth
        cConfig.resolution.y = config.resolutionHeight
        cConfig.displayarea = config.displayArea
        cConfig.scrollarea = config.scrollArea
        cConfig.scrolltime = config.scrollTime
        cConfig.fixtime = config.fixTime
        cConfig.density = config.density
        cConfig.lineSpacing = config.lineSpacing
        cConfig.fontsize = config.fontSize
        cConfig.opacity = config.opacity
        cConfig.outline = config.outline
        cConfig.shadow = config.shadow
        cConfig.bold = config.bold ? 1 : 0
        cConfig.blockmode = config.blockMode
        cConfig.saveBlockedPart = 1
        cConfig.showUserNames = 0
        cConfig.showMsgBox = 1
        
        // Copy font name
        let fontNameBytes = config.fontName.utf8CString
        withUnsafeMutableBytes(of: &cConfig.fontname) { buffer in
            let count = min(fontNameBytes.count, buffer.count)
            for i in 0..<count {
                buffer[i] = UInt8(bitPattern: fontNameBytes[i])
            }
        }
        
        return cConfig
    }
}

// MARK: - Error Types

public enum DanmakuError: Error, LocalizedError {
    case readError(code: Int32)
    case writeError(code: Int32)
    case sortError(code: Int32)
    case emptyFile
    case invalidConfiguration
    
    public var errorDescription: String? {
        switch self {
        case .readError(let code):
            return "Failed to read danmaku file (error code: \(code))"
        case .writeError(let code):
            return "Failed to write ASS file (error code: \(code))"
        case .sortError(let code):
            return "Failed to sort danmaku (error code: \(code))"
        case .emptyFile:
            return "Input file contains no danmaku"
        case .invalidConfiguration:
            return "Invalid configuration"
        }
    }
}
