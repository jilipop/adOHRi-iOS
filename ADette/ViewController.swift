//
//  ViewController.swift
//  ADette
//
//  Created by Test on 14.12.21.
//

import UIKit
import AVFAudio

class ViewController: UIViewController {

    let audioSession = AVAudioSession.sharedInstance()
    let player = Player()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        do {
            if #available(iOS 11.0, *) {
                try audioSession.setCategory(.playback, mode: .spokenAudio, policy: .longForm)
                print("audio session category set successfully")
            } else {
                try audioSession.setCategory(.playback, mode: .spokenAudio)
                print("audio session category set successfully")
            }
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
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

