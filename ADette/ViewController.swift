import UIKit
import AVFAudio

class ViewController: UIViewController {
    
    let player = Player()
    let wifi = WiFiManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func playStopAction(_ sender: UIButton) {
        if !player.isPlaying() {
            if wifi.isConnected() {
                player.start()
                sender.setTitle("Stoppen", for: UIControl.State.normal)
                sender.accessibilityLabel = "Stoppen"
                    UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged,
                                         argument: sender)
            } else {
                DispatchQueue.main.async() { //these changes will appear in background during first prompt
                    sender.isEnabled = false
                    sender.isSelected = false
                    sender.setTitle("Verbinde...", for: UIControl.State.normal)
                }
                wifi.promptUserToConnect(callback: { (accepted) -> Void in
                    sender.setTitle("Starten", for: UIControl.State.normal) //this will appear after the system dialogs
                    if accepted {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            if self.wifi.isConnected() {
                                self.player.start()
                                sender.setTitle("Stoppen", for: UIControl.State.normal)
                                sender.accessibilityLabel = "Stoppen"
                                    UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged,
                                                         argument: sender)
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
        } else {
            player.stop()
            sender.setTitle("Starten", for: UIControl.State.normal)
            sender.accessibilityLabel = "Starten"
                UIAccessibility.post(notification: UIAccessibility.Notification.layoutChanged,
                                     argument: sender)
      }
    }
}
