import Foundation
import AVFAudio

class Player {
    private let audioSession: AVAudioSession
    private let engine: AVAudioEngine
    private let playerNode: AVAudioPlayerNode
    private let outputFormat: AVAudioFormat
    private let frameSize = Int(FRAME_SIZE)
    private let numChannels = UInt32(CHANNELS)
    private let sampleRate = Double(RATE)
    
    private var isPlayRequested = false
        
    init(audioSession: AVAudioSession = .sharedInstance(), engine: AVAudioEngine = .init(), playerNode: AVAudioPlayerNode = .init()) {
        self.audioSession = audioSession
        self.engine = engine
        self.playerNode = playerNode
        do {
            try audioSession.setCategory(.playback, mode: .spokenAudio, policy: .longForm)
            print("audio session category set successfully")
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
        outputFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: numChannels)!
        
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.outputNode, format: outputFormat)
        engine.prepare()
    }
    
    deinit {
        if isPlayRequested {
            iRx_stop()
        }
        ortp_exit()
    }
    
    func isPlaying() -> Bool {
        return isPlayRequested
    }
    
    func isEngineRunning() -> Bool {
        return engine.isRunning
    }
    
    func start() {
        isPlayRequested = true
        iRx_start()
        do {
            try audioSession.setActive(true)
        } catch {
            print("Failed to start audio session. Error: \(error)")
            isPlayRequested = false
            return
        }
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine. Error: \(error)")
            isPlayRequested = false
            return
        }
        DispatchQueue.global(qos: .userInteractive).async {
            self.runRx()
            iRx_stop() //TODO: find a better place for this? Use DispatchGroup to wait in stop() after all?
        }
        playerNode.play()
    }
    
    private func runRx() {
        let sampleCount = AVAudioFrameCount(frameSize * 2)
        
        while isPlayRequested {
            let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: sampleCount)!
            let result = rx(&outputBuffer.mutableAudioBufferList.pointee)
            outputBuffer.frameLength = AVAudioFrameCount(frameSize)
            if result < 0 {
                print("stopping due to decoding error")
                stop() //TODO: probably should do this through an interruption delegate
            } else {
                playerNode.scheduleBuffer(outputBuffer) {}
            }
        }
    }
    
    func stop() {
        isPlayRequested = false
        playerNode.stop()
        engine.stop()
        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to stop audio session. Error: \(error)")
        }
    }
}
