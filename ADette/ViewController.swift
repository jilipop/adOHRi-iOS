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
        sender.isSelected.toggle()
        if sender.isSelected {
            if !wifi.isConnected() {
                wifi.connect()
            }
            player.start()
            sender.setTitle("Stoppen", for: UIControl.State.normal)
            sender.isSelected = false
        } else {
            player.stop()
            sender.setTitle("Starten", for: UIControl.State.normal)
      }
    }
}
