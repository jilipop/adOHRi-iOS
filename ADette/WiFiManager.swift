import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

class WiFiManager {
    let wiFiCredentials = NEHotspotConfiguration(ssid: "Audio-Deskription", passphrase: Secrets.passphrase, isWEP: false)
    let config = NEHotspotConfigurationManager()
    
    init() {
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
