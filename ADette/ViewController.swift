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
        sessionHealth = AudioSessionHealthObserver()
        sessionHealth?.delegate = self
        wiFi.delegate = self
        
        setupNotification()
    }
    
    @IBAction func playStopAction(_ sender: UIButton) {
        if player.isPlaying() {
            togglePlayer(sender, action: playerAction.stop)
        } else {
            //TODO: Check if headphones are connected and react to result
            if wiFi.isConnected() {
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
    
    func reactToInterruption(_ sender: InterruptionNotifier, type: InterruptionCause) {
        if player.isPlaying() {
            switch type {
                
            case .audioSessionStopped:
                print("The audio session was interrupted.")
                
            case .wiredHeadphonesDisconnected:
                print("Wired headphones were plugged out.")
                
            case .bluetoothOutputDisconnected:
                print("The Bluetooth output device was disconnected.")
                
            case .wiFiDisconnected:
                print("The WiFi connection was lost.")
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
