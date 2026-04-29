import SwiftUI
import CoreSMC
import ServiceManagement
import AutoUpdate
import OSLog

@Observable
final class FanVM {
    private static let updateRepositoryOwner = "TopScrech"
    private static let updateRepositoryName = "FanControl"
    private static let allFansSelectionID = -1
    private static let selectedFanIDDefaultsKey = "selectedFanID"
    static let showsMenuBarFanSpeedDefaultsKey = "showsMenuBarFanSpeed"
    static let showsMenuBarAverageTemperaturesDefaultsKey = "showsMenuBarAverageTemperatures"
    private static let allowPrereleaseUpdatesDefaultsKey = "allowPrereleaseUpdates"
    private static let useGitHubProxyDefaultsKey = "useGitHubProxy"
    private static let gitHubProxyURLDefaultsKey = "gitHubProxyURL"
    private static let lastAutomaticUpdateCheckDateDefaultsKey = "lastAutomaticUpdateCheckDate"
    private static let manualRetryAttempts = 15
    private static let manualRetryInterval: Duration = .seconds(1)
    private static let presetStepRPM = 500
    private static let rpmMatchTolerance = 1.0
    private static let errorDisplaySeconds = 5.0
    private static let errorDisplayDuration: Duration = .seconds(errorDisplaySeconds)
    private static let updateCheckIntervalSeconds = 24.0 * 60 * 60
    private static let automaticUpdateCheckRetrySeconds = 60.0
    private static let fanRefreshBackoffAfterEmptySeconds = 10.0
    private static let fanRefreshBackoffAfterFailureSeconds = 5.0
    private static let licenseOfflineGracePeriodSeconds = 7.0 * 24 * 60 * 60
    private static let defaultCustomPresetMinimumTemperature = 40
    private static let defaultCustomPresetMaximumTemperature = 80
    static let defaultGitHubProxyURLString = "https://gh-proxy.com"
    
    var fans: [Fan] = []
    var temperatureSensors: [TemperatureSensor] = []
    var isSendingControlAttempts = false
    var controlAttemptTargetMode: FanControlMode?
    var isCheckingForUpdates = false
    var updateStatusText = String(localized: "Not checked yet")
    var updateChangelogEntries: [UpdateChangelogEntry] = []
    var isUpdatePromptPresented = false
    var isSettingsOpen = false
    var isDebugSectionVisible = false
    var mainWindowUpdateStatusAlert: UpdateStatusAlert?
    var settingsUpdateStatusAlert: UpdateStatusAlert?
    var menuBarUpdateStatusAlert: UpdateStatusAlert?
    var helperConnectionStatus = HelperConnectionStatus.unavailable
    
    var selectedFanID = 0 {
        didSet {
            UserDefaults.standard.set(selectedFanID, forKey: Self.selectedFanIDDefaultsKey)
        }
    }
    
    var allowsPrereleaseUpdates = UserDefaults.standard.bool(forKey: FanVM.allowPrereleaseUpdatesDefaultsKey) {
        didSet {
            UserDefaults.standard.set(allowsPrereleaseUpdates, forKey: Self.allowPrereleaseUpdatesDefaultsKey)
            let allowsPrereleaseUpdates = allowsPrereleaseUpdates
            
            Task {
                await appUpdater.setAllowPrereleases(allowsPrereleaseUpdates)
            }
        }
    }
    
    var usesGitHubProxy = UserDefaults.standard.bool(forKey: FanVM.useGitHubProxyDefaultsKey) {
        didSet {
            UserDefaults.standard.set(usesGitHubProxy, forKey: Self.useGitHubProxyDefaultsKey)
            let resolvedGitHubProxyURL = gitHubProxyURL
            
            Task {
                await appUpdater.setGitHubProxyURL(resolvedGitHubProxyURL)
            }
        }
    }
    
    var gitHubProxyURLString = UserDefaults.standard.string(forKey: FanVM.gitHubProxyURLDefaultsKey) ?? FanVM.defaultGitHubProxyURLString {
        didSet {
            UserDefaults.standard.set(gitHubProxyURLString, forKey: Self.gitHubProxyURLDefaultsKey)
            let resolvedGitHubProxyURL = gitHubProxyURL
            
            Task {
                await appUpdater.setGitHubProxyURL(resolvedGitHubProxyURL)
            }
        }
    }
    
    var errorAlert: ErrorAlert?
    var licenseEmail = ""
    var licenseKey = ""
    var isCheckingLicense = false
    
    var isLicenseActive = false {
        didSet {
            guard isLicenseActive != oldValue else { return }
            
            if !isLicenseActive {
                Task {
                    await disableCustomPresetsForInactiveLicense()
                }
            }
        }
    }
    
    var licenseStatusText = String(localized: "No saved license")
    let deviceName: String
    let isMacBook: Bool
    
    var appVersionDescription: String {
        Bundle.main.versionTag
    }
    
    var helperConnectionStatusText: String {
        helperConnectionStatus.text
    }
    
    var isErrorAlertPresented: Bool {
        get {
            errorAlert != nil
        } set {
            guard !newValue else { return }
            dismissError()
        }
    }
    
    var isMainWindowUpdateStatusAlertPresented: Bool {
        get {
            mainWindowUpdateStatusAlert != nil
        } set {
            guard !newValue else { return }
            dismissUpdateStatusAlert(for: .mainWindow)
        }
    }
    
    var isSettingsUpdateStatusAlertPresented: Bool {
        get {
            settingsUpdateStatusAlert != nil
        } set {
            guard !newValue else { return }
            dismissUpdateStatusAlert(for: .settings)
        }
    }
    
    var isMenuBarUpdateStatusAlertPresented: Bool {
        get {
            menuBarUpdateStatusAlert != nil
        } set {
            guard !newValue else { return }
            dismissUpdateStatusAlert(for: .menuBar)
        }
    }
    
    var updatePromptTitle: String {
        updatePromptTitle(for: updateTargetVersionTag)
    }
    
    var updateTargetVersionTag: String {
        if showsFakeUpdatePrompt {
            return "v9.9.9-debug"
        }
        
        return preparedUpdate?.release.tagName ?? String(localized: "Unknown")
    }
    
    var showsResetGitHubProxyURLButton: Bool {
        gitHubProxyURLString != Self.defaultGitHubProxyURLString
    }
    
    private static let logger = Logger(subsystem: "FanControl", category: "FanVM")
    private let localSMC: LocalSMCService?
    private var remoteSMC: RemoteSMCService?
    private let temperatureSensorService = ISMCTemperatureSensorService()
    
    private let appUpdater = AppUpdater(
        owner: FanVM.updateRepositoryOwner,
        repository: FanVM.updateRepositoryName,
        gitHubProxyURL: FanVM.storedGitHubProxyURL()
    )
    
    private let preparedUpdateInstaller = PreparedUpdateInstaller()
    private let licenseVerificationService = LicenseVerificationService()
    private let licenseCredentialStore = LicenseCredentialStore()
    private var preparedUpdate: PreparedUpdate?
    private var isInstallingPreparedUpdate = false
    private var showsFakeUpdatePrompt = false
    private var automaticUpdateTask: Task<Void, Never>?
    private var debugDelayedUpdateCheckTask: Task<Void, Never>?
    private var timer: Timer?
    private var holdingManualOverride = false
    private var helperInstallInProgress = false
    private var customPresetStore = FanCustomPresetStore()
    private var controlActionToken = 0
    private var errorDismissToken = 0
    private var errorDismissTask: Task<Void, Never>?
    private var errorExpiryDate: Date?
    private var nextFanReadDate = Date.distantPast
    private let isRoot = geteuid() == 0
    
