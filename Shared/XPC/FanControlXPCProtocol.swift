import Foundation

@objc(FanControlXPCProtocol)
nonisolated protocol FanControlXPCProtocol {
    func componentInfo(withReply reply: @escaping @Sendable (Int, String) -> Void)
    func readTemperatures(withReply reply: @escaping @Sendable (String?, String?) -> Void)
    func prepareForUpdate(withReply reply: @escaping @Sendable (String?) -> Void)
    func readFans(withReply reply: @escaping @Sendable ([FanSnapshot]?, String?) -> Void)
    func setManualRPM(fanID: Int, rpm: Double, withReply reply: @escaping @Sendable (String?) -> Void)
    func setAuto(fanID: Int, withReply reply: @escaping @Sendable (String?) -> Void)
    func keepAliveManualOverride(withReply reply: @escaping @Sendable (String?) -> Void)
}
