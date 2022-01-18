import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

class WiFiManager {
    private let wiFiCredentials: NEHotspotConfiguration
    private let config: NEHotspotConfigurationManager
    
    init(hotspotConfigManager: NEHotspotConfigurationManager = .init(), hotspotConfig: NEHotspotConfiguration = .init(ssid: Secrets.ssid, passphrase: Secrets.passphrase, isWEP: false)) {
        config = hotspotConfigManager
        wiFiCredentials = hotspotConfig
        wiFiCredentials.lifeTimeInDays = 1
    }
    
    func isConnected() -> Bool {
        var ssid: String?
        if let interfaces = CNCopySupportedInterfaces() as NSArray? {
            for interface in interfaces {
                if let interfaceInfo = CNCopyCurrentNetworkInfo(interface as! CFString) as NSDictionary? {
                    ssid = interfaceInfo[kCNNetworkInfoKeySSID as String] as? String
                    break
                }
            }
        }
        return ssid == wiFiCredentials.ssid ? true : false
    }
    
    func promptUserToConnect(callback: @escaping (Bool) -> Void) {
        config.apply(wiFiCredentials) { error in
            if let error = error as NSError? {
                if error.code == NEHotspotConfigurationError.userDenied.rawValue {
                    print("User denied the connection.")
                }
                callback(false)
            }
            else {
                print("Trying to connect to AD wifi...")
                callback(true)
            }
        }
    }
    
    func remove() {
        config.removeConfiguration(forSSID: wiFiCredentials.ssid)
    }
}