    init() {
        let detectedDeviceName = MacDeviceDescriptionProvider.current()
        deviceName = detectedDeviceName
        isMacBook = detectedDeviceName.localizedCaseInsensitiveContains("MacBook")
        Self.logger.info("Initializing FanVM")
        Self.logHelperBundleDiagnostics()
        selectedFanID = UserDefaults.standard.integer(forKey: Self.selectedFanIDDefaultsKey)
        var localError: String?
        
        do {
            localSMC = try LocalSMCService()
            Self.logger.info("Local SMC client ready")
        } catch {
            localSMC = nil
            localError = error.localizedDescription
            Self.logger.error("Local SMC client init failed: \(error)")
        }
        
        if localSMC == nil {
            if let localError {
                presentError(localError)
            }
        }
        
        loadStoredLicenseState()
        
        connectHelperIfAvailable()
        
        Task {
            await configureAppUpdater()
            await startAutomaticUpdateChecks()
            await verifySavedLicenseOnLaunch()
            await refresh()
            await applyActiveCustomPresetsIfNeeded(refreshAfterApply: true)
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task {
                await self?.tick()
            }
        }
    }
    
    deinit {
        Self.logger.info("Deinitializing FanVM")
        automaticUpdateTask?.cancel()
        debugDelayedUpdateCheckTask?.cancel()
        errorDismissTask?.cancel()
        timer?.invalidate()
    }
    
    var selectedFan: Fan? {
        guard !controlsAllFans else { return nil }
        
        return fans.first {
            $0.id == selectedFanID
        }
    }
    
    var controlsAllFans: Bool {
        selectedFanID == Self.allFansSelectionID
    }
    
    var isAnyFanSpinning: Bool {
        fans.contains {
            $0.currentRPM > 0
        }
    }
    
    var menuBarCurrentSpeeds: [String] {
        fans.map {
            String(Int($0.currentRPM.rounded()))
        }
    }
    
    var canUsePresetControl: Bool {
        isLicenseActive
    }
    
    var allFansID: Int {
        Self.allFansSelectionID
    }
    
    var showsAllFansOption: Bool {
        fans.count > 1
    }
    
    var controlMinRPM: Double? {
        let targetFans = selectedFansForControl
        guard !targetFans.isEmpty else { return nil }
        
        if controlsAllFans {
            return targetFans.map(\.minRPM).max()
        }
        
        return targetFans.first?.minRPM
    }
    
    var controlMaxRPM: Double? {
        let targetFans = selectedFansForControl
        guard !targetFans.isEmpty else { return nil }
        
        if controlsAllFans {
            return targetFans.map(\.maxRPM).min()
        }
        
        return targetFans.first?.maxRPM
    }
    
    var controlPresetRPMs: [Int] {
        guard let minRPM = controlMinRPM, let maxRPM = controlMaxRPM else { return [] }
        
        let start = Int((minRPM / Double(Self.presetStepRPM)).rounded(.up)) * Self.presetStepRPM
        let end = Int((maxRPM / Double(Self.presetStepRPM)).rounded(.down)) * Self.presetStepRPM
        
        guard start <= end else { return [] }
        
        return Array(stride(from: start, through: end, by: Self.presetStepRPM))
    }
    
    func changeSelectedFan(by offset: Int) {
        guard offset != 0 else { return }
        
        let selectionIDs = selectableFanIDs
        guard !selectionIDs.isEmpty else { return }
        
        guard let currentIndex = selectionIDs.firstIndex(of: selectedFanID) else {
            selectedFanID = offset > 0 ? selectionIDs[0] : selectionIDs[selectionIDs.count - 1]
            return
        }
        
        let rawNextIndex = (currentIndex + offset) % selectionIDs.count
        let nextIndex = rawNextIndex >= 0 ? rawNextIndex : rawNextIndex + selectionIDs.count
        selectedFanID = selectionIDs[nextIndex]
    }
    
    func resetGitHubProxyURL() {
        gitHubProxyURLString = Self.defaultGitHubProxyURLString
    }
    
    var selectedCustomPresetDraft: FanCustomPresetDraft {
        customPresetStore.draft(
            for: selectedFansForControl,
            selectableTemperatureSensors: selectableTemperatureSensors,
            defaultMinimumTemperature: Self.defaultCustomPresetMinimumTemperature,
            defaultMaximumTemperature: Self.defaultCustomPresetMaximumTemperature
        )
    }
    
    var selectedCustomPresetIsActive: Bool {
        customPresetStore.isActive(for: selectedFansForControl)
    }
    
    var selectedCustomPresetPercentageText: String? {
        let draft = selectedCustomPresetDraft
        
        guard let sensor = customPresetStore.resolvedTemperatureSensor(
            for: draft.sensorKey,
            selectableTemperatureSensors: selectableTemperatureSensors
        ) else {
            return nil
        }
        
        let minimumTemperature = Double(draft.minimumTemperature)
        let maximumTemperature = Double(draft.maximumTemperature)
        let percentage: Double
        
        if sensor.celsius <= minimumTemperature {
            percentage = 0
        } else if maximumTemperature <= minimumTemperature || sensor.celsius >= maximumTemperature {
            percentage = 1
        } else {
            percentage = (sensor.celsius - minimumTemperature) / (maximumTemperature - minimumTemperature)
        }
        
        return percentage.formatted(.percent.precision(.fractionLength(0)))
    }
    
    var activeControlMode: FanControlMode? {
        let targetFans = selectedFansForControl
        guard !targetFans.isEmpty else { return nil }
        
        if controlsAllFans {
            return activeControlModeForAllFans(targetFans)
        }
        
        let presetRPMs = controlPresetRPMs.map(Double.init)
        
        let fanModes = targetFans.compactMap {
            activeControlMode(for: $0, presetRPMs: presetRPMs, customPreset: customPresetStore.preset(for: $0.id))
        }
        
        guard fanModes.count == targetFans.count, let firstMode = fanModes.first else { return nil }
        guard fanModes.allSatisfy({ $0 == firstMode }) else { return nil }
        
        return firstMode
    }
    
    var showsControlAttemptProgress: Bool {
        guard isSendingControlAttempts else { return false }
        guard let controlAttemptTargetMode else { return true }
        return activeControlMode != controlAttemptTargetMode
    }
    
    private var selectableTemperatureSensors: [TemperatureSensor] {
        TemperatureSensorCategory.averageCases(isMacBook: isMacBook).compactMap {
            $0.averageSensor(in: temperatureSensors)
        } + temperatureSensors
    }
    
    private static func logHelperBundleDiagnostics() {
        let bundleURL = Bundle.main.bundleURL
        
        let launchdURL = bundleURL.appendingPathComponent(
            "Contents/Library/LaunchDaemons/\(FanControlXPCConstants.launchdPlistName)"
        )
        
        let helperURL = bundleURL.appendingPathComponent(
            "Contents/Library/PrivilegedHelperTools/FanControlHelper"
        )
        
        let fm = FileManager.default
        
        Self.logger.info("App bundle path: \(bundleURL.path)")
        Self.logger.info("Launchd plist path: \(launchdURL.path)")
        Self.logger.info("Launchd plist exists: \(fm.fileExists(atPath: launchdURL.path))")
        Self.logger.info("Helper tool path: \(helperURL.path)")
        Self.logger.info("Helper tool exists: \(fm.fileExists(atPath: helperURL.path))")
    }
    
