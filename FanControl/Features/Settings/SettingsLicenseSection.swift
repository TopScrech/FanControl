import ScrechKit

struct SettingsLicenseSection: View {
    @Bindable var model: FanVM
    @State private var isResetConfirmationPresented = false
    
    var body: some View {
        Section {
            TextField("Email", text: $model.licenseEmail)
            
            SecureField("License key", text: $model.licenseKey)
            
            LabeledContent("Status", value: model.licenseStatusText)
            
            Button(action: verifyLicense) {
                LabeledContent {
                    Image(systemName: "checkmark.seal")
                } label: {
                    Text("Verify license")
                }
            }
            .disabled(model.isCheckingLicense)
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
