import ScrechKit

struct ContentView: View {
    @AppStorage("keepsWindowOnTop") private var keepsWindowOnTop = false
    
    @Bindable var model: FanVM
    let showsUpdateAlert: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ContentViewHeader(model: model)
            
            ScrollView {
                if model.componentVersion == nil {
                    ComponentSettingsSection()
                        .environment(model)
                } else {
                    FanControlsView(model: model)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding()
        .frame(width: 400)
        .frame(maxHeight: .infinity)
        .background(MainWindowLevelView(keepsWindowOnTop: keepsWindowOnTop))
        .background(FanSelectionShortcutsView(changeSelectedFan: model.changeSelectedFan))
        .background(ContentViewBackground())
        .alert("Error", isPresented: $model.isErrorAlertPresented, presenting: model.errorAlert) { _ in
            Button("Copy error message", action: model.copyErrorMessage)
            Button("OK", role: .cancel, action: model.dismissError)
        } message: {
            Text($0.message)
        }
        .alert(
            model.mainWindowUpdateStatusAlert?.title ?? "",
            isPresented: $model.isMainWindowUpdateStatusAlertPresented,
            presenting: model.mainWindowUpdateStatusAlert
        ) { _ in
            Button("OK", role: .cancel) {
                model.dismissUpdateStatusAlert(for: .mainWindow)
            }
        } message: {
            Text($0.message)
        }
        .sheet(showsUpdateAlert && !model.isSettingsOpen ? $model.isUpdatePromptPresented : .constant(false)) {
            UpdateSheet(model: model)
        }
    }
}