    nonisolated private static func updateCodeSigningValidation() -> AppUpdater.CodeSigningValidation {
        guard let authority = currentCodeSigningAuthority() else {
            return .required
        }
        
        guard authority.hasPrefix("Developer ID Application:") else {
            let logger = Logger(subsystem: "FanControl", category: "FanVM")
            logger.info("Skipping update code signing identity match for local authority \(authority, privacy: .public)")
            return .skipped
        }
        
        return .required
    }
    
    nonisolated private static func currentCodeSigningAuthority() -> String? {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/codesign")
        process.arguments = ["-dvvv", Bundle.main.bundleURL.path(percentEncoded: false)]
        
        let standardError = Pipe()
        process.standardOutput = Pipe()
        process.standardError = standardError
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        
        guard process.terminationStatus == 0 else {
            return nil
        }
        
        let description = String(
            decoding: standardError.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )
        
        guard let authorityLine = description
            .split(separator: "\n")
            .first(where: { $0.hasPrefix("Authority=") })
        else {
            return nil
        }
        
        return String(authorityLine.dropFirst("Authority=".count))
    }
    
    
    func tick() async {
        if holdingManualOverride, let smc = writeService {
            do {
                try await smc.keepAliveManualOverride()
            } catch {
                presentError(error.localizedDescription)
                Self.logger.error("Manual keep-alive failed: \(error)")
            }
        }
        
        await refresh()
        await applyActiveCustomPresetsIfNeeded()
    }
    
    func refresh() async {
        Self.logger.info("Refresh starting")
        
        var refreshError: Error?

        if shouldReadFansNow(), let smc = activeService {
            do {
                let snapshots = try await smc.readFans()
                Self.logger.info("Refresh readFans count=\(snapshots.count)")
                fans = snapshots
                resetFanReadBackoff()
                
                if fans.isEmpty {
                    selectedFanID = Self.allFansSelectionID
                    deferFanReads(for: Self.fanRefreshBackoffAfterEmptySeconds)
                    
                } else if fans.count == 1 {
                    selectedFanID = fans[0].id
                    
                } else if !controlsAllFans, !fans.contains(where: { $0.id == selectedFanID }) {
                    selectedFanID = fans[0].id
                }
            } catch {
                refreshError = error
                deferFanReads(for: Self.fanRefreshBackoffAfterFailureSeconds)
                Self.logger.error("Refresh readFans failed: \(error)")
            }
        } else {
            if activeService == nil {
                Self.logger.info("Refresh fan read skipped: no active SMC service")
            } else {
                Self.logger.info("Refresh fan read skipped: backing off until \(self.nextFanReadDate, privacy: .public)")
            }
        }
        
        do {
            let sensors = try await temperatureSensorService.readTemperatureSensors()
            Self.logger.info("Refresh readTemperatureSensors count=\(sensors.count)")
            temperatureSensors = sensors
        } catch {
            if refreshError == nil {
                refreshError = error
            }
            
            temperatureSensors = []
            Self.logger.error("Refresh readTemperatureSensors failed: \(error)")
        }
        
        if let refreshError {
            presentError(refreshError.localizedDescription)
        }
    }
    
    func checkForUpdatesNow(presenter: UpdateStatusAlertPresenter) async {
        guard !isCheckingForUpdates else { return }
        isCheckingForUpdates = true
        
        updateStatusText = String(localized: "Checking for updates")
        defer { isCheckingForUpdates = false }
        
        do {
            switch try await appUpdater.prepareUpdateIfAvailable() {
            case .upToDate:
                clearPreparedUpdate()
                updateStatusText = String(localized: "The latest version is already installed")
                
                presentUpdateStatusAlert(
                    title: String(localized: "You’re up to date"),
                    message: String(localized: "The latest version is already installed"),
                    presenter: presenter
                )
                
                Self.logger.info("Update check: already on latest version")
                
            case .prepared(let preparedUpdate):
                await presentPreparedUpdate(preparedUpdate)
                Self.logger.info("Update prepared tag=\(preparedUpdate.release.tagName)")
            }
        } catch {
            updateStatusText = String(localized: "Update failed")
            Self.logger.error("Update check failed: \(error)")
            
            let template = String(localized: "Update failed: %@")
            presentError(String(format: template, locale: .current, error.localizedDescription))
        }
    }
    
    func installPreparedUpdate() async {
        guard !isCheckingForUpdates else { return }
        
        if showsFakeUpdatePrompt {
            showsFakeUpdatePrompt = false
            updateChangelogEntries = []
            isUpdatePromptPresented = false
            return
        }
        
        guard let preparedUpdate else { return }
        
        isCheckingForUpdates = true
        let installingTemplate = String(localized: "Installing %@")
        updateStatusText = String(format: installingTemplate, locale: .current, preparedUpdate.release.tagName)
        isUpdatePromptPresented = false
        defer { isCheckingForUpdates = false }
        
        do {
            isInstallingPreparedUpdate = true
            await resetFansForTermination()
            let installedAppURL = try preparedUpdateInstaller.install(preparedUpdate)
            
            clearPreparedUpdate()
            try relaunchInstalledApp(at: installedAppURL)
            
            Self.logger.info("Update install succeeded tag=\(preparedUpdate.release.tagName)")
            Darwin.exit(EXIT_SUCCESS)
        } catch {
            isInstallingPreparedUpdate = false
            await appUpdater.discardPreparedUpdate(preparedUpdate)
            
            clearPreparedUpdate()
            updateStatusText = String(localized: "Update failed")
            Self.logger.error("Update install failed: \(error)")
            
            let template = String(localized: "Update failed: %@")
            presentError(String(format: template, locale: .current, error.localizedDescription))
        }
    }
    
    func dismissUpdatePrompt() async {
        isUpdatePromptPresented = false
        
        if showsFakeUpdatePrompt {
            showsFakeUpdatePrompt = false
            updateChangelogEntries = []
            return
        }
        
        guard let preparedUpdate else { return }
        await appUpdater.discardPreparedUpdate(preparedUpdate)
        clearPreparedUpdate()
        updateStatusText = String(localized: "Update postponed")
    }
    
    func dismissUpdateStatusAlert(for presenter: UpdateStatusAlertPresenter) {
        switch presenter {
        case .mainWindow: mainWindowUpdateStatusAlert = nil
        case .settings: settingsUpdateStatusAlert = nil
        case .menuBar: menuBarUpdateStatusAlert = nil
        }
    }
    
    private func presentUpdateStatusAlert(
        title: String,
        message: String,
        presenter: UpdateStatusAlertPresenter
    ) {
        let alert = UpdateStatusAlert(title: title, message: message)
        
        mainWindowUpdateStatusAlert = nil
        settingsUpdateStatusAlert = nil
        menuBarUpdateStatusAlert = nil
        
        switch presenter {
        case .mainWindow: mainWindowUpdateStatusAlert = alert
        case .settings: settingsUpdateStatusAlert = alert
        case .menuBar: menuBarUpdateStatusAlert = alert
        }
    }
    
    func setSettingsOpen(_ isOpen: Bool) {
        isSettingsOpen = isOpen
        
        if isOpen {
            updateHelperConnectionStatus()
        }
    }
    
    func revealDebugSection() {
        isDebugSectionVisible = true
    }
    
    func presentFakeUpdatePrompt() {
        showsFakeUpdatePrompt = true
        updateChangelogEntries = [
            UpdateChangelogEntry(
                tagName: "v9.9.9-debug",
                isPrerelease: true,
                notes: String(localized: "Some release notes")
            ),
            UpdateChangelogEntry(
                tagName: "v9.9.8-rc.2",
                isPrerelease: true,
                notes: String(localized: "Some release notes")
            ),
            UpdateChangelogEntry(
                tagName: "v9.9.8-beta.4",
                isPrerelease: true,
                notes: String(localized: "Some release notes")
            ),
            UpdateChangelogEntry(
                tagName: "v9.9.7",
                isPrerelease: false,
                notes: String(localized: "Some release notes")
            ),
            UpdateChangelogEntry(
                tagName: "v9.9.6",
                isPrerelease: false,
                notes: String(localized: "Some release notes")
            )
        ]
        
        isUpdatePromptPresented = true
    }
    
