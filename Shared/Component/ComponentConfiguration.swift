import Foundation

nonisolated enum ComponentConfiguration {
    static let protocolVersion = 1
    static let version = "1.7"
    static let bundleIdentifier = "dev.topscrech.FanControl.component"
    static let teamIdentifier = "8FQUA2F388"
    static let clientRequirement = "anchor apple generic and certificate leaf[subject.OU] = \"8FQUA2F388\" and (identifier \"dev.topscrech.FanControl\" or identifier \"dev.topscrech.FanControl.component\" or identifier \"dev.topscrech.FanControl.fan\")"
    static let helperRequirement = "anchor apple generic and certificate leaf[subject.OU] = \"8FQUA2F388\" and identifier \"dev.topscrech.FanControl.helper\""
    // Publish the component DMG on this release page alongside the app
    static let downloadURL = URL(string: "https://github.com/TopScrech/FanControl/releases")
}
