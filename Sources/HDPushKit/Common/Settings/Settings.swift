import Foundation

public struct Settings: Codable, Equatable {
    public struct PushManagerSettings: Codable, Equatable {
        public var ssid = ""
        public var mobileCountryCode = ""
        public var mobileNetworkCode = ""
        public var trackingAreaCode = ""
        public var host = ""
        public var matchEthernet = false
    }
    
    public var uuid: UUID
    public var deviceName: String
    public var pushManagerSettings = PushManagerSettings()
}

public extension Settings {
    var user: User {
        User(uuid: uuid, deviceName: deviceName)
    }
}

public extension Settings.PushManagerSettings {
    // Convenience function that determines if the pushManagerSettings model has any valid configuration properties set. A valid configuration
    // includes both a host value and an SSID or private LTE network configuration.
    var isEmpty: Bool {
        if (!ssid.isEmpty || (!mobileCountryCode.isEmpty && !mobileNetworkCode.isEmpty) || matchEthernet) && !host.isEmpty {
            return false
        } else {
            return true
        }
    }
}