    func scheduleDebugUpdateCheck() {
        debugDelayedUpdateCheckTask?.cancel()
        
        debugDelayedUpdateCheckTask = Task { [weak self] in
            do {
                try await Task.sleep(for: .seconds(2))
            } catch {
                return
            }
            
            await self?.checkForUpdatesAutomatically()
        }
    }
    
    func verifyLicenseNow() async {
        let email = self.licenseEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        let licenseKey = self.licenseKey.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !email.isEmpty, !licenseKey.isEmpty else {
            licenseStatusText = String(localized: "Email and license key are required")
            isLicenseActive = false
            return
        }
        
        await verifyLicense(
            email: email,
            licenseKey: licenseKey,
            shouldSaveCredentials: true
        )
    }
    
    func clearSavedLicense() async {
        do {
            if let savedCredentials = licenseCredentialStore.loadCredentials() {
                guard let deviceIdentifier = MacDeviceIdentityProvider.deviceIdentifier() else {
                    presentError("Could not identify this Mac for license reset")
                    return
                }
                
                _ = try await licenseVerificationService.removeDevice(
                    email: savedCredentials.email,
                    licenseKey: savedCredentials.licenseKey,
                    deviceIdentifier: deviceIdentifier
                )
            }
            
            try licenseCredentialStore.clearCredentials()
            licenseEmail = ""
            licenseKey = ""
            isLicenseActive = false
            licenseStatusText = String(localized: "No saved license")
        } catch {
            presentError(error.localizedDescription)
        }
    }
    
    func setManualRPM(_ rpm: Double, targetMode: FanControlMode = .preset) async {
        if targetMode == .preset, !isLicenseActive {
            presentError(String(localized: "Preset control requires an active license"))
            return
        }
        
        await applyManualRPM(
            requestSummary: "Manual request rpm=\(rpm)",
            actionSummary: "Manual applied rpm=\(rpm)",
            targetMode: targetMode
        ) { _ in
            rpm
        }
    }
    
    func setCustomPreset(_ draft: FanCustomPresetDraft) async {
        guard isLicenseActive else {
            presentError(String(localized: "Preset control requires an active license"))
            return
        }
        
        let targetFans = selectedFansForControl
        
        guard !targetFans.isEmpty else {
            Self.logger.info("Custom preset request ignored: no selected fan targets")
            return
        }
        
        let normalizedDraft = customPresetStore.normalizedDraft(
            draft,
            selectableTemperatureSensors: selectableTemperatureSensors
        )
        
        guard let sensor = customPresetStore.resolvedTemperatureSensor(
            for: normalizedDraft.sensorKey,
            selectableTemperatureSensors: selectableTemperatureSensors
        ) else {
            presentError(String(localized: "No temperature sensors available"))
            return
        }
        
        let targetFanIDs = targetFans.map(\.id)
        
        customPresetStore.storeConfiguration(
            fanIDs: targetFanIDs,
            sensor: sensor,
            draft: normalizedDraft,
            isEnabled: false
        )
        
        let actionToken = startControlAction()
        let helperStatus = await ensureHelperConnected()
        
        guard let smc = writeService else {
            setWriteUnavailableError(status: helperStatus)
            Self.logger.info("Custom preset request ignored: no writable SMC client")
            return
        }
        
        do {
            var successfulSignals = 0
            var lastAttemptError: Error?
            
            beginControlAttemptProgress(targetMode: .custom)
            defer { endControlAttemptProgress() }
            
            for attempt in 1...Self.manualRetryAttempts {
                guard isControlActionCurrent(actionToken) else {
                    Self.logger.info("Custom preset retries canceled")
                    return
                }
                
                for fan in targetFans {
                    let targetRPM = customPresetStore.targetRPM(
                        for: fan,
                        sensorTemperature: sensor.celsius,
                        minimumTemperature: normalizedDraft.minimumTemperature,
                        maximumTemperature: normalizedDraft.maximumTemperature
                    )
                    
                    do {
                        try await smc.setFanManualRPM(fanID: fan.id, rpm: targetRPM)
                        successfulSignals += 1
                        
                        Self.logger.info(
                            "Custom preset signal sent fan=\(fan.id) sensor=\(sensor.key) rpm=\(targetRPM) attempt=\(attempt)"
                        )
                    } catch {
                        lastAttemptError = error
                        
                        Self.logger.error(
                            "Custom preset signal failed fan=\(fan.id) sensor=\(sensor.key) rpm=\(targetRPM) attempt=\(attempt) error=\(error)"
                        )
                    }
                }
                
                if attempt < Self.manualRetryAttempts {
                    try await Task.sleep(for: Self.manualRetryInterval)
                }
            }
            
            guard isControlActionCurrent(actionToken) else {
                Self.logger.info("Custom preset retries canceled")
                return
            }
            
            guard successfulSignals > 0 else {
                if let lastAttemptError {
                    presentError(lastAttemptError.localizedDescription)
                }
                
                return
            }
            
            customPresetStore.setEnabled(true, fanIDs: targetFanIDs)
            holdingManualOverride = true
            await refresh()
            
            Self.logger.info(
                "Custom preset applied fans=\(String(describing: targetFanIDs)) sensor=\(sensor.key) signals=\(successfulSignals)"
            )
            
        } catch is CancellationError {
            Self.logger.info("Custom preset retries canceled")
            
        } catch {
            Self.logger.error("Custom preset failed error=\(error)")
            presentError(error.localizedDescription)
        }
    }
    
    func setControlMin() async {
        if controlsAllFans {
            await applyManualRPM(
                requestSummary: "Manual request all-fans minimum",
                actionSummary: "Manual applied all-fans minimum",
                targetMode: .min
            ) {
                $0.minRPM
            }
            
            return
        }
        
        guard let minRPM = controlMinRPM else { return }
        await setManualRPM(minRPM, targetMode: .min)
    }
    
    func setControlMax() async {
        if controlsAllFans {
            await applyManualRPM(
                requestSummary: "Manual request all-fans maximum",
                actionSummary: "Manual applied all-fans maximum",
                targetMode: .max
            ) {
                $0.maxRPM
            }
            
            return
        }
        
        guard let maxRPM = controlMaxRPM else { return }
        await setManualRPM(maxRPM, targetMode: .max)
    }
    
