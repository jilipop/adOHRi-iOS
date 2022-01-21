import Foundation
import AVFAudio

class HeadphonesDetector {
    let session: AVAudioSession
    
    var headphonesConnected: Bool = false
    weak var delegate: HeadphonesDetectorDelegate?
    
    init(session: AVAudioSession = .sharedInstance()) {
        self.session = session
    }
    
    func setupNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil)
    }
    
    func checkCurrentState() {
        headphonesConnected = false
        let currentRoute = self.session.currentRoute
        if currentRoute.outputs.count != 0 {
            for description in currentRoute.outputs {
                switch description.portType {
                
                case .headphones:
                    print("wired headphones plugged in")
                    headphonesConnected = true
                    
                case .bluetoothLE:
                    print("bluetoothLE connected")
                    headphonesConnected = true
                    
                case .bluetoothHFP:
                    print("bluetoothHFP connected")
                    headphonesConnected = true
                    
                case .bluetoothA2DP:
                    print("bluetoothA2DP connected")
                    headphonesConnected = true
                    
                default: ()
                }
            }
            if headphonesConnected == false {
                print("no headphones connected")
            }
        } else {
            print("requires connection to device")
        }
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
        }

        switch reason {

        case .newDeviceAvailable:
            headphonesConnected = hasHeadphones(in: session.currentRoute)
            print("headphones were connected")
        
        case .oldDeviceUnavailable:
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                headphonesConnected = hasHeadphones(in: previousRoute)
                print("headphones were disconnected")
                DispatchQueue.main.async {
                    self.headphonesDidDisconnect()
                }
            }
        
        default: ()
        }
    }

    private func hasHeadphones(in routeDescription: AVAudioSessionRouteDescription) -> Bool {
        return !routeDescription.outputs.filter(
            {$0.portType == .headphones
                || $0.portType == .bluetoothLE
                || $0.portType == .bluetoothHFP
                || $0.portType == .bluetoothA2DP
            }).isEmpty
    }
    
    func headphonesDidDisconnect() {
        delegate?.headphonesDidDisconnect(self)
    }
}
