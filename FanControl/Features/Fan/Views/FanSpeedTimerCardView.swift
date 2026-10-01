import ScrechKit

struct FanSpeedTimerCardView: View {
    @Environment(FanVM.self) private var model

    @State private var draft = FanSpeedTimerDraft()
    @State private var isExpanded = false

    private var canCreateTimer: Bool {
        model.isLicenseActive && model.fanSpeedTimer == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            FanSpeedTimerHeaderView(
                isExpandable: canCreateTimer,
                isExpanded: $isExpanded
            )

            if let speedTimer = model.fanSpeedTimer {
                FanSpeedTimerRowView(speedTimer: speedTimer)
                    .transition(.opacity)
            } else if isExpanded, canCreateTimer,
                      let rpmRange = model.fanSpeedTimerRPMRange {
                VStack(alignment: .leading, spacing: 14) {
                    FanSpeedTimerEditorView(
                        draft: $draft,
                        minimumRPM: rpmRange.lowerBound,
                        maximumRPM: rpmRange.upperBound
                    )

                    AsyncButton {
                        await model.startFanSpeedTimer(draft)
                    } label: {
                        Text("Start timer")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.capsule)
                    .controlSize(.large)
                    .disabled(
                        !draft.isValid(minimumRPM: rpmRange.lowerBound, maximumRPM: rpmRange.upperBound) ||
                        model.isStartingFanSpeedTimer ||
                        model.isSendingControlAttempts
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .fanCardSurface()
        .clipped()
        .animation(.easeInOut(duration: 0.2), value: isExpanded)
        .animation(.easeInOut(duration: 0.2), value: model.fanSpeedTimer)
        .onChange(of: model.fanSpeedTimer == nil) {
            isExpanded = false
        }
        .onChange(of: model.fanSpeedTimerRPMRange, initial: true) {
            normalizeRPM()
        }
    }

    private func normalizeRPM() {
        guard let rpmRange = model.fanSpeedTimerRPMRange else { return }
        draft.rpm = min(max(draft.rpm, rpmRange.lowerBound), rpmRange.upperBound)
    }
}
