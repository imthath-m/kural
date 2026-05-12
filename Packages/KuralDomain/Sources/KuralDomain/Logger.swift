import Foundation

public enum Logger {
    public static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: "INFO", file: file, function: function, line: line)
    }

    public static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: "ERROR", file: file, function: function, line: line)
    }

    public static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: "DEBUG", file: file, function: function, line: line)
    }

    private static func log(_ message: String, level: String, file: String, function: String, line: Int) {
        let fileName = (file as NSString).lastPathComponent
        if level == "INFO" {
            print("[\(fileName):\(line)] \(function) - \(message)")
        } else {
            print("[\(fileName):\(line)] \(function) - [\(level)] \(message)")
        }
    }
}
