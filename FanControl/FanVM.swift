import ServiceManagement
import OSLog
import Darwin
import CoreSMC
import AutoUpdate

@Observable
final class FanVM {
    private static let updateRepositoryOwner = "TopScrech"
    private static let updateRepositoryName = "FanControl"
    private static let allFansSelectionID = -1
    private static let selectedFanIDDefaultsKey = "selectedFanID"
    private static let allowPrereleaseUpdatesDefaultsKey = "allowPrereleaseUpdates"
    private static let manualRetryAttempts = 15
    private static let manualRetryInterval: Duration = .seconds(1)
    private static let presetStepRPM = 500
    private static let rpmMatchTolerance = 1.0
    private static let errorDisplaySeconds = 5.0
    private static let errorDisplayDuration: Duration = .seconds(errorDisplaySeconds)
    private static let updateCheckIntervalSeconds = 24.0 * 60 * 60
    
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
    
    var errorText: String?
    let processorName: String
    
    var appVersionDescription: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? String(localized: "Unknown")
        
        guard version.hasPrefix("v") else { return "v\(version)" }
        return version
    }
    
    var updatePromptTitle: String {
        String(localized: "Update available")
    }
    
    var updatePromptSummary: String {
        let template = String(localized: "Version %@ is ready. Do you want to install it now?")
        return String(format: template, locale: .current, updateTargetVersionTag)
    }
    
    var updateTargetVersionTag: String {
        if showsFakeUpdatePrompt {
            return "v9.9.9-debug"
        }
        
        return preparedUpdate?.release.tagName ?? String(localized: "Unknown")
    }
    
    private static let logger = Logger(subsystem: "FanControl", category: "FanVM")
    private let localSMC: LocalSMCService?
    private var remoteSMC: RemoteSMCService?
    private let temperatureSensorService = ISMCTemperatureSensorService()
    private let appUpdater = AppUpdater(owner: FanVM.updateRepositoryOwner, repository: FanVM.updateRepositoryName)
    private var preparedUpdate: PreparedUpdate?
    private var showsFakeUpdatePrompt = false
    private var automaticUpdateTask: Task<Void, Never>?
    private var timer: Timer?
    private var holdingManualOverride = false
    private var helperInstallInProgress = false
    private var controlActionToken = 0
    private var errorDismissToken = 0
    private var errorDismissTask: Task<Void, Never>?
    private var errorExpiryDate: Date?
    private let isRoot = geteuid() == 0
    
    init() {
        processorName = Self.detectProcessorName()
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
            Self.logger.error("Local SMC client init failed: \(error.localizedDescription)")
        }
        
        if localSMC == nil {
            if let localError {
                presentError(localError)
            }
        }
        
        connectHelperIfAvailable()
        
        Task {
            await appUpdater.setAllowPrereleases(allowsPrereleaseUpdates)
            await startAutomaticUpdateChecks()
            await checkForUpdatesOnLaunch()
            await refresh()
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
    
    var allFansID: Int {
        Self.allFansSelectionID
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
    
    var activeControlMode: FanControlMode? {
        let targetFans = selectedFansForControl
        guard !targetFans.isEmpty else { return nil }
        
        if controlsAllFans {
            return activeControlModeForAllFans(targetFans)
        }
        
        let presetRPMs = controlPresetRPMs.map(Double.init)
        
        let fanModes = targetFans.compactMap {
            activeControlMode(for: $0, presetRPMs: presetRPMs)
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
    
    nonisolated private static func detectProcessorName() -> String {
        if let hardwareOverview = loadHardwareOverview() {
            let machineName = hardwareOverview.machineName?.trimmingCharacters(in: .whitespacesAndNewlines)
            let rawMachineModel = hardwareOverview.machineModel?.trimmingCharacters(in: .whitespacesAndNewlines)
            let machineModel = rawMachineModel.map(formatMachineModelIdentifier)
            
            let chipName = normalizeChipName(
                hardwareOverview.chipType ?? sysctlString("machdep.cpu.brand_string")
            )
            
            let modelSize = rawMachineModel.flatMap { macBookSizeLabel(for: $0) }
            
            if let machineName, !machineName.isEmpty, let chipName, !chipName.isEmpty {
                let deviceName: String
                
                if let modelSize, !modelSize.isEmpty {
                    deviceName = "\(machineName) \(modelSize) \(chipName)"
                } else {
                    deviceName = "\(machineName) \(chipName)"
                }
                
                if let machineModel, !machineModel.isEmpty {
                    return "\(deviceName) (\(machineModel))"
                }
                
                return deviceName
            }
        }
        
        if let processorName = sysctlString("machdep.cpu.brand_string") {
            return processorName
        }
        
        if let processorName = sysctlString("hw.model") {
            return formatMachineModelIdentifier(processorName)
        }
        
        if let processorName = sysctlString("hw.machine") {
            return processorName
        }
        
        return String(localized: "Unknown processor")
    }
    
    nonisolated private static func sysctlString(_ name: String) -> String? {
        var size = 0
        guard sysctlbyname(name, nil, &size, nil, 0) == 0, size > 1 else { return nil }
        
        var buffer = [CChar](repeating: 0, count: size)
        guard sysctlbyname(name, &buffer, &size, nil, 0) == 0 else { return nil }
        
        let value = String(cString: buffer).trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
    
    nonisolated private static func loadHardwareOverview() -> HardwareOverview? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
        process.arguments = ["SPHardwareDataType", "-json"]
        
        let stdoutPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = Pipe()
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }
        
        guard process.terminationStatus == 0 else { return nil }
        
        let data = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        
        guard
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let rows = object["SPHardwareDataType"] as? [[String: Any]],
            let first = rows.first
        else {
            return nil
        }
        
        return HardwareOverview(
            machineName: first["machine_name"] as? String,
            chipType: first["chip_type"] as? String ?? first["cpu_type"] as? String,
            machineModel: first["machine_model"] as? String
        )
    }
    
    nonisolated private static func normalizeChipName(_ rawValue: String?) -> String? {
        guard let rawValue else { return nil }
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        
        if value.hasPrefix("Apple ") {
            return String(value.dropFirst("Apple ".count))
        }
        
        return value
    }
    
    nonisolated private static func formatMachineModelIdentifier(_ rawValue: String) -> String {
        guard let firstDigitIndex = rawValue.firstIndex(where: \.isNumber) else { return rawValue }
        let prefix = rawValue[..<firstDigitIndex]
        let suffix = rawValue[firstDigitIndex...]
        return "\(prefix) \(suffix)"
    }
    
    nonisolated private static func macBookSizeLabel(for machineModel: String) -> String? {
        switch machineModel {
        case "Mac15,3", "Mac15,4", "Mac15,5", "Mac15,6", "Mac15,7", "Mac15,8", "Mac15,9", "Mac16,3", "Mac16,5": "16"
        case "Mac14,5", "Mac14,9", "Mac14,10", "Mac15,10", "Mac16,1", "Mac16,2", "Mac16,4": "14"
        case "Mac14,2", "Mac14,15", "Mac15,12", "Mac15,13": "13"
        default: nil
        }
    }
    
    private struct HardwareOverview {
        let machineName: String?
        let chipType: String?
        let machineModel: String?
    }
    
    func tick() async {
        if holdingManualOverride, let smc = writeService {
            do {
                try await smc.keepAliveManualOverride()
            } catch {
                presentError(error.localizedDescription)
                Self.logger.error("Manual keep-alive failed: \(error.localizedDescription)")
            }
        }
        
        await refresh()
    }
    
    func refresh() async {
        Self.logger.info("Refresh starting")
        
        var refreshError: Error?
        
        if let smc = activeService {
            do {
                let snapshots = try await smc.readFans()
                Self.logger.info("Refresh readFans count=\(snapshots.count)")
                fans = snapshots
                
                if fans.isEmpty {
                    selectedFanID = Self.allFansSelectionID
                } else if !controlsAllFans, !fans.contains(where: { $0.id == selectedFanID }) {
                    selectedFanID = fans[0].id
                }
            } catch {
                refreshError = error
                Self.logger.error("Refresh readFans failed: \(error.localizedDescription)")
            }
        } else {
            Self.logger.info("Refresh fan read skipped: no active SMC service")
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
            Self.logger.error("Refresh readTemperatureSensors failed: \(error.localizedDescription)")
        }
        
        if let refreshError {
            presentError(refreshError.localizedDescription)
        }
    }
    
    func checkForUpdatesNow() async {
        guard !isCheckingForUpdates else { return }
        
        isCheckingForUpdates = true
        updateStatusText = String(localized: "Checking for updates")
        defer { isCheckingForUpdates = false }
        
        do {
            switch try await appUpdater.prepareUpdateIfAvailable() {
            case .upToDate:
                clearPreparedUpdate()
                updateStatusText = String(localized: "You are on the latest version")
                Self.logger.info("Update check: already on latest version")
                
            case .prepared(let preparedUpdate):
                await setPreparedUpdate(preparedUpdate)
                updateChangelogEntries = await loadUpdateChangelogEntries(for: preparedUpdate.release)
                let template = String(localized: "Update available: %@")
                updateStatusText = String(format: template, locale: .current, preparedUpdate.release.tagName)
                Self.logger.info("Update prepared tag=\(preparedUpdate.release.tagName)")
                isUpdatePromptPresented = true
            }
        } catch {
            updateStatusText = String(localized: "Update failed")
            Self.logger.error("Update check failed: \(error.localizedDescription)")
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
            try await appUpdater.installAndRelaunch(preparedUpdate)
        } catch {
            await appUpdater.discardPreparedUpdate(preparedUpdate)
            clearPreparedUpdate()
            updateStatusText = String(localized: "Update failed")
            Self.logger.error("Update install failed: \(error.localizedDescription)")
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
    
    func setSettingsOpen(_ isOpen: Bool) {
        isSettingsOpen = isOpen
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
            )
        ]
        
        isUpdatePromptPresented = true
    }
    
    func setManualRPM(_ rpm: Double, targetMode: FanControlMode = .preset) async {
        await applyManualRPM(
            requestSummary: "Manual request rpm=\(rpm)",
            actionSummary: "Manual applied rpm=\(rpm)",
            targetMode: targetMode
        ) { _ in
            rpm
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
        
        let helperStatus = await ensureHelperConnected()
        
        guard let smc = writeService else {
            setWriteUnavailableError(status: helperStatus)
            Self.logger.info("Manual request ignored: no writable SMC client")
            return
        }
        
        do {
            let fanIDs = targetFans.map(\.id)
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
                        Self.logger.error("Manual signal failed fan=\(fan.id) rpm=\(rpm) attempt=\(attempt) error=\(error.localizedDescription)")
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
                if let lastAttemptError {
                    presentError(lastAttemptError.localizedDescription)
                }
                
                return
            }
            
            holdingManualOverride = true
            await refresh()
            Self.logger.info("\(actionSummary) fans=\(String(describing: fanIDs)) signals=\(successfulSignals)")
            
        } catch is CancellationError {
            Self.logger.info("Manual retries canceled")
            
        } catch {
            Self.logger.error("Manual failed error=\(error.localizedDescription)")
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
        
        let helperStatus = await ensureHelperConnected()
        
        guard let smc = writeService else {
            setWriteUnavailableError(status: helperStatus)
            Self.logger.info("Auto request ignored: missing writable SMC client")
            return
        }
        
        let fanIDs = targetFans.map(\.id)
        var successfulSignals = 0
        var lastAttemptError: Error?
        
        Self.logger.info("Auto request fans=\(String(describing: fanIDs))")
        
        for fan in targetFans {
            do {
                try await smc.setFanAuto(fanID: fan.id)
                successfulSignals += 1
            } catch {
                lastAttemptError = error
                Self.logger.error("Auto signal failed fan=\(fan.id) error=\(error.localizedDescription)")
            }
        }
        
        guard successfulSignals > 0 else {
            if let lastAttemptError {
                presentError(lastAttemptError.localizedDescription)
            }
            
            return
        }
        
        holdingManualOverride = false
        await refresh()
        Self.logger.info("Auto applied fans=\(String(describing: fanIDs))")
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
    
    private var writeService: SMCService? {
        if let remoteSMC {
            return remoteSMC
        }
        
        return isRoot ? localSMC : nil
    }
    
    private func activeControlMode(for fan: Fan, presetRPMs: [Double]) -> FanControlMode? {
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
    
    private func connectHelperIfAvailable() {
        let service = SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName)
        
        if service.status == .enabled {
            remoteSMC = RemoteSMCService()
            Self.logger.info("SMC helper connected")
        } else {
            Self.logger.info("SMC helper status: \(String(describing: service.status))")
        }
    }
    
    private func startAutomaticUpdateChecks() async {
        automaticUpdateTask?.cancel()
        
        automaticUpdateTask = Task { [weak self] in
            guard let self else { return }
            
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(Self.updateCheckIntervalSeconds))
                } catch {
                    return
                }
                
                await self.checkForUpdatesAutomatically()
            }
        }
        
        Self.logger.info("Automatic update checks started")
    }
    
    private func checkForUpdatesOnLaunch() async {
        await checkForUpdatesAutomatically()
    }
    
    private func checkForUpdatesAutomatically() async {
        guard !isCheckingForUpdates else { return }
        
        isCheckingForUpdates = true
        defer { isCheckingForUpdates = false }
        
        do {
            switch try await appUpdater.prepareUpdateIfAvailable() {
            case .upToDate:
                if preparedUpdate == nil {
                    updateStatusText = String(localized: "You are on the latest version")
                }
                
            case .prepared(let preparedUpdate):
                await setPreparedUpdate(preparedUpdate)
                updateChangelogEntries = await loadUpdateChangelogEntries(for: preparedUpdate.release)
                let template = String(localized: "Update available: %@")
                updateStatusText = String(format: template, locale: .current, preparedUpdate.release.tagName)
                isUpdatePromptPresented = true
            }
        } catch {
            Self.logger.error("Automatic update check failed: \(error.localizedDescription)")
        }
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
            let releases = try await GitHubReleaseProvider(session: .shared).releases(
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
                    lhs.1 < rhs.1
                }
                .map {
                    changelogEntry(for: $0.0)
                }
            
            if changelogEntries.isEmpty {
                return [changelogEntry(for: targetRelease)]
            }
            
            return changelogEntries
        } catch {
            Self.logger.error("Failed to fetch intermediate changelogs: \(error.localizedDescription)")
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
    
    private func ensureHelperConnected() async -> SMAppService.Status {
        if remoteSMC != nil {
            return .enabled
        }
        
        let service = SMAppService.daemon(plistName: FanControlXPCConstants.launchdPlistName)
        
        guard !helperInstallInProgress else { return service.status }
        
        helperInstallInProgress = true
        defer { helperInstallInProgress = false }
        
        switch service.status {
        case .enabled:
            remoteSMC = RemoteSMCService()
            return service.status
            
        case .requiresApproval:
            return service.status
            
        case .notFound, .notRegistered:
            break
            
        @unknown default:
            return service.status
        }
        
        do {
            let status = try SMCHelperInstaller.registerIfNeeded()
            Self.logger.info("SMC helper register status: \(String(describing: status))")
            
            if status == .enabled {
                remoteSMC = RemoteSMCService()
            }
            
            return status
        } catch {
            presentError(error.localizedDescription)
            Self.logger.error("SMC helper register failed: \(error.localizedDescription)")
            return service.status
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
        
        if message == errorText, let errorExpiryDate, now < errorExpiryDate {
            return
        }
        
        errorDismissToken += 1
        let dismissToken = errorDismissToken
        
        errorDismissTask?.cancel()
        
        errorExpiryDate = now.addingTimeInterval(Self.errorDisplaySeconds)
        errorText = message
        
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
        errorText = nil
        errorExpiryDate = nil
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