    private func applyManualRPM(
        requestSummary: String,
        actionSummary: String,
        targetMode: FanControlMode,
        rpmForFan: (Fan) -> Double
    ) async {
        let actionToken = startControlAction()
        let targetFans = selectedFansForControl
        
        guard !targetFans.isEmpty else {
            Self.logger.info("Manual request ignored: no selected fan targets")
            return
        }
        
        let fanIDs = targetFans.map(\.id)
        
        let previouslyEnabledCustomPresetFanIDs = fanIDs.filter {
            customPresetStore.preset(for: $0)?.isEnabled == true
        }
        
        customPresetStore.setEnabled(false, fanIDs: previouslyEnabledCustomPresetFanIDs)
        
        let helperStatus = await ensureHelperConnected()
        
        guard let smc = writeService else {
            customPresetStore.setEnabled(true, fanIDs: previouslyEnabledCustomPresetFanIDs)
            holdingManualOverride = customPresetStore.hasEnabledPresets
            setWriteUnavailableError(status: helperStatus)
            Self.logger.info("Manual request ignored: no writable SMC client")
            return
        }
        
        do {
            Self.logger.info("\(requestSummary) fans=\(String(describing: fanIDs))")
            var successfulSignals = 0
            var lastAttemptError: Error?
            
            beginControlAttemptProgress(targetMode: targetMode)
            defer { endControlAttemptProgress() }
            
            for attempt in 1...Self.manualRetryAttempts {
                guard isControlActionCurrent(actionToken) else {
                    Self.logger.info("Manual retries canceled")
                    return
                }
                
                for fan in targetFans {
                    let rpm = rpmForFan(fan)
                    
                    do {
                        try await smc.setFanManualRPM(fanID: fan.id, rpm: rpm)
                        successfulSignals += 1
                        Self.logger.info("Manual signal sent fan=\(fan.id) rpm=\(rpm) attempt=\(attempt)")
                    } catch {
                        lastAttemptError = error
                        Self.logger.error("Manual signal failed fan=\(fan.id) rpm=\(rpm) attempt=\(attempt) error=\(error)")
                    }
                }
                
                if attempt < Self.manualRetryAttempts {
                    try await Task.sleep(for: Self.manualRetryInterval)
                }
            }
            
            guard isControlActionCurrent(actionToken) else {
                Self.logger.info("Manual retries canceled")
                return
            }
            
            guard successfulSignals > 0 else {
                customPresetStore.setEnabled(true, fanIDs: previouslyEnabledCustomPresetFanIDs)
                holdingManualOverride = customPresetStore.hasEnabledPresets
                
                if let lastAttemptError {
                    presentError(lastAttemptError.localizedDescription)
                }
                
                return
            }
            
            holdingManualOverride = true
            await refresh()
            Self.logger.info("\(actionSummary) fans=\(String(describing: fanIDs)) signals=\(successfulSignals)")
            
        } catch is CancellationError {
            customPresetStore.setEnabled(true, fanIDs: previouslyEnabledCustomPresetFanIDs)
            holdingManualOverride = customPresetStore.hasEnabledPresets
            Self.logger.info("Manual retries canceled")
            
        } catch {
            customPresetStore.setEnabled(true, fanIDs: previouslyEnabledCustomPresetFanIDs)
            holdingManualOverride = customPresetStore.hasEnabledPresets
            
            Self.logger.error("Manual failed error=\(error)")
            presentError(error.localizedDescription)
        }
    }
    
    func setAuto() async {
        _ = startControlAction()
        let targetFans = selectedFansForControl
        
        guard !targetFans.isEmpty else {
            Self.logger.info("Auto request ignored: missing SMC or selected fan")
            return
        }
        
        let fanIDs = targetFans.map(\.id)
        
        let previouslyEnabledCustomPresetFanIDs = fanIDs.filter {
            customPresetStore.preset(for: $0)?.isEnabled == true
        }
        
        customPresetStore.setEnabled(false, fanIDs: previouslyEnabledCustomPresetFanIDs)
        
        let helperStatus = await ensureHelperConnected()
        
        guard let smc = writeService else {
            customPresetStore.setEnabled(true, fanIDs: previouslyEnabledCustomPresetFanIDs)
            holdingManualOverride = customPresetStore.hasEnabledPresets
            setWriteUnavailableError(status: helperStatus)
            Self.logger.info("Auto request ignored: missing writable SMC client")
            return
        }
        
        var successfulSignals = 0
        var lastAttemptError: Error?
        
        Self.logger.info("Auto request fans=\(String(describing: fanIDs))")
        
        for fan in targetFans {
            do {
                try await smc.setFanAuto(fanID: fan.id)
                successfulSignals += 1
            } catch {
                lastAttemptError = error
                Self.logger.error("Auto signal failed fan=\(fan.id) error=\(error)")
            }
        }
        
        guard successfulSignals > 0 else {
            customPresetStore.setEnabled(true, fanIDs: previouslyEnabledCustomPresetFanIDs)
            holdingManualOverride = customPresetStore.hasEnabledPresets
            
            if let lastAttemptError {
                presentError(lastAttemptError.localizedDescription)
            }
            
            return
        }
        
        holdingManualOverride = customPresetStore.hasEnabledPresets
        await refresh()
        Self.logger.info("Auto applied fans=\(String(describing: fanIDs))")
    }
    
    func prepareForTermination() async {
        guard !isInstallingPreparedUpdate else { return }
        await resetFansForTermination()
    }
    
    private func resetFansForTermination() async {
        let targetFans = fans
        
        guard !targetFans.isEmpty else { return }
        
        let fanIDs = targetFans.map(\.id)
        let helperStatus = await ensureHelperConnected()
        
        guard let smc = writeService else {
            Self.logger.error("Termination auto reset skipped: no writable SMC client status=\(String(describing: helperStatus))")
            return
        }
        
        customPresetStore.setEnabled(false, fanIDs: fanIDs)
        
        var successfulSignals = 0
        var lastAttemptError: Error?
        
        for fanID in fanIDs {
            do {
                try await smc.setFanAuto(fanID: fanID)
                successfulSignals += 1
            } catch {
                lastAttemptError = error
                Self.logger.error("Termination auto reset failed fan=\(fanID) error=\(error)")
            }
        }
        
        holdingManualOverride = customPresetStore.hasEnabledPresets
        
        if successfulSignals == 0, let lastAttemptError {
            Self.logger.error("Termination auto reset failed error=\(lastAttemptError)")
        }
    }
    
    private func relaunchInstalledApp(at installedAppURL: URL) throws {
        let process = Process()
        process.executableURL = URL(filePath: "/usr/bin/open")
        process.arguments = [installedAppURL.path(percentEncoded: false)]
        try process.run()
    }
    
    private var activeService: SMCService? {
        localSMC ?? remoteSMC
    }
    
    private func startControlAction() -> Int {
        controlActionToken += 1
        endControlAttemptProgress()
        return controlActionToken
    }
    
    func dismissError() {
        errorDismissToken += 1
        errorDismissTask?.cancel()
        clearError()
    }
    
    func copyErrorMessage() {
        guard let message = errorAlert?.message else { return }
        
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(message, forType: .string)
        dismissError()
    }
    
    private func isControlActionCurrent(_ token: Int) -> Bool {
        controlActionToken == token
    }
    
    private var selectedFansForControl: [Fan] {
        if controlsAllFans {
            return fans
        }
        
        guard let selectedFan else { return [] }
        return [selectedFan]
    }
    
    private var selectableFanIDs: [Int] {
        if showsAllFansOption {
            return [allFansID] + fans.map(\.id)
        }
        
        return fans.map(\.id)
    }
    
    private var writeService: SMCService? {
        if let remoteSMC {
            return remoteSMC
        }
        
        return isRoot ? localSMC : nil
    }
    
    private func activeControlMode(
        for fan: Fan,
        presetRPMs: [Double],
        customPreset: FanCustomPreset?
    ) -> FanControlMode? {
        if customPreset?.isEnabled == true, holdingManualOverride {
            return .custom
        }
        
        if (fan.mode == 0 || fan.mode == 3) && !holdingManualOverride {
            return .auto
        }
        
        if Self.rpmMatches(fan.targetRPM, fan.maxRPM) {
            return .max
        }
        
        if Self.rpmMatches(fan.targetRPM, fan.minRPM) {
            return .min
        }
        
        if presetRPMs.contains(where: { Self.rpmMatches(fan.targetRPM, $0) }) {
            return .preset
        }
        
        return nil
    }
    
