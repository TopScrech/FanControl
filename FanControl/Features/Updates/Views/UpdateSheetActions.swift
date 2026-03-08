import SwiftUI

struct UpdateSheetActions: View {
    @Bindable var model: FanVM
    
    var body: some View {
        HStack {
            Spacer()
            
            Button("Not now", action: cancelUpdate)
                .keyboardShortcut(.cancelAction)
            
            Button("Update", action: installPreparedUpdate)
                .keyboardShortcut(.defaultAction)
                .disabled(model.isCheckingForUpdates)
        }
    }
    
    private func installPreparedUpdate() {
        Task {
            await model.installPreparedUpdate()
        }
    }
    
    private func cancelUpdate() {
        Task {
            await model.dismissUpdatePrompt()
        }
    }
}

#Preview {
    UpdateSheetActions(model: FanVM())
}
