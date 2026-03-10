import SwiftUI

struct UpdateSheetActions: View {
    let isUpdateDisabled: Bool
    let onCancel: () -> Void
    let onInstall: () -> Void
    
    var body: some View {
        HStack {
            Spacer()
            
            Button("Not now", action: onCancel)
                .keyboardShortcut(.cancelAction)
            
            Button("Update", action: onInstall)
                .keyboardShortcut(.defaultAction)
                .disabled(isUpdateDisabled)
        }
    }
}

#Preview {
    UpdateSheetActions(
        isUpdateDisabled: false,
        onCancel: {},
        onInstall: {}
    )
}
