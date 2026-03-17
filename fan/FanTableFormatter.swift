import CoreSMC

enum FanTableFormatter {
    static func format(_ fans: [Fan]) -> String {
        guard !fans.isEmpty else {
            return "No fans found"
        }
        
        let headers = ["ID", "Mode", "Current", "Target", "Min", "Max"]
        
        let rows = fans
            .sorted {
                $0.id < $1.id
            }
            .map {[
                String($0.userFacingID),
                $0.cliModeDescription,
                String(Int($0.currentRPM.rounded())),
                String(Int($0.targetRPM.rounded())),
                String(Int($0.minRPM.rounded())),
                String(Int($0.maxRPM.rounded())),
            ]}
        
        let widths = headers.indices.map { index in
            max(headers[index].count, rows.map { $0[index].count }.max() ?? 0)
        }
        
        return ([formatRow(headers, widths: widths)] + rows.map { formatRow($0, widths: widths) })
            .joined(separator: "\n")
    }
    
    private static func formatRow(_ values: [String], widths: [Int]) -> String {
        zip(values, widths)
            .map { value, width in
                value.padding(toLength: width, withPad: " ", startingAt: 0)
            }
            .joined(separator: "  ")
    }
}
