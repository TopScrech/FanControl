import Foundation
import OSLog

@Observable
final class FanVM {
    var fans: [Fan] = []
    var selectedFanID = 0
    var errorText: String?
    
    private static let logger = Logger(subsystem: "FanControl", category: "FanVM")
    private let smc: SMCClient?
    private var timer: Timer?
    private var holdingManualOverride = false
    
    init() {
        Self.logger.info("Initializing FanVM")
        
        do {
            smc = try SMCClient()
            Self.logger.info("SMC client ready")
        } catch {
            smc = nil
            errorText = error.localizedDescription
            Self.logger.error("SMC client init failed: \(error.localizedDescription, privacy: .public)")
        }
        
        refresh()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task {
                await self?.tick()
            }
        }
    }
    
    deinit {
        Self.logger.info("Deinitializing FanVM")
        timer?.invalidate()
    }
    
    var selectedFan: Fan? {
        fans.first(where: { $0.id == selectedFanID })
    }
    
    func tick() async {
        if holdingManualOverride {
            do {
                try smc?.keepAliveManualOverride()
            } catch {
                errorText = error.localizedDescription
                Self.logger.error("Manual keep-alive failed: \(error.localizedDescription, privacy: .public)")
            }
        }
        
        refresh()
    }
    
    func refresh() {
        guard let smc else { return }
        
        do {
            fans = try smc.readFans()
            
            if selectedFanID >= fans.count {
                selectedFanID = 0
            }
        } catch {
            errorText = error.localizedDescription
            Self.logger.error("Refresh failed: \(error.localizedDescription, privacy: .public)")
        }
    }
    
    func setManualRPM(_ rpm: Double) async {
        guard let smc else {
            Self.logger.info("Manual request ignored: no SMC client")
            return
        }
        
        guard let fan = selectedFan else {
            Self.logger.info("Manual request ignored: no selected fan")
            return
        }
        
        do {
            Self.logger.info("Manual request fan=\(fan.id, privacy: .public) rpm=\(rpm, privacy: .public) mode=\(fan.mode, privacy: .public)")
            try smc.setFanManualRPM(fanID: fan.id, rpm: rpm)
            holdingManualOverride = true
            refresh()
            Self.logger.info("Manual applied fan=\(fan.id, privacy: .public) rpm=\(rpm, privacy: .public)")
        } catch {
            Self.logger.error("Manual failed fan=\(fan.id, privacy: .public) rpm=\(rpm, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            errorText = error.localizedDescription
        }
    }
    
    func setAuto() async {
        guard let smc, let fan = selectedFan else {
            Self.logger.info("Auto request ignored: missing SMC or selected fan")
            return
        }
        
        do {
            Self.logger.info("Auto request fan=\(fan.id, privacy: .public) mode=\(fan.mode, privacy: .public)")
            try smc.setFanAuto(fanID: fan.id)
            holdingManualOverride = false
            refresh()
            Self.logger.info("Auto applied fan=\(fan.id, privacy: .public)")
        } catch {
            Self.logger.error("Auto failed fan=\(fan.id, privacy: .public) error=\(error.localizedDescription, privacy: .public)")
            errorText = error.localizedDescription
        }
    }
}
