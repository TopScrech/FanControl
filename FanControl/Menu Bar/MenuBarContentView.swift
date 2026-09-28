import ScrechKit

struct MenuBarContentView: View {
    @Environment(\.colorScheme) private var colorScheme

    @Bindable var model: FanVM
    let showsUpdateAlert: Bool
    
    var body: some View {
        VStack(spacing: 8) {
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
        .background {
            Color(white: colorScheme == .dark ? 0.16 : 0.96)
                .ignoresSafeArea()
        }
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
