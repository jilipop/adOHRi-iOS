import UIKit

class ViewController: UIViewController, InterruptionDelegate {
    
    var player = Player()
    var wiFi = WiFiManager()
    var sessionHealth: AudioSessionHealthObserver?
    
    @IBOutlet var startStopButton: UIButton!
    
    enum playerAction {
        case start, stop
    }
    
    deinit {
        //TODO: Test this
        NotificationCenter.default.removeObserver(
            self,
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
        
        wiFi.remove()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        startStopButton.layer.cornerRadius = 10
        
        sessionHealth = AudioSessionHealthObserver()
        sessionHealth?.delegate = self
        wiFi.delegate = self
        
        setupNotification()
    }
    
    @IBAction func playStopAction(_ sender: UIButton) {
        if player.isPlaying() {
            togglePlayer(sender, action: playerAction.stop)
        } else {
            if !(sessionHealth?.areHeadphonesConnected() ?? true) {
                view.makeToast("Bitte Kopfhörer verbinden", duration: 3.0, position: .top)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .announcement, argument: "Bitte Kopfhörer verbinden")
                }
            }
            /*else*/ if wiFi.isConnected() {
                togglePlayer(sender, action: playerAction.start)
            } else {
                tryToConnectAndPlay(sender)
            }
        }
    }
    
    private func setupNotification() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleReturnToForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil)
    }
    
    private func togglePlayer(_ sender: UIButton, action: playerAction) {
        var caption: String
        if case .start = action {
            player.start()
            caption = "Stoppen"
        } else {
            player.stop()
            caption = "Starten"
        }
        sender.setTitle(caption, for: .normal)
        sender.accessibilityLabel = caption
        UIAccessibility.post(notification: .layoutChanged, argument: sender)
    }
    
    private func tryToConnectAndPlay(_ sender: UIButton) {
        startStopButton.isHidden = true
        self.view.makeToastActivity(.center)
        
        wiFi.promptUserToConnect(callback: { (accepted) -> Void in
            if accepted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if self.wiFi.isConnected() {
                        self.togglePlayer(sender, action: playerAction.start)
                    }
                    self.view.hideToastActivity()
                    sender.isHidden = false
                }
            } else {
                self.view.hideToastActivity()
                sender.isHidden = false
            }
        })
    }
    
    func reactToInterruption(_ sender: InterruptionNotifier, cause: InterruptionCause) {
        if player.isPlaying() {
            switch cause {
                
            case .audioSessionStopped:
                print("The audio session was interrupted.")
                
            case .wiredHeadphonesDisconnected:
                print("Wired headphones were plugged out.")
                view.makeToast("Die Kopfhörer wurden entfernt", duration: 3.0, position: .top)
                
            case .bluetoothOutputDisconnected:
                print("The Bluetooth output device was disconnected.")
                view.makeToast("Verbindung zu den Bluetooth-Kopfhörer verloren", duration: 3.0, position: .top)
                
            case .wiFiDisconnected:
                print("The WiFi connection was lost.")
                view.makeToast("WLAN-Verbindung getrennt", duration: 3.0, position: .top)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .announcement, argument: "WLAN-Verbindung getrennt")
                }
            }
            togglePlayer(startStopButton, action: playerAction.stop)
        }
    }
    
    @objc private func handleReturnToForeground() {
        if player.isPlaying() {
            if !wiFi.isConnected()
                || !(sessionHealth?.areHeadphonesConnected() ?? true)
                || !player.isEngineRunning() {
                togglePlayer(startStopButton, action: playerAction.stop)
                print("The play/stop button was reset because an interruption occurred while the app was in the background.")
            }
        }
    }
}
