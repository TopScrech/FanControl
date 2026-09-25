import ScrechKit

struct ContentViewToolbar: ToolbarContent {
    @Bindable var model: FanVM
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Text("FanControl")
                .headline()
        }
        .hidesSharedToolbarBackground()
        
        if #available(macOS 26, *) {
            ToolbarSpacer(.flexible)
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            if !model.isLicenseActive {
                LicenseInactiveBadge()
            }
            
            if model.fans.count > 1 {
                FanSelectionChips(model: model)
                    // Toolbar inset is narrower than the 8pt card inset below
                    .padding(.trailing, 4)
            }
        }
        .hidesSharedToolbarBackground()
    }
}