    private func activeControlModeForAllFans(_ fans: [Fan]) -> FanControlMode? {
        if fans.allSatisfy({ customPresetStore.preset(for: $0.id)?.isEnabled == true }) && holdingManualOverride {
            return .custom
        }
        
        if fans.allSatisfy({ ($0.mode == 0 || $0.mode == 3) && !holdingManualOverride }) {
            return .auto
        }
        
        if fans.allSatisfy({ Self.rpmMatches($0.targetRPM, $0.maxRPM) }) {
            return .max
        }
        
        if fans.allSatisfy({ Self.rpmMatches($0.targetRPM, $0.minRPM) }) {
            return .min
        }
        
        guard let targetRPM = fans.first?.targetRPM else { return nil }
        guard fans.allSatisfy({ Self.rpmMatches($0.targetRPM, targetRPM) }) else { return nil }
        
        let presetRPMs = controlPresetRPMs.map(Double.init)
        
        if presetRPMs.contains(where: { Self.rpmMatches(targetRPM, $0) }) {
            return .preset
        }
        
        return nil
    }
    
    private static func rpmMatches(_ lhs: Double, _ rhs: Double) -> Bool {
        abs(lhs - rhs) <= rpmMatchTolerance
    }
    
    private func applyActiveCustomPresetsIfNeeded(refreshAfterApply: Bool = false) async {
        guard isLicenseActive else { return }
        
        let activeFans: [(Fan, FanCustomPreset)] = fans.compactMap { fan in
            guard let preset = customPresetStore.preset(for: fan.id), preset.isEnabled else { return nil }
            return (fan, preset)
        }
        
        guard !activeFans.isEmpty else { return }
        
        let helperStatus = await ensureHelperConnected()
        
        guard let smc = writeService else {
            setWriteUnavailableError(status: helperStatus)
            return
        }
        
        holdingManualOverride = true
        var successfulSignals = 0
        var lastAttemptError: Error?
        
        for (fan, preset) in activeFans {
            guard let sensor = temperatureSensors.first(where: { $0.key == preset.sensorKey }) else {
                continue
            }
            
            let targetRPM = customPresetStore.targetRPM(
                for: fan,
                sensorTemperature: sensor.celsius,
                minimumTemperature: preset.minimumTemperature,
                maximumTemperature: preset.maximumTemperature
            )
            let needsManualSignal =
            fan.mode == 0 ||
            fan.mode == 3 ||
            !Self.rpmMatches(fan.targetRPM, targetRPM)
            
            guard needsManualSignal else { continue }
            
            do {
                try await smc.setFanManualRPM(fanID: fan.id, rpm: targetRPM)
                successfulSignals += 1
                
                Self.logger.info(
                    "Custom preset tick applied fan=\(fan.id) sensor=\(sensor.key) rpm=\(targetRPM)"
                )
            } catch {
                lastAttemptError = error
                
                Self.logger.error(
                    "Custom preset tick failed fan=\(fan.id) sensor=\(sensor.key) rpm=\(targetRPM) error=\(error)"
                )
            }
        }
        
        if successfulSignals > 0 {
            holdingManualOverride = true
            
            if refreshAfterApply {
                await refresh()
            }
            
            return
        }
        
        if let lastAttemptError {
            presentError(lastAttemptError.localizedDescription)
        }
    }
    
    private func disableCustomPresetsForInactiveLicense() async {
        let activeFanIDs = customPresetStore.activeFanIDs
        
        guard !activeFanIDs.isEmpty else { return }
        
        customPresetStore.setEnabled(false, fanIDs: activeFanIDs)
        holdingManualOverride = customPresetStore.hasEnabledPresets
        
        let helperStatus = await ensureHelperConnected()
        
        guard let smc = writeService else {
            setWriteUnavailableError(status: helperStatus)
            return
        }
        
        var successfulSignals = 0
        var lastAttemptError: Error?
        
        for fanID in activeFanIDs {
            do {
                try await smc.setFanAuto(fanID: fanID)
                successfulSignals += 1
            } catch {
                lastAttemptError = error
                
                Self.logger.error(
                    "Failed to disable custom preset after license deactivation fan=\(fanID) error=\(error)"
                )
            }
        }
        
        holdingManualOverride = customPresetStore.hasEnabledPresets
        
        if successfulSignals > 0 {
            await refresh()
            return
        }
        
        if let lastAttemptError {
            presentError(lastAttemptError.localizedDescription)
        }
    }
    
    private func connectHelperIfAvailable() {
        let service = SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName)
        
        if service.status == .enabled {
            remoteSMC = makeRemoteSMCService()
            Self.logger.info("SMC helper connected")
        } else {
            Self.logger.info("SMC helper status: \(String(describing: service.status))")
        }
        
