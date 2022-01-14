import Foundation
import NetworkExtension
import SystemConfiguration.CaptiveNetwork

class WiFiManager {
    let wiFiCredentials = NEHotspotConfiguration(ssid: "Audio-Deskription", passphrase: "klappeauf!", isWEP: false)
    let config = NEHotspotConfigurationManager()
    
    init() {
        wiFiCredentials.lifeTimeInDays = 1
    }
    
    func isADConnected() -> Bool {
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
    
    func connect() {
        config.apply(wiFiCredentials) { error in
            if let error = error {
                print(error.localizedDescription)
            }
            else {
                print("connecting to AD wifi")
            }
        }
    }
    
    func remove() {
        config.removeConfiguration(forSSID: wiFiCredentials.ssid)
    }
}
