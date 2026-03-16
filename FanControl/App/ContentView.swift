import ScrechKit

struct ContentView: View {
    @AppStorage("keepsWindowOnTop") private var keepsWindowOnTop = false
    
    @Bindable var model: FanVM
    let showsUpdateAlert: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ContentViewHeader(model: model)
            
            HStack(alignment: .top, spacing: 12) {
                FanControlsView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: 400, alignment: .topLeading)
                
                FanTemperatureCardView(model: model)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .frame(width: 280)
                    .fanCardSurface()
                    .frame(maxHeight: 400, alignment: .topLeading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
        .padding()
        .frame(width: 680)
        .background(MainWindowLevelView(keepsWindowOnTop: keepsWindowOnTop))
        .background(ContentViewBackground())
        .alert(item: $model.errorAlert) { error in
            Alert(
                title: Text("Error"),
                message: Text(error.message),
                primaryButton: .default(Text("Copy error message"), action: model.copyErrorMessage),
                secondaryButton: .cancel(Text("OK"), action: model.dismissError)
            )
        }
        .alert(item: $model.mainWindowUpdateStatusAlert) { updateStatusAlert in
            Alert(
                title: Text(updateStatusAlert.title),
                message: Text(updateStatusAlert.message),
                dismissButton: .cancel(Text("OK")) {
                    model.dismissUpdateStatusAlert(for: .mainWindow)
                }
            )
        }
        .sheet(showsUpdateAlert && !model.isSettingsOpen ? $model.isUpdatePromptPresented : .constant(false)) {
            UpdateSheet(model: model)
        }
    }
}