        updateHelperConnectionStatus(serviceStatus: service.status)
    }
    
    private func makeRemoteSMCService() -> RemoteSMCService {
        RemoteSMCService { [weak self] in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.remoteSMC = nil
                self.updateHelperConnectionStatus()
                Self.logger.info("SMC helper client cleared after disconnect")
            }
        }
    }
    
    private func startAutomaticUpdateChecks() async {
        automaticUpdateTask?.cancel()
        
        automaticUpdateTask = Task { [weak self] in
            guard let self else { return }
            
            while !Task.isCancelled {
                let secondsUntilNextCheck = self.secondsUntilNextAutomaticUpdateCheck()
                
                if secondsUntilNextCheck > 0 {
                    do {
                        try await Task.sleep(for: .seconds(secondsUntilNextCheck))
                    } catch {
                        return
                    }
                }
                
                let didRunCheck = await self.checkForUpdatesOnLaunch()
                guard !didRunCheck else { continue }
                
                do {
                    try await Task.sleep(for: .seconds(Self.automaticUpdateCheckRetrySeconds))
                } catch {
                    return
                }
            }
        }
        
        Self.logger.info("Automatic update checks started")
    }
    
    private func configureAppUpdater() async {
        await appUpdater.setAllowPrereleases(allowsPrereleaseUpdates)
        await appUpdater.setGitHubProxyURL(gitHubProxyURL)
        await appUpdater.setCodeSigningValidation(Self.updateCodeSigningValidation())
    }
    
    private func checkForUpdatesOnLaunch() async -> Bool {
        guard shouldCheckForUpdatesAutomatically else { return false }
        guard !isCheckingForUpdates else { return false }
        await checkForUpdatesAutomatically()
        return true
    }
    
    private func verifySavedLicenseOnLaunch() async {
        guard let savedCredentials = licenseCredentialStore.loadCredentials() else { return }
        licenseEmail = savedCredentials.email
        licenseKey = savedCredentials.licenseKey
        await verifyLicense(
            email: savedCredentials.email,
            licenseKey: savedCredentials.licenseKey,
            shouldSaveCredentials: false
        )
    }
    
    private func checkForUpdatesAutomatically() async {
        guard !isCheckingForUpdates else { return }
        
        let checkDate = Date()
        isCheckingForUpdates = true
        defer {
            isCheckingForUpdates = false
            UserDefaults.standard.set(checkDate, forKey: Self.lastAutomaticUpdateCheckDateDefaultsKey)
        }
        
        do {
            switch try await appUpdater.prepareUpdateIfAvailable() {
            case .upToDate:
                if !showsFakeUpdatePrompt {
                    clearPreparedUpdate()
                }
                
            case .prepared(let preparedUpdate):
                await presentPreparedUpdate(preparedUpdate)
            }
        } catch {
            Self.logger.error("Automatic update check failed: \(error)")
        }
    }
    
    private var shouldCheckForUpdatesAutomatically: Bool {
        guard
            let lastAutomaticUpdateCheckDate = UserDefaults.standard.object(
                forKey: Self.lastAutomaticUpdateCheckDateDefaultsKey
            ) as? Date
        else {
            return true
        }
        
        return Date().timeIntervalSince(lastAutomaticUpdateCheckDate) >= Self.updateCheckIntervalSeconds
    }
    
    private func secondsUntilNextAutomaticUpdateCheck() -> TimeInterval {
        guard
            let lastAutomaticUpdateCheckDate = UserDefaults.standard.object(
                forKey: Self.lastAutomaticUpdateCheckDateDefaultsKey
            ) as? Date
        else {
            return 0
        }
        
        let nextAutomaticUpdateCheckDate = lastAutomaticUpdateCheckDate.addingTimeInterval(
            Self.updateCheckIntervalSeconds
        )
        
        return max(0, nextAutomaticUpdateCheckDate.timeIntervalSinceNow)
    }
    
    private func updatePromptTitle(for versionTag: String) -> String {
        let template = String(localized: "Update %@ available")
        return String(format: template, locale: .current, versionTag)
    }
    
    private func updateAvailableStatusText(for versionTag: String) -> String {
        let template = String(localized: "Update available: %@")
        return String(format: template, locale: .current, versionTag)
    }
    
    private func presentPreparedUpdate(
        _ preparedUpdate: PreparedUpdate
    ) async {
        await setPreparedUpdate(preparedUpdate)
        updateChangelogEntries = await loadUpdateChangelogEntries(for: preparedUpdate.release)
        updateStatusText = updateAvailableStatusText(for: preparedUpdate.release.tagName)
        isUpdatePromptPresented = true
    }
    
    private func setPreparedUpdate(_ preparedUpdate: PreparedUpdate) async {
        if let existingPreparedUpdate = self.preparedUpdate {
            await appUpdater.discardPreparedUpdate(existingPreparedUpdate)
        }
        
        self.preparedUpdate = preparedUpdate
    }
    
    private func clearPreparedUpdate() {
        preparedUpdate = nil
        updateChangelogEntries = []
    }
    
    private func loadUpdateChangelogEntries(for targetRelease: Release) async -> [UpdateChangelogEntry] {
        guard
            let currentVersion = currentAppSemanticVersion(),
            let targetVersion = targetRelease.semanticVersion
        else {
            return [changelogEntry(for: targetRelease)]
        }
        
        do {
            let releases = try await GitHubReleaseProvider(
                session: .shared,
                proxyURL: gitHubProxyURL
            ).releases(
                owner: Self.updateRepositoryOwner,
                repository: Self.updateRepositoryName
            )
            
            let changelogEntries = releases
                .compactMap { release -> (Release, SemanticVersion)? in
                    guard let version = release.semanticVersion else { return nil }
                    return (release, version)
                }
                .filter { release, version in
                    version > currentVersion &&
                    version <= targetVersion &&
                    (allowsPrereleaseUpdates || !release.isPrerelease)
                }
                .sorted { lhs, rhs in
                    lhs.1 > rhs.1
                }
                .map {
                    changelogEntry(for: $0.0)
                }
            
            if changelogEntries.isEmpty {
                return [changelogEntry(for: targetRelease)]
            }
            
            return changelogEntries
        } catch {
            Self.logger.error("Failed to fetch intermediate changelogs: \(error)")
            return [changelogEntry(for: targetRelease)]
        }
    }
    
    private func changelogEntry(for release: Release) -> UpdateChangelogEntry {
        UpdateChangelogEntry(
            tagName: release.tagName,
            isPrerelease: release.isPrerelease,
            notes: releaseNotesText(for: release)
        )
    }
    
    private var gitHubProxyURL: URL? {
        Self.gitHubProxyURL(from: gitHubProxyURLString, isEnabled: usesGitHubProxy)
    }
    
    private static func storedGitHubProxyURL() -> URL? {
        let isEnabled = UserDefaults.standard.bool(forKey: Self.useGitHubProxyDefaultsKey)
        let proxyURLString = UserDefaults.standard.string(forKey: Self.gitHubProxyURLDefaultsKey) ?? Self.defaultGitHubProxyURLString
        return gitHubProxyURL(from: proxyURLString, isEnabled: isEnabled)
    }
    
    private static func gitHubProxyURL(from proxyURLString: String, isEnabled: Bool) -> URL? {
        guard isEnabled else { return nil }
        
        let trimmedProxyURLString = proxyURLString
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard
            let components = URLComponents(string: trimmedProxyURLString),
            let scheme = components.scheme,
            let host = components.host,
            !scheme.isEmpty,
            !host.isEmpty
        else {
            return nil
        }
        
        return components.url
    }
    
    private func currentAppSemanticVersion() -> SemanticVersion? {
        let info = Bundle.main.infoDictionary
        
        guard let version = (
            info?["CFBundleShortVersionString"] as? String ??
            info?["CFBundleVersion"] as? String
        ) else {
            return nil
        }
        
        return try? SemanticVersion(parsing: version)
    }
    
    private func releaseNotesText(for release: Release) -> String {
        let notes = release.body.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if notes.isEmpty {
            return String(localized: "No release notes")
        }
        
        return notes
    }
    
    private func verifyLicense(
        email: String,
        licenseKey: String,
        shouldSaveCredentials: Bool
    ) async {
        guard !isCheckingLicense else { return }
        
        isCheckingLicense = true
        defer { isCheckingLicense = false }
        
        let deviceIdentifier = MacDeviceIdentityProvider.deviceIdentifier()
        let osVersion = MacDeviceIdentityProvider.osVersion()
        
        do {
            let verifiedAt = Date()
            
            let result = try await licenseVerificationService.verify(
                email: email,
                licenseKey: licenseKey,
                deviceName: deviceName,
                deviceIdentifier: deviceIdentifier,
                os: osVersion
            )
            
            licenseCredentialStore.saveLastCheck(reason: result.reason, date: verifiedAt)
            licenseStatusText = Self.licenseStatusText(reason: result.reason, date: verifiedAt)
            isLicenseActive = result.valid
            
            if result.reason == .active {
                licenseCredentialStore.saveLastActiveValidationDate(verifiedAt)
            } else {
                licenseCredentialStore.clearLastActiveValidationDate()
            }
            
            if shouldSaveCredentials, result.valid {
                try licenseCredentialStore.saveCredentials(
                    email: email,
                    licenseKey: licenseKey
                )
            }
        } catch {
            if applyOfflineGracePeriodIfAvailable() {
                return
            }
            
            isLicenseActive = false
            licenseStatusText = expiredLicenseGracePeriodStatusText() ?? String(localized: "License check failed")
            presentError(error.localizedDescription)
        }
    }
    
    private func loadStoredLicenseState() {
        guard let savedCredentials = licenseCredentialStore.loadCredentials() else {
            licenseStatusText = String(localized: "No saved license")
            isLicenseActive = false
            return
        }
        
        licenseEmail = savedCredentials.email
        licenseKey = savedCredentials.licenseKey
        licenseStatusText = String(localized: "Saved license will be checked on launch")
        
        if let reason = licenseCredentialStore.loadLastCheckReason(),
           let date = licenseCredentialStore.loadLastCheckDate() {
            licenseStatusText = Self.licenseStatusText(reason: reason, date: date)
            isLicenseActive = reason == .active
        }
        
        if isLicenseActive {
            if !applyOfflineGracePeriodIfAvailable() {
                isLicenseActive = false
                licenseStatusText = expiredLicenseGracePeriodStatusText() ?? String(localized: "License check required")
            }
        }
    }
    
    private static func licenseStatusText(reason: LicenseVerificationReason, date: Date) -> String {
        let checkedAtText = date.formatted(date: .abbreviated, time: .shortened)
        return "\(reason.localizedStatusText) (\(checkedAtText))"
    }
    
    private func applyOfflineGracePeriodIfAvailable() -> Bool {
        guard let lastActiveValidationDate = licenseCredentialStore.loadLastActiveValidationDate() else {
            return false
        }
        
        let gracePeriodDeadline = lastActiveValidationDate.addingTimeInterval(Self.licenseOfflineGracePeriodSeconds)
        let now = Date()
        
        guard now <= gracePeriodDeadline else {
            return false
        }
        
        isLicenseActive = true
        
        licenseStatusText = Self.offlineGracePeriodStatusText(
            lastActiveValidationDate: lastActiveValidationDate,
            gracePeriodDeadline: gracePeriodDeadline
        )
        
        return true
    }
    
    private func expiredLicenseGracePeriodStatusText() -> String? {
        guard let lastActiveValidationDate = licenseCredentialStore.loadLastActiveValidationDate() else {
            return nil
        }
        
        let gracePeriodDeadline = lastActiveValidationDate.addingTimeInterval(Self.licenseOfflineGracePeriodSeconds)
        guard Date() > gracePeriodDeadline else { return nil }
        
        return Self.offlineGracePeriodExpiredStatusText(gracePeriodDeadline: gracePeriodDeadline)
    }
    
    private static func offlineGracePeriodStatusText(
        lastActiveValidationDate: Date,
        gracePeriodDeadline: Date
    ) -> String {
        let lastVerifiedText = lastActiveValidationDate.formatted(date: .abbreviated, time: .shortened)
        let deadlineText = gracePeriodDeadline.formatted(date: .abbreviated, time: .shortened)
        
        return String(
            localized: "License active offline until \(deadlineText) (last verified \(lastVerifiedText))"
        )
    }
    
    private static func offlineGracePeriodExpiredStatusText(gracePeriodDeadline: Date) -> String {
        let deadlineText = gracePeriodDeadline.formatted(date: .abbreviated, time: .shortened)
        
        return String(
            localized: "License deactivated after no verification for 7 days (deadline \(deadlineText))"
        )
    }
    
    private func ensureHelperConnected() async -> SMAppService.Status {
        if remoteSMC != nil {
            updateHelperConnectionStatus(serviceStatus: .enabled)
            return .enabled
        }
        
        let service = SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName)
        
        guard !helperInstallInProgress else {
            updateHelperConnectionStatus(serviceStatus: service.status)
            return service.status
        }
        
        helperInstallInProgress = true
        defer { helperInstallInProgress = false }
        
        switch service.status {
        case .requiresApproval:
            updateHelperConnectionStatus(serviceStatus: service.status)
            return service.status
            
        case .enabled, .notFound, .notRegistered:
            break
            
        @unknown default:
            updateHelperConnectionStatus(serviceStatus: service.status)
            return service.status
        }
        
        do {
            let status = try SMCHelperInstaller.registerIfNeeded()
            Self.logger.info("SMC helper register status: \(String(describing: status))")
            
            if status == .enabled {
                remoteSMC = makeRemoteSMCService()
            }
            
            updateHelperConnectionStatus(serviceStatus: status)
            
            return status
        } catch {
            presentError(error.localizedDescription)
            Self.logger.error("SMC helper register failed: \(error)")
            
            updateHelperConnectionStatus(serviceStatus: service.status)
            return service.status
        }
    }
    
    private func updateHelperConnectionStatus(serviceStatus: SMAppService.Status? = nil) {
        if isRoot, localSMC != nil {
            helperConnectionStatus = .runningAsRoot
            return
        }
        
        if remoteSMC != nil {
            helperConnectionStatus = .connected
            return
        }
        
        switch serviceStatus ?? SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName).status {
        case .enabled:
            helperConnectionStatus = .enabled
            
        case .requiresApproval:
            helperConnectionStatus = .requiresApproval
            
        case .notFound:
            helperConnectionStatus = .notFound
            
        case .notRegistered:
            helperConnectionStatus = .notRegistered
            
        @unknown default:
            helperConnectionStatus = .unavailable
        }
    }
    
    private func setWriteUnavailableError(status: SMAppService.Status) {
        if isRoot {
            return
        }
        
        let message: String
        
        switch status {
        case .requiresApproval:
            message = String(localized: "Helper needs approval in System Settings > General > Login Items > Allow in Background")
            
        case .notFound:
            let bundlePath = Bundle.main.bundleURL.path
            
            let helperPath = Bundle.main.bundleURL
                .appendingPathComponent("Contents/Library/PrivilegedHelperTools/FanControlHelper")
                .path
            
            let plistPath = Bundle.main.bundleURL
                .appendingPathComponent(
                    "Contents/Library/LaunchDaemons/\(FanControlXPCConstants.launchdPlistName)"
                )
                .path
            
            let systemHelperPath = "/Library/PrivilegedHelperTools/FanControlHelper"
            let systemPlistPath = "/Library/LaunchDaemons/\(FanControlXPCConstants.launchdPlistName)"
            let fm = FileManager.default
            let helperExists = fm.fileExists(atPath: helperPath)
            let plistExists = fm.fileExists(atPath: plistPath)
            let systemHelperExists = fm.fileExists(atPath: systemHelperPath)
            let systemPlistExists = fm.fileExists(atPath: systemPlistPath)
            
            let template = String(
                localized: """
Helper not found in app bundle
Bundle: %@
Helper exists: %@
Plist exists: %@
System helper exists: %@
System plist exists: %@
"""
            )
            
            message = String(
                format: template,
                locale: .current,
                bundlePath,
                String(describing: helperExists),
                String(describing: plistExists),
                String(describing: systemHelperExists),
                String(describing: systemPlistExists)
            )
            
        case .notRegistered:
            message = String(localized: "Helper not registered. Run from /Applications and try again")
            
        case .enabled:
            message = String(localized: "Helper connected but no writable SMC client is available")
            
        @unknown default:
            message = String(localized: "Helper status unknown. Try again after approving or reinstalling")
        }
        
        presentError(message)
    }
    
    private func presentError(_ message: String) {
        let now = Date()
        
        if message == errorAlert?.message, let errorExpiryDate, now < errorExpiryDate {
            return
        }
        
        errorDismissToken += 1
        let dismissToken = errorDismissToken
        
        errorDismissTask?.cancel()
        
        errorExpiryDate = now.addingTimeInterval(Self.errorDisplaySeconds)
        errorAlert = ErrorAlert(message: message)
        
        errorDismissTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: Self.errorDisplayDuration)
            } catch {
                return
            }
            
            guard let self, self.errorDismissToken == dismissToken else { return }
            self.clearError()
        }
    }
    
    private func clearError() {
        errorAlert = nil
        errorExpiryDate = nil
    }

    private func shouldReadFansNow(at now: Date = Date()) -> Bool {
        now >= nextFanReadDate
    }

    private func deferFanReads(for seconds: TimeInterval, from now: Date = Date()) {
        nextFanReadDate = max(nextFanReadDate, now.addingTimeInterval(seconds))
    }

    private func resetFanReadBackoff() {
        nextFanReadDate = .distantPast
    }
    
    private func beginControlAttemptProgress(targetMode: FanControlMode) {
        isSendingControlAttempts = true
        controlAttemptTargetMode = targetMode
    }
    
    private func endControlAttemptProgress() {
        isSendingControlAttempts = false
        controlAttemptTargetMode = nil
    }
}
