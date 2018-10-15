import Darwin
import Foundation

/// :nodoc:
enum Log {

    enum Level: Int {
        case errors
        case warnings
        case info
        case verbose
    }

    static var level: Level = .warnings

    static func error(_ message: Any) {
        log(level: .errors, "error: \(message)")
        // to return error when running swift templates which is done in a different process
        if ProcessInfo().processName == "bin" {
            fputs("\(message)", stderr)
        }
    }

    static func warning(_ message: Any) {
        log(level: .warnings, "warning: \(message)")
    }

    static func verbose(_ message: Any) {
        log(level: .verbose, message)
    }

    static func info(_ message: Any) {
        log(level: .info, message)
    }

    private static func log(level logLevel: Level, _ message: Any) {
        guard logLevel.rawValue <= Log.level.rawValue else { return }
        print(message)
    }

}

extension String: Error {}
