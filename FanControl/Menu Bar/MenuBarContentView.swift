import ScrechKit

struct MenuBarContentView: View {
    @Bindable var model: FanVM
    let showsUpdateAlert: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            MenuBarContentViewHeader(model: model)
            
            ScrollView {
                FanControlsView(model: model, showSensors: true)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding()
        .frame(width: 340)
        .frame(minHeight: 515, maxHeight: .infinity, alignment: .top)
        .background(FanSelectionShortcutsView(changeSelectedFan: model.changeSelectedFan))
        .background(ContentViewBackground())
        .alert(item: $model.errorAlert) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                primaryButton: .default(Text("Copy error message"), action: model.copyErrorMessage),
                secondaryButton: .cancel(Text("OK"), action: model.dismissError)
            )
        }
        .alert(item: $model.menuBarUpdateStatusAlert) { updateStatusAlert in
            Alert(
                title: Text(updateStatusAlert.title),
                message: Text(updateStatusAlert.message),
                dismissButton: .cancel(Text("OK")) {
                    model.dismissUpdateStatusAlert(for: .menuBar)
                }
            )
        }
        .sheet(showsUpdateAlert && !model.isSettingsOpen ? $model.isUpdatePromptPresented : .constant(false)) {
            UpdateSheet(model: model)
        }
    }
}
