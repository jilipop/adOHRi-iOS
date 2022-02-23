import UIKit

class MainViewController: UIViewController, InterruptionDelegate {
    
    var player = Player()
    var wiFi = WiFiManager()
    var sessionHealth: AudioSessionHealthObserver?
    
    var toastStyle = ToastStyle()
    
    let startTitle = NSLocalizedString("MainViewController.StartStopButton.Start", comment: "Text der Starten-Taste")
    let stopTitle = NSLocalizedString("MainViewController.StartStopButton.Stop", comment: "Text der Stoppen-Taste")
    let useHeadphones = NSLocalizedString("MainViewController.UseHeadphonesToast", comment: "Aufforderung zur Verwendung von Kopfhörern")
    let wiredHeadphonesDisconnected = NSLocalizedString("MainViewController.WiredHeadphonesDisconnectedToast", comment: "Info beim Entfernen kabelgebundener Kopfhörer")
    let bluetoothHeadphonesDisconnected = NSLocalizedString("MainViewController.BluetoothHeadphonesDisconnectedToast", comment: "Info bei verlorer Verbindung zu Bluetooth-Kopfhörern")
    let wiFiDisconnected = NSLocalizedString("MainViewController.WiFiDisconnectedToast", comment: "Info bei Verlust der WLAN-Verbindung")
    
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
        startStopButton.setTitle(startTitle, for: .normal)
        toastStyle.backgroundColor = .systemBlue
        toastStyle.activityBackgroundColor = .clear
        toastStyle.activityIndicatorColor = .black

        if #available(iOS 13.0, *) {
            toastStyle.activityIndicatorColor = UIColor.init { (traitCollection) -> UIColor in
                return traitCollection.userInterfaceStyle == .dark ? .white : .black
            }
            toastStyle.messageColor = UIColor.init { (traitCollection) -> UIColor in
                return traitCollection.userInterfaceStyle == .dark ? .black : .white
            }
        }
        ToastManager.shared.style = toastStyle
        
        sessionHealth = AudioSessionHealthObserver()
        sessionHealth?.delegate = self
        wiFi.delegate = self
        
        setupNotification()
    }
    
    @IBAction func playStopAction(_ sender: UIButton) {
        if player.isPlaying() {
            togglePlayer(sender, action: playerAction.stop)
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        } else {
            if !(sessionHealth?.areHeadphonesConnected() ?? true) {
                view.makeToast(useHeadphones, duration: 5.0, position: .top)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .announcement, argument: self.useHeadphones)
                }
            }
            /*else*/ if wiFi.isConnected() {
                togglePlayer(sender, action: playerAction.start)
            } else {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                if wiFi.isConnected() {
                    togglePlayer(sender, action: playerAction.start)
                } else {
                    tryToConnectAndPlay(sender)
                }
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
        var buttonTitle: String
        if case .start = action {
            player.start()
            buttonTitle = stopTitle
        } else {
            player.stop()
            buttonTitle = startTitle
        }
        sender.setTitle(buttonTitle, for: .normal)
        sender.accessibilityLabel = buttonTitle
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
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                }
            } else {
                self.view.hideToastActivity()
                sender.isHidden = false
                self.navigationController?.setNavigationBarHidden(false, animated: true)
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
                view.makeToast(wiredHeadphonesDisconnected, duration: 5.0, position: .top)
                
            case .bluetoothOutputDisconnected:
                print("The Bluetooth output device was disconnected.")
                view.makeToast(bluetoothHeadphonesDisconnected, duration: 5.0, position: .top)
                
            case .wiFiDisconnected:
                print("The WiFi connection was lost.")
                view.makeToast(wiFiDisconnected, duration: 5.0, position: .top)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .announcement, argument: self.wiFiDisconnected)
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
