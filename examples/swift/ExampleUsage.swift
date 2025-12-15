import Foundation

// Example usage of DanmakuConverter

func exampleUsage() {
    // Basic conversion with default settings
    let inputXML = "/path/to/danmaku.xml"
    let outputASS = "/path/to/output.ass"
    
    let result = DanmakuConverter.convertXMLToASS(
        inputPath: inputXML,
        outputPath: outputASS
    )
    
    switch result {
    case .success(let count):
        print("Successfully converted \(count) danmaku to ASS")
    case .failure(let error):
        print("Conversion failed: \(error.localizedDescription)")
    }
}

func exampleWithCustomConfig() {
    // Conversion with custom configuration
    var config = DanmakuConverter.Configuration()
    config.resolutionWidth = 1280
    config.resolutionHeight = 720
    config.fontSize = 28
    config.fontName = "PingFang SC"
    config.opacity = 200
    config.scrollTime = 10.0
    
    let result = DanmakuConverter.convertXMLToASS(
        inputPath: "/path/to/danmaku.xml",
        outputPath: "/path/to/output.ass",
        configuration: config,
        timeShift: 2.5  // Shift all danmaku by 2.5 seconds
    )
    
    switch result {
    case .success(let count):
        print("Converted \(count) danmaku with custom settings")
    case .failure(let error):
        print("Error: \(error)")
    }
}

func exampleJSONConversion() {
    // Convert JSON format (Bilibili newer format)
    let result = DanmakuConverter.convertJSONToASS(
        inputPath: "/path/to/danmaku.json",
        outputPath: "/path/to/output.ass"
    )
    
    switch result {
    case .success(let count):
        print("Converted \(count) danmaku from JSON")
    case .failure(let error):
        print("Error: \(error)")
    }
}

// For iOS apps, you might use it like this:
func convertInDocumentsDirectory() {
    let fileManager = FileManager.default
    let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    let inputURL = documentsURL.appendingPathComponent("danmaku.xml")
    let outputURL = documentsURL.appendingPathComponent("subtitles.ass")
    
    let result = DanmakuConverter.convertXMLToASS(
        inputPath: inputURL.path,
        outputPath: outputURL.path
    )
    
    switch result {
    case .success(let count):
        print("Created ASS file at: \(outputURL.path)")
        print("Total danmaku: \(count)")
    case .failure(let error):
        print("Failed: \(error.localizedDescription)")
    }
}
