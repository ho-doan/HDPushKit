import Foundation
#if os(iOS)
import UIKit
#endif
import Combine
import os

@available(iOS 15.0, *)
public class SettingsManager: NSObject {
    enum Error: Swift.Error {
        case uuidMismatch
    }
    
    public static let shared = SettingsManager()
    
    public var settings: Settings {
        settingsSubject.value
    }
    
    public private(set) lazy var settingsPublisher = settingsSubject.eraseToAnyPublisher()
    private let settingsWillWriteSubject = PassthroughSubject<Void, Never>()
    private static let settingsKey = "settings"
    private let pushGroupIdentifier = (Bundle.main.object(forInfoDictionaryKey: "GroupNEAppPushLocal") as? String)!
    private static let userDefaults = UserDefaults(suiteName: pushGroupIdentifier)!
    private let settingsSubject: CurrentValueSubject<Settings, Never>
    private static let logger = Logger(prependString: "SettingsManager", subsystem: .general)
    
    override init() {
        var settings = Self.fetch()
        
        if settings == nil {
#if os(iOS)
let deviceName = UIDevice.current.name
#else
let deviceName = "Unknown"
#endif
            
            settings = Settings(uuid: UUID(), deviceName: deviceName)
            
            do {
                try Self.set(settings: settings!)
            } catch {
                SettingsManager.logger.log("Error encoding settings - \(error)")
            }
        }
        
        settingsSubject = CurrentValueSubject(settings!)
        
        super.init()
        
        Self.userDefaults.addObserver(self, forKeyPath: Self.settingsKey, options: [.new], context: nil)
    }
    
    // MARK: - Publishers
    
    // A publisher that emits new settings following a call to `set(settings:)`.
    public private(set) lazy var settingsDidWritePublisher = {
        settingsWillWriteSubject
        .compactMap { [weak self] _ in
            self?.settingsPublisher
                .dropFirst()
                .first()
        }
        .switchToLatest()
        .eraseToAnyPublisher()
    }()
    
    // MARK: - Actions
    
    func refresh() throws {
        guard let settings = Self.fetch() else {
            return
        }
        
        settingsSubject.send(settings)
    }
    
    public func set(settings: Settings) throws {
        guard settings.uuid == self.settings.uuid else {
            throw Error.uuidMismatch
        }
        
        settingsWillWriteSubject.send()
        try Self.set(settings: settings)
        settingsSubject.send(settings)
    }
    
    private static func set(settings: Settings) throws {
        let encoder = JSONEncoder()
        let encodedSettings = try encoder.encode(settings)
        userDefaults.set(encodedSettings, forKey: Self.settingsKey)
    }
    
    private static func fetch() -> Settings? {
        guard let encodedSettings = userDefaults.data(forKey: settingsKey) else {
            return nil
        }
        
        do {
            let decoder = JSONDecoder()
            let settings = try decoder.decode(Settings.self, from: encodedSettings)
            return settings
        } catch {
            logger.log("Error decoding settings - \(error)")
            return nil
        }
    }
    
    // MARK: - KVO
    
    public override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        do {
            try refresh()
        } catch {
            SettingsManager.logger.log("Error refreshing settings - \(error)")
        }
    }
}
