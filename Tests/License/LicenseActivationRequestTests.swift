import Foundation
import Testing
@testable import FanControl

struct LicenseActivationRequestTests {
    @Test func decodedCredentials() throws {
        let url = try #require(URL(string: "fancontrol://activate?email=buyer%2Btag%26other%40example.com&licenseKey=FAN-ABCDE-12345-ABCDE-12345-ABCDE"))
        let request = try #require(LicenseActivationRequest(url: url))
        #expect(request.email == "buyer+tag&other@example.com")
        #expect(request.licenseKey == "FAN-ABCDE-12345-ABCDE-12345-ABCDE")
    }

    @Test(arguments: [
        "https://activate?email=buyer@example.com&licenseKey=FAN-TEST",
        "fancontrol://other?email=buyer@example.com&licenseKey=FAN-TEST",
        "fancontrol://activate/path?email=buyer@example.com&licenseKey=FAN-TEST",
        "fancontrol://activate?email=buyer@example.com",
        "fancontrol://activate?email=buyer@example.com&licenseKey=",
        "fancontrol://activate?email=buyer@example.com&email=other@example.com&licenseKey=FAN-TEST",
        "fancontrol://activate?email=buyer@example.com&licenseKey=FAN-TEST&licenseKey=OTHER",
        "fancontrol://user@activate?email=buyer@example.com&licenseKey=FAN-TEST",
        "fancontrol://activate?email=invalid&licenseKey=FAN-TEST"
    ])
    func rejectedURLs(_ value: String) throws {
        let url = try #require(URL(string: value))
        #expect(LicenseActivationRequest(url: url) == nil)
    }
}
