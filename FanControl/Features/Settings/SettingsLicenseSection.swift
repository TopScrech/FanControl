import ScrechKit

struct SettingsLicenseSection: View {
    @Environment(\.openURL) private var openURL
    
    private enum Field: Hashable {
        case email, licenseKey
    }
    
    @Bindable var model: FanVM
    
    @State private var isResetConfirmationPresented = false
    @FocusState private var focusedField: Field?
    
    private let restoreURL = URL(string: "https://fancontrol.dev/restore-license")!
    
    var body: some View {
        Section {
            TextField("Email", text: $model.licenseEmail)
                .focused($focusedField, equals: .email)
            
            SecureField("License key", text: $model.licenseKey)
                .focused($focusedField, equals: .licenseKey)
                .onSubmit(verifyLicense)
            
            LabeledContent("Status", value: model.licenseStatusText)
        } header: {
            HStack {
                Text("License")
                
                Spacer()
                
                if model.isLicenseActive {
                    Button("Reset") {
                        isResetConfirmationPresented = true
                    }
                    .secondary()
                    .disabled(model.licenseEmail.isEmpty && model.licenseKey.isEmpty)
                } else {
                    Button("Restore") {
                        openURL(restoreURL)
                    }
                    .secondary()
                }
            }
        }
        .confirmationDialog(
            "Reset saved license",
            isPresented: $isResetConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive, action: resetLicense)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the saved email and license key from this Mac and unregisters this device")
        }
        .task {
            focusedField = nil
        }
    }
    
    private func verifyLicense() {
        Task {
            await model.verifyLicenseNow()
        }
    }
    
    private func resetLicense() {
        Task {
            await model.clearSavedLicense()
        }
    }
}
