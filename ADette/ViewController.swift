import UIKit

class ViewController: UIViewController, HeadphonesDetectorDelegate {
    var player = Player()
    var wifi = WiFiManager()
    var headphonesDetector: HeadphonesDetector?
    
    @IBOutlet var startStopButton: UIButton!
    
    enum playerAction {
        case start, stop
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headphonesDetector = HeadphonesDetector()
        headphonesDetector?.delegate = self
        
        headphonesDetector?.setupNotification()
        headphonesDetector?.checkCurrentState()
    }
    
    @IBAction func playStopAction(_ sender: UIButton) {
        if player.isPlaying() {
            togglePlayer(sender, action: playerAction.stop)
        } else {
            //TODO: Check if headphones are connected and react to result
            if wifi.isConnected() {
                togglePlayer(sender, action: playerAction.start)
            } else {
                tryToConnectAndPlay(sender)
            }
        }
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
        DispatchQueue.main.async { //these changes will appear in background during first prompt
            sender.isEnabled = false
            sender.isSelected = false
            sender.setTitle("Verbinde...", for: .normal)
        }
        wifi.promptUserToConnect(callback: { (accepted) -> Void in
            sender.setTitle("Starten", for: .normal) //this will appear after the system dialogs
            if accepted {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    if self.wifi.isConnected() {
                        self.togglePlayer(sender, action: playerAction.start)
                    }
                    sender.isEnabled = true
                    sender.isSelected = true
                }
            } else {
                sender.isEnabled = true
                sender.isSelected = true
            }
        })
    }
    
    func headphonesDidDisconnect(_ sender: HeadphonesDetector) {
        if player.isPlaying() {
            togglePlayer(startStopButton, action: playerAction.stop)
            print("stopping player because headphones were disconnected")
        }
    }
}
