import Foundation
import AVFAudio

class AudioSessionHealthObserver: InterruptionNotifier {
    
    let session: AVAudioSession
    
    weak var delegate: InterruptionDelegate?
    
    init(session: AVAudioSession = .sharedInstance()) {
        self.session = session
        
        setupNotifications()
    }

    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleInterruption),
            name: AVAudioSession.interruptionNotification,
            object: nil)
    }
    
    func areHeadphonesConnected() -> Bool {
        var headphonesConnected = false
        let currentRoute = self.session.currentRoute
        if currentRoute.outputs.count == 0 {
            print("Checking for headphones won't work in iOS simulator.")
        } else {
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
        }
        return headphonesConnected
    }
    
    @objc private func handleRouteChange(notification: Notification) {
        guard let userInfo = notification.userInfo,
            let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
            let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
                return
        }

        switch reason {

        case .newDeviceAvailable:
            if hasWiredHeadphones(in: session.currentRoute) {
                print("headphones were connected")
            } else if hasBluetoothOutput(in: session.currentRoute) {
                print("bluetooth output device was connected")
            }
        
        case .oldDeviceUnavailable:
            if let previousRoute =
                userInfo[AVAudioSessionRouteChangePreviousRouteKey] as? AVAudioSessionRouteDescription {
                if hasWiredHeadphones(in: previousRoute) {
                    print("headphones were unplugged")
                    DispatchQueue.main.async {
                        self.interruptionDidOccur(cause: .wiredHeadphonesDisconnected)
                    }
                } else if hasBluetoothOutput(in: previousRoute) {
                    print("bluetooth output device was disconnected")
                    DispatchQueue.main.async {
                        self.interruptionDidOccur(cause: .bluetoothOutputDisconnected)
                    }
                }
            }
            
        default: ()
        }
    }

    @objc private func handleInterruption(notification: Notification) {
        guard let userInfo = notification.userInfo,
                let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
                let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
                    return
            }

        if case .began = type {
            DispatchQueue.main.async {
                self.interruptionDidOccur(cause: .audioSessionStopped)
            }
        }
    }
    
    private func hasWiredHeadphones(in routeDescription: AVAudioSessionRouteDescription) -> Bool {
        return !routeDescription.outputs.filter(
            {$0.portType == .headphones}).isEmpty
    }
    
    private func hasBluetoothOutput(in routeDescription: AVAudioSessionRouteDescription) -> Bool {
        return !routeDescription.outputs.filter(
            {$0.portType == .bluetoothLE
                || $0.portType == .bluetoothHFP
                || $0.portType == .bluetoothA2DP
            }).isEmpty
    }
    
    func interruptionDidOccur(cause: InterruptionCause) {
        delegate?.reactToInterruption(self, cause: cause)
    }
}
