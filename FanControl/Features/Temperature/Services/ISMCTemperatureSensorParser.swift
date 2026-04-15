import Foundation

enum ISMCTemperatureSensorParser {
    nonisolated static func parse(_ output: String) throws -> [TemperatureSensor] {
        let sensors = output
            .split(whereSeparator: \.isNewline)
            .compactMap(parseSensor)
            .sorted()
        
        guard !sensors.isEmpty else {
            throw ISMCCommandError.invalidOutput
        }
        
        return sensors
    }
    
    nonisolated private static func parseSensor(_ rawLine: Substring) -> TemperatureSensor? {
        let line = normalizedLine(String(rawLine))
        
        guard !line.isEmpty else { return nil }
        
        if let sensor = parseStrictRow(line) {
            return sensor
        }
        
        return parseFlexibleRow(line)
    }
    
    nonisolated private static func parseStrictRow(_ line: String) -> TemperatureSensor? {
        let rowPattern = #/^\s*(.+?)\s{2,}(\S+)\s{2,}(-?\d+(?:[.,]\d+)?)\s*°C(?:\s{2,}(\S+))?\s*$/#
        
        guard
            let match = line.wholeMatch(of: rowPattern),
            let celsius = celsiusValue(from: String(match.output.3))
        else {
            return nil
        }
        
        return TemperatureSensor(
            key: String(match.output.2),
            celsius: celsius,
            displayName: String(match.output.1).trimmingCharacters(in: .whitespaces)
        )
    }
    
    nonisolated private static func parseFlexibleRow(_ line: String) -> TemperatureSensor? {
        let valuePattern = #/(-?\d+(?:[.,]\d+)?)\s*°C/#
        
        guard
            let valueMatch = line.firstMatch(of: valuePattern),
            let celsius = celsiusValue(from: String(valueMatch.output.1))
        else {
            return nil
        }
        
        let prefix = String(line[..<valueMatch.range.lowerBound])
            .trimmingCharacters(in: .whitespaces)
        
        guard let prefixMatch = prefix.wholeMatch(of: #/^\s*(.+?)\s{2,}(\S+)\s*$/#)
            ?? prefix.wholeMatch(of: #/^\s*(.+?)\s+(\S+)\s*$/#) else {
            return nil
        }
        
        let displayName = String(prefixMatch.output.1).trimmingCharacters(in: .whitespaces)
        let key = String(prefixMatch.output.2).trimmingCharacters(in: .whitespaces)
        
        guard !displayName.isEmpty, !key.isEmpty else {
            return nil
        }
        
        return TemperatureSensor(
            key: key,
            celsius: celsius,
            displayName: displayName
        )
    }
    
    nonisolated private static func celsiusValue(from rawValue: String) -> Double? {
        Double(rawValue.replacing(",", with: "."))
    }
    
    nonisolated private static func normalizedLine(_ line: String) -> String {
        let ansiPattern = #/\u{001B}\[[0-9;?]*[ -/]*[@-~]/#
        
        return line
            .replacing(ansiPattern, with: "")
            .replacing("℃", with: "°C")
            .replacing("ºC", with: "°C")
    }
}
