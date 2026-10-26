import ScrechKit

struct RemoteTimerSectionView: View {
    let mac: RemoteMacState
    @State private var fanID = RemoteFanCommand.allFansID
    @State private var draft = FanSpeedTimerDraft()
    @Environment(RemoteControlViewModel.self) private var model

    var body: some View {
        Section {
            if mac.fans.contains(where: { $0.timerEndDate != nil }) {
                ForEach(mac.fans.filter { $0.timerEndDate != nil }) {
                    RemoteTimerStatusView(fan: $0)
                }

                Button("Cancel timer") {
                    Task {
                        await model.send(action: .cancelTimer, fanID: RemoteFanCommand.allFansID, to: mac)
                    }
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .disabled(!mac.isOnline || model.isSendingCommand)
            } else if mac.fans.allSatisfy({ $0.supportsTimers == true }), !mac.fans.isEmpty {
                Picker("Fans", selection: $fanID) {
                    Text("All fans")
                        .tag(RemoteFanCommand.allFansID)

                    ForEach(mac.fans) {
                        Text("Fan \($0.id + 1)")
                            .tag($0.id)
                    }
                }

                if let range = model.timerRPMRange(fanID: fanID, in: mac) {
                    RemoteTimerEditorView(draft: $draft, rpmRange: range)

                    Button("Start timer on Mac") {
                        Task {
                            await model.startTimer(draft, fanID: fanID, on: mac)
                        }
                    }
                    .buttonStyle(.bordered)
                    .foregroundStyle(.primary)
                    .disabled(!mac.isOnline || model.isSendingCommand ||
                              !draft.isValid(minimumRPM: range.lowerBound, maximumRPM: range.upperBound))
                }
            } else {
                Text("Update FanControl on your Mac to use remote timers")
                    .secondary()
            }
        } header: {
            RemoteTimerHeaderView(endDate: mac.fans.compactMap(\.timerEndDate).first)
        }
        .onChange(of: model.timerRPMRange(fanID: fanID, in: mac), initial: true) {
            guard let range = model.timerRPMRange(fanID: fanID, in: mac) else { return }
            draft.rpm = min(max(draft.rpm, range.lowerBound), range.upperBound)
        }
    }
}
