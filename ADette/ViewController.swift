//
//  ViewController.swift
//  ADette
//
//  Created by Test on 14.12.21.
//

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
            if !wifi.isADConnected() {
                wifi.connect()
            }
            player.start()
            sender.setTitle("Audiodeskription stoppen", for: UIControl.State.normal)
        } else {
            player.stop()
            wifi.remove()
            sender.setTitle("Audiodeskription starten", for: UIControl.State.normal)
      }
    }
}

