import ScrechKit

struct FanPromotionsView: View {
    @AppStorage("hasDismissedDiscordPromotion") private var hasDismissedDiscordPromotion = false
    @AppStorage("hasDismissedIPhonePromotion") private var hasDismissedIPhonePromotion = false
    
    private let discordURL = URL(string: "https://discord.gg/MAgTjeFTB7")
    private let appStoreURL = URL(string: "https://apps.apple.com/app/id6806835921")
    
    var body: some View {
        Group {
            if !hasDismissedDiscordPromotion {
                FanPromotionCard(
                    title: "Join our Discord community!",
                    linkTitle: "Join",
                    destination: discordURL
                ) {
                    hasDismissedDiscordPromotion = true
                }
            }
            
            if !hasDismissedIPhonePromotion {
                FanPromotionCard(
                    title: "Manage fan speed from your iPhone!",
                    linkTitle: "App Store",
                    destination: appStoreURL,
                    showsShareButton: true
                ) {
                    hasDismissedIPhonePromotion = true
                }
            }
        }
    }
}
