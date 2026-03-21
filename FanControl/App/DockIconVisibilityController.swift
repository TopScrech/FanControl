import SwiftUI

enum DockIconVisibilityController {
    static let hidesDockIconDefaultsKey = "hidesDockIcon"
    
    @MainActor
    static func applyStoredPreference(defaults: UserDefaults = .standard) {
        setDockIconHidden(defaults.bool(forKey: hidesDockIconDefaultsKey))
    }
    
    @MainActor
    static func setDockIconHidden(_ isHidden: Bool) {
        let app = NSApplication.shared
        let activationPolicy: NSApplication.ActivationPolicy = isHidden ? .accessory : .regular
        
        guard app.activationPolicy() != activationPolicy else { return }
        guard app.setActivationPolicy(activationPolicy) else { return }
        
        if !isHidden {
            app.activate(ignoringOtherApps: true)
        }
    }
}
