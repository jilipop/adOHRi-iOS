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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func playStopAction(_ sender: UIButton) {
        sender.isSelected.toggle()
        if sender.isSelected {
            player.start()
            sender.setTitle("Audiodeskription stoppen", for: UIControl.State.normal)
        } else {
            player.stop()
            sender.setTitle("Audiodeskription starten", for: UIControl.State.normal)
      }
    }
}

