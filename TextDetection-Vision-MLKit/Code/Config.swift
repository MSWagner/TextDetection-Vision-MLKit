import Foundation

/// Global set of configuration values for this application.
struct Config {
    static let keyPrefix = "mws.textdetection.vision.mlkit"

    // MARK: User Defaults

    struct UserDefaultsKey {
        static let lastUpdate = Config.keyPrefix + ".lastUpdate"
    }
}
