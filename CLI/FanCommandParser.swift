import Foundation

enum FanCommandParser {
    static let usage = """

Control all fans:
  min                           Set all fans to minimum
  max                           Set all fans to maximum
  -a, auto                      Set all fans to auto
  [speed]                       Set all fans to [speed, example: 4000, 4k, 1.6k]
  
Control a specific fan:
  -l, list                      List all fans
  -id [fan id] min              Set one fan to minimum
  -id [fan id] max              Set one fan to maximum
  -id [fan id] -a, auto         Set one fan to auto
  -id [fan id] [speed]          Set one fan to [speed]

Timers:
  timer [speed] [duration]      Run a timer for all fans, then return to auto
  -id [fan id] timer [speed] [duration]
                               Run a timer for one fan, then return to auto
  Duration: 30m, 1h, 1h30m, or 60s (maximum 23h59m)

Other:
  -h, --help                    Show this help
  -r, --report                  Print support report
  -v, --version                 Print app version
  -d, --device                  Print device model

"""
    
    static func parse(arguments: [String]) throws -> FanCommand {
        guard let firstArgument = arguments.first else {
            return .help
        }
        
        switch firstArgument {
        case "-h", "--help", "help":
            return .help
            
        case "-v", "--version":
            guard arguments.count == 1 else {
                throw FanCLIError.usage("Version does not accept extra arguments")
            }
            
            return .version
            
        case "-d", "--device":
            guard arguments.count == 1 else {
                throw FanCLIError.usage("Device does not accept extra arguments")
            }
            
            return .device
            
        case "-r", "--report":
            guard arguments.count == 1 else {
                throw FanCLIError.usage("Report does not accept extra arguments")
            }
            
            return .report
            
        case "list", "-l":
            guard arguments.count == 1 else {
                throw FanCLIError.usage("List does not accept extra arguments")
            }
            
            return .list
            
        case "min":
            guard arguments.count == 1 else {
                throw FanCLIError.usage("Min does not accept extra arguments")
            }
            
            return .minAll
            
        case "max":
            guard arguments.count == 1 else {
                throw FanCLIError.usage("Max does not accept extra arguments")
            }
            
            return .maxAll
            
        case "auto", "-a":
            guard arguments.count == 1 else {
                throw FanCLIError.usage("Auto does not accept extra arguments")
            }
            
            return .autoAll
            
        case "-id", "--id":
            return try parseFanScopedCommand(arguments)

        case "timer":
            return try parseTimerCommand(Array(arguments.dropFirst()), userFacingFanID: nil)
            
        default:
            if let rpm = parseRPM(firstArgument) {
                guard arguments.count == 1 else {
                    throw FanCLIError.usage("RPM does not accept extra arguments")
                }
                
                return .setAllRPM(rpm)
            }
            
            throw FanCLIError.usage("Unknown command \(firstArgument)")
        }
    }
    
    private static func parseFanScopedCommand(_ arguments: [String]) throws -> FanCommand {
        guard arguments.count >= 3 else {
            throw FanCLIError.usage("Fan commands require an id and a value")
        }
        
        guard let fanID = parsePositiveInteger(arguments[1]) else {
            throw FanCLIError.usage("Fan id must be a positive integer")
        }

        if arguments[2] == "timer" {
            return try parseTimerCommand(Array(arguments.dropFirst(3)), userFacingFanID: fanID)
        }

        guard arguments.count == 3 else {
            throw FanCLIError.usage("Fan commands require an id and a value")
        }
        
        if isAutoAlias(arguments[2]) {
            return .autoFan(fanID)
        }
        
        if arguments[2] == "min" {
            return .minFan(fanID)
        }
        
        if arguments[2] == "max" {
            return .maxFan(fanID)
        }
        
        guard let rpm = parseRPM(arguments[2]) else {
            throw FanCLIError.usage("RPM must be min, max, auto, -a, a positive integer, or use k suffix like 1.5k")
        }
        
        return .setFanRPM(fanID, rpm)
    }

    private static func parseTimerCommand(_ arguments: [String], userFacingFanID: Int?) throws -> FanCommand {
        guard arguments.count == 2 else {
            throw FanCLIError.usage("Timer requires a speed and duration, for example: timer 4k 30m")
        }

        guard let rpm = parseRPM(arguments[0]) else {
            throw FanCLIError.usage("Timer RPM must be a positive integer or use k suffix like 1.5k")
        }

        guard let duration = parseTimerDuration(arguments[1]) else {
            throw FanCLIError.usage("Timer duration must be positive and at most 23h59m, using h, m, or s in order")
        }

        return .timer(FanTimerRequest(rpm: rpm, duration: duration, userFacingFanID: userFacingFanID))
    }

    private static func parseTimerDuration(_ value: String) -> TimeInterval? {
        var digits = ""
        var totalSeconds = 0
        var previousMultiplier = Int.max

        for character in value {
            if character.isASCII && character.isNumber {
                digits.append(character)
                continue
            }

            let multiplier: Int
            switch character {
            case "h": multiplier = 3600
            case "m": multiplier = 60
            case "s": multiplier = 1
            default: return nil
            }

            guard multiplier < previousMultiplier, let amount = Int(digits), amount <= 86_340 / multiplier else {
                return nil
            }

            totalSeconds += amount * multiplier
            guard totalSeconds <= 86_340 else { return nil }
            previousMultiplier = multiplier
            digits = ""
        }

        guard digits.isEmpty, totalSeconds > 0 else { return nil }
        return TimeInterval(totalSeconds)
    }
    
    private static func parseRPM(_ value: String) -> Int? {
        if let integer = parsePositiveInteger(value) {
            return integer
        }
        
        let normalizedValue = value.lowercased()
        guard normalizedValue.hasSuffix("k") else { return nil }
        
        let thousandsValue = String(normalizedValue.dropLast())
        guard !thousandsValue.isEmpty else { return nil }
        
        guard let decimalRPM = Decimal(string: thousandsValue, locale: Locale(identifier: "en_US_POSIX")) else {
            return nil
        }
        
        guard decimalRPM > 0 else { return nil }
        
        let scaledRPM = decimalRPM * 1000
        var roundedRPM = Decimal()
        var mutableScaledRPM = scaledRPM
        NSDecimalRound(&roundedRPM, &mutableScaledRPM, 0, .plain)
        guard roundedRPM == scaledRPM else { return nil }
        
        let decimalNumber = NSDecimalNumber(decimal: roundedRPM)
        let integerRPM = decimalNumber.intValue
        guard integerRPM > 0 else { return nil }
        guard decimalNumber.compare(NSDecimalNumber(value: integerRPM)) == .orderedSame else { return nil }
        
        return integerRPM
    }
    
    private static func parsePositiveInteger(_ value: String) -> Int? {
        guard let integer = Int(value), integer > 0 else { return nil }
        return integer
    }
    
    private static func isAutoAlias(_ value: String) -> Bool {
        value == "auto" || value == "-a"
    }
}
