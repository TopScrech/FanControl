import Foundation

@Observable
final class FanVM {
    var fans: [Fan] = []
    var selectedFanID = 0
    var errorText: String?
    
    private let smc: SMCClient?
    private var timer: Timer?
    private var holdingManualOverride = false
    
    init() {
        do {
            smc = try SMCClient()
            errorText = nil
        } catch {
            smc = nil
            errorText = error.localizedDescription
        }
        
        refresh()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { await self?.tick() }
        }
    }
    
    deinit {
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
            if errorText == nil || errorText?.isEmpty == false {
                errorText = nil
            }
        } catch {
            errorText = error.localizedDescription
        }
    }
    
    func setManualRPM(_ rpm: Double) async {
        guard let smc, let fan = selectedFan else { return }
        
        do {
            try smc.setFanManualRPM(fanID: fan.id, rpm: rpm)
            holdingManualOverride = true
            refresh()
        } catch {
            errorText = error.localizedDescription
        }
    }
    
    func setAuto() async {
        guard let smc, let fan = selectedFan else { return }
        
        do {
            try smc.setFanAuto(fanID: fan.id)
            holdingManualOverride = false
            refresh()
        } catch {
            errorText = error.localizedDescription
        }
    }
}
