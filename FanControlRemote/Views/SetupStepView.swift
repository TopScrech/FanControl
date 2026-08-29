import SwiftUI

struct SetupStepView<Actions: View>: View {
    var number: Int
    var title: String
    var detail: String
    @ViewBuilder var actions: Actions

    var body: some View {
        HStack(alignment: .top) {
            Text(number, format: .number)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(width: 32, height: 32)
                .background(.tint, in: .circle)
                .accessibilityLabel("Step \(number)")

            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)

                Text(detail)
                    .foregroundStyle(.secondary)

                actions
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.quaternary, in: .rect(cornerRadius: 18))
    }
}
