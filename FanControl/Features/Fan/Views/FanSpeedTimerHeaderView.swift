import ScrechKit

struct FanSpeedTimerHeaderView: View {
    let isExpandable: Bool
    @Binding var isExpanded: Bool

    var body: some View {
        HStack(spacing: 8) {
            Text("Timer")
                .headline()

            Spacer(minLength: 0)

            if isExpandable {
                Button(isExpanded ? "Hide" : "New timer", systemImage: isExpanded ? "chevron.up" : "plus") {
                    isExpanded.toggle()
                }
                .buttonStyle(FanSelectionChipStyle(isSelected: isExpanded))
                .labelStyle(.titleAndIcon)
                .contentTransition(.symbolEffect(.replace))
            }
        }
        .frame(minHeight: 24)
    }
}
