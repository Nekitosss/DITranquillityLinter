import Darwin
import Foundation

/// :nodoc:
public enum Log {

    public enum Level: String, Codable {
        case errors
        case warnings
        case info
        case verbose
		
		var intValue: Int {
			switch self {
			case .errors: return 0
			case .warnings: return 1
			case .info: return 2
			case .verbose: return 3
			}
		}
    }

	static var level: Level { return LintOptions.shared.logLevel }

    public static func error(_ message: Any) {
        log(level: .errors, "error: \(message)")
        // to return error when running swift templates which is done in a different process
        if ProcessInfo().processName == "bin" {
            fputs("\(message)", stderr)
        }
    }

    public static func warning(_ message: Any) {
        log(level: .warnings, "warning: \(message)")
    }

    public static func verbose(_ message: Any) {
        log(level: .verbose, message)
    }

    public static func info(_ message: Any) {
        log(level: .info, message)
    }

    private static func log(level logLevel: Level, _ message: Any) {
        guard logLevel.intValue <= Log.level.intValue else { return }
        print(message)
    }

}

extension String: Error {}
