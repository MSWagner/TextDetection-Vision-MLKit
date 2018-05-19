import UIKit

/// Defines the global appearance for the application.
struct Appearance {
    /// Sets the global appearance for the application.
    /// Call this method early in the applicaiton's setup, i.e. in `applicationDidFinishLaunching:`
    static func setup() {
        UINavigationBar.appearance().barTintColor = UIColor(red:0.36, green:0.80, blue:0.74, alpha:1.0)
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().titleTextAttributes = [NSAttributedStringKey.foregroundColor: UIColor.white]
        UIApplication.shared.statusBarStyle = .lightContent
    }
}
