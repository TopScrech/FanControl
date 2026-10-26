import ScrechKit

struct SetupStepView<Actions: View>: View {
    var number: Int
    var title: String
    var detail: String
    @ViewBuilder var actions: Actions

    var body: some View {
        HStack(alignment: .top) {
            Text(number, format: .number)
                .headline()
                .foregroundStyle(.white)
                .frame(32)
                .background(.tint, in: .circle)
                .accessibilityLabel("Step \(number)")

            VStack(alignment: .leading) {
                Text(title)
                    .headline()

                Text(detail)
                    .secondary()

                actions
                    .padding(.top, 4)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.fill.quaternary, in: .rect(cornerRadius: 18))
    }
}
