import Foundation

final class FanControlHelperService: NSObject, FanControlXPCProtocol, Sendable {
    let owner = UUID()
    private let engine: FanControlEngine
    private let temperatures: ComponentTemperatureReader

    init(engine: FanControlEngine, temperatures: ComponentTemperatureReader) {
        self.engine = engine
        self.temperatures = temperatures
    }

    func componentInfo(withReply reply: @escaping @Sendable (Int, String) -> Void) {
        reply(ComponentConfiguration.protocolVersion, ComponentConfiguration.version)
    }

    func readTemperatures(withReply reply: @escaping @Sendable (String?, String?) -> Void) {
        Task {
            do { reply(try await temperatures.read(), nil) }
            catch { reply(nil, error.localizedDescription) }
        }
    }

    func readFans(withReply reply: @escaping @Sendable ([FanSnapshot]?, String?) -> Void) {
        Task { @MainActor in
            do { reply(try engine.readFans().map(FanSnapshot.init(fan:)), nil) }
            catch { reply(nil, error.localizedDescription) }
        }
    }

    func setManualRPM(fanID: Int, rpm: Double, withReply reply: @escaping @Sendable (String?) -> Void) {
        Task { @MainActor in
            do { try engine.setManualRPM(owner: owner, fanID: fanID, rpm: rpm); reply(nil) }
            catch { reply(error.localizedDescription) }
        }
    }

    func setAuto(fanID: Int, withReply reply: @escaping @Sendable (String?) -> Void) {
        Task { @MainActor in
            do { try engine.setAuto(owner: owner, fanID: fanID); reply(nil) }
            catch { reply(error.localizedDescription) }
        }
    }

    func keepAliveManualOverride(withReply reply: @escaping @Sendable (String?) -> Void) {
        Task { @MainActor in
            do { try engine.keepAlive(owner: owner); reply(nil) }
            catch { reply(error.localizedDescription) }
        }
    }

    func prepareForUpdate(withReply reply: @escaping @Sendable (String?) -> Void) {
        Task { @MainActor in
            do { try engine.prepareForUpdate(); reply(nil) }
            catch { reply(error.localizedDescription) }
        }
    }
}
