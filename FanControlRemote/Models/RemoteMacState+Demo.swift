import Foundation

extension RemoteMacState {
    static var demoMacBookPro: RemoteMacState {
        RemoteMacState(
            id: "demo-macbook-pro-16-m6-max",
            name: "MacBook Pro 16-inch (M6 Max)",
            updatedAt: .now,
            fans: [
                RemoteFanState(
                    id: 0,
                    minRPM: 1_200,
                    maxRPM: 6_800,
                    currentRPM: 2_320,
                    targetRPM: 2_320,
                    mode: 0,
                    activeAction: .automatic
                ),
                RemoteFanState(
                    id: 1,
                    minRPM: 1_200,
                    maxRPM: 6_800,
                    currentRPM: 2_180,
                    targetRPM: 2_180,
                    mode: 0,
                    activeAction: .automatic
                ),
            ]
        )
    }
}
