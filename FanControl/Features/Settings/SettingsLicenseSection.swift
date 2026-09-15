import ScrechKit

struct SettingsLicenseSection: View {
    private static let licenseKeyLength = 33

    @Environment(\.openURL) private var openURL
    
    private enum Field: Hashable {
        case initial, email, licenseKey
    }
    
    @Bindable var model: FanVM
    
    @State private var isResetConfirmationPresented = false
    @State private var isVerificationAlertPresented = false
    @State private var verificationAlert: LicenseVerificationAlert?
    @FocusState private var focusedField: Field?
    
    private let buyURL = URL(string: "https://fancontrol.dev")!
    private let restoreURL = URL(string: "https://fancontrol.dev/restore-license")!
    
    var body: some View {
        Section {
            TextField("Email", text: $model.licenseEmail)
                .focused($focusedField, equals: .email)
            
            SecureField("License key", text: $model.licenseKey)
                .focused($focusedField, equals: .licenseKey)
                .onChange(of: model.licenseKey) { _, licenseKey in
                    guard licenseKey.count == Self.licenseKeyLength else { return }
                    verifyLicense()
                }
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
                    Button("Buy") {
                        openURL(buyURL)
                    }
                    .secondary()
                    
                    Text("•")
                        .secondary()
                    
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
        .alert(
            verificationAlert?.title ?? "",
            isPresented: $isVerificationAlertPresented,
            presenting: verificationAlert
        ) { _ in
            Button("OK", role: .cancel) {
                verificationAlert = nil
            }
        } message: {
            Text($0.message)
        }
        .background {
            Color.clear
                .focusable()
                .focused($focusedField, equals: .initial)
                .focusEffectDisabled()
                .accessibilityHidden(true)
        }
        .defaultFocus($focusedField, .initial)
    }
    
    private func verifyLicense() {
        Task {
            guard let alert = await model.verifyLicenseNow() else { return }
            verificationAlert = alert
            isVerificationAlertPresented = true
        }
    }
    
    private func resetLicense() {
        Task {
            await model.clearSavedLicense()
        }
    }
}
