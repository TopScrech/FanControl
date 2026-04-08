import Foundation

enum AppBundleLocator {
    nonisolated static var current: Bundle {
        let mainBundle = Bundle.main
        let resolvedMainBundleURL = mainBundle.bundleURL.standardizedFileURL.resolvingSymlinksInPath()
        
        if resolvedMainBundleURL.pathExtension == "app", let bundle = Bundle(url: resolvedMainBundleURL) {
            return bundle
        }
        
        guard let executableURL = mainBundle.executableURL else {
            return mainBundle
        }
        
        var candidateURL = executableURL
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .deletingLastPathComponent()
        
        while candidateURL.path != "/" {
            if candidateURL.pathExtension == "app", let bundle = Bundle(url: candidateURL) {
                return bundle
            }
            
            candidateURL.deleteLastPathComponent()
        }
        
        return mainBundle
    }
}
