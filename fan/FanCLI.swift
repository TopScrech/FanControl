final class FanCLI {
    private let service = FanCLIService()
    private let reportService = FanReportService()
    
    func run(_ command: FanCommand) async throws {
        switch command {
        case .help:
            print(FanCommandParser.usage)
            
        case .version:
            print(AppBundleLocator.current.versionTag)
            
        case .device:
            print(MacDeviceDescriptionProvider.current())
            
        case .report:
            print(try await reportService.makeReport())
            
        case .list:
            let fans = try await service.readFans()
            print(FanTableFormatter.format(fans))

        case .completionZsh:
            print(FanShellCompletion.zshScript())
            
        case .minAll:
            try await service.setMinimumRPM(userFacingFanID: nil)
            print("Set all fans to minimum RPM")
            
        case .minFan(let fanID):
            try await service.setMinimumRPM(userFacingFanID: fanID)
            print("Set fan \(fanID) to minimum RPM")
            
        case .maxAll:
            try await service.setMaximumRPM(userFacingFanID: nil)
            print("Set all fans to maximum RPM")
            
        case .maxFan(let fanID):
            try await service.setMaximumRPM(userFacingFanID: fanID)
            print("Set fan \(fanID) to maximum RPM")
            
        case .setAllRPM(let rpm):
            try await service.setManualRPM(rpm, userFacingFanID: nil)
            print("Set all fans to \(rpm) RPM")
            
        case .setFanRPM(let fanID, let rpm):
            try await service.setManualRPM(rpm, userFacingFanID: fanID)
            print("Set fan \(fanID) to \(rpm) RPM")
            
        case .autoAll:
            try await service.setAuto(userFacingFanID: nil)
            print("Set all fans to auto")
            
        case .autoFan(let fanID):
            try await service.setAuto(userFacingFanID: fanID)
            print("Set fan \(fanID) to auto")
        }
    }
}
