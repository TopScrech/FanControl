import Foundation

@objc(FanControlXPCProtocol)
protocol FanControlXPCProtocol {
    func readFans(withReply reply: @escaping ([FanSnapshot]?, String?) -> Void)
    func readTemperatureSensors(withReply reply: @escaping ([TemperatureSensorSnapshot]?, String?) -> Void)
    func setManualRPM(fanID: Int, rpm: Double, withReply reply: @escaping (String?) -> Void)
    func setAuto(fanID: Int, withReply reply: @escaping (String?) -> Void)
    func keepAliveManualOverride(withReply reply: @escaping (String?) -> Void)
}
