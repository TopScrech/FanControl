import ScrechKit

struct MenuBarContentView: View {
    @Bindable var model: FanVM
    let showsUpdateAlert: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            MenuBarContentViewHeader(model: model)
            
            ScrollView {
                if model.componentVersion == nil || model.componentInstaller.isInstalling {
                    ComponentSettingsSection()
                        .environment(model)
                        .environment(model.componentInstaller)
                } else {
                    FanControlsView(model: model, showSensors: true)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .padding()
        .frame(width: 340)
        .frame(minHeight: 515, maxHeight: .infinity, alignment: .top)
        .background(FanSelectionShortcutsView(changeSelectedFan: model.changeSelectedFan))
        .background(ContentViewBackground())
        .alert("Error", isPresented: $model.isErrorAlertPresented, presenting: model.errorAlert) { _ in
            Button("Copy error message", action: model.copyErrorMessage)
            Button("OK", role: .cancel, action: model.dismissError)
        } message: {
            Text($0.message)
        }
        .alert(
            model.menuBarUpdateStatusAlert?.title ?? "",
            isPresented: $model.isMenuBarUpdateStatusAlertPresented,
            presenting: model.menuBarUpdateStatusAlert
        ) { _ in
            Button("OK", role: .cancel) {
                model.dismissUpdateStatusAlert(for: .menuBar)
            }
        } message: {
            Text($0.message)
        }
        .sheet(showsUpdateAlert && !model.isSettingsOpen ? $model.isUpdatePromptPresented : .constant(false)) {
            UpdateSheet(model: model)
        }
    }
}
