import CoreSMC
import Foundation
import OSLog

@MainActor
final class FanControlEngine {
    private let smc: (any ComponentFanHardware)?
    private let initializationError: Error?
    private var owner: UUID?
    private var controlledFans = Set<Int>()
    private var lastHeartbeat = ContinuousClock.now
    private var isPreparingForUpdate = false
    private let logger = Logger(subsystem: "FanControl", category: "Component")

    init() {
        do {
            smc = try SMCFanController()
            initializationError = nil
        } catch {
            smc = nil
            initializationError = error
        }
    }

    init(controller: any ComponentFanHardware) {
        smc = controller
        initializationError = nil
    }

    func readFans() throws -> [Fan] { try controller().readFans() }

    func setManualRPM(owner: UUID, fanID: Int, rpm: Double) throws {
        guard !isPreparingForUpdate else { throw failure("Component is preparing for an update") }
        guard self.owner == nil || self.owner == owner else { throw failure("Another FanControl client is controlling the fans") }
        let smc = try controller()
        guard rpm.isFinite, let fan = try smc.readFans().first(where: { $0.id == fanID }),
              rpm >= fan.minRPM, rpm <= fan.maxRPM else {
            throw failure("Fan speed must be within the fan's supported range")
        }
        self.owner = owner
        lastHeartbeat = .now
        // Track before writing: a failed write may still have changed the mode
        controlledFans.insert(fanID)
        do { try smc.setFanManualRPM(fanID: fanID, rpm: rpm) }
        catch {
            restore(owner: owner)
            throw error
        }
    }

    func setAuto(owner: UUID, fanID: Int) throws {
        guard self.owner == nil || self.owner == owner else { throw failure("Another FanControl client is controlling the fans") }
        let smc = try controller()
        guard try smc.readFans().contains(where: { $0.id == fanID }) else { throw failure("Unknown fan") }
        try smc.setFanAuto(fanID: fanID)
        controlledFans.remove(fanID)
        if controlledFans.isEmpty { self.owner = nil }
    }

    func keepAlive(owner: UUID) throws {
        guard self.owner == owner, !isPreparingForUpdate else { return }
        try controller().keepAliveManualOverride()
        lastHeartbeat = .now
    }

    func checkLease(now: ContinuousClock.Instant = .now) {
        if !controlledFans.isEmpty, lastHeartbeat.duration(to: now) > .seconds(10) {
            restoreAll()
        }
    }

    func restore(owner: UUID) {
        guard self.owner == owner else { return }
        restoreAll()
    }

    func prepareForUpdate() throws {
        isPreparingForUpdate = true
        restoreAll()
        guard controlledFans.isEmpty else {
            isPreparingForUpdate = false
            throw failure("Could not restore automatic fan control — try again before updating")
        }
    }

    func restoreAll() {
        for fanID in controlledFans {
            do {
                try controller().setFanAuto(fanID: fanID)
                controlledFans.remove(fanID)
            } catch {
                logger.error("Automatic fan restoration failed for fan \(fanID): \(error)")
            }
        }
        if controlledFans.isEmpty { owner = nil }
    }

    private func controller() throws -> any ComponentFanHardware {
        guard let smc else { throw initializationError ?? failure("SMC unavailable") }
        return smc
    }

    private func failure(_ description: String) -> NSError {
        NSError(domain: "FanControlComponent", code: 1, userInfo: [NSLocalizedDescriptionKey: description])
    }
}
