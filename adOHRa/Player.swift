import Foundation
import AVFAudio

class Player {
    private let audioSession: AVAudioSession
    private let engine: AVAudioEngine
    private let playerNode: AVAudioPlayerNode
    private let outputFormat: AVAudioFormat
    private let frameSize = Int(FRAME_SIZE)
    private let numChannels = UInt32(CHANNELS)
    private let floatSize = UInt32(MemoryLayout<Float32>.stride)
    private let sampleRate = Double(RATE)
    private let referenceRate = UInt32(PAYLOAD_0_REFERENCE_RATE)
    private let port = Int32(PORT)
    private let jitter = UInt32(JITTER)
    private let addr = ADDR
    private let rxGroup = DispatchGroup()
    
    private var session: UnsafeMutablePointer<RtpSession>?
    private var decoder: OpaquePointer?
    
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
            stop()
        }
        iRxDeinit()
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
        iRxInit()
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
            self.rxGroup.enter()
            self.runRx()
            self.rxGroup.leave()
        }
        playerNode.play()
    }
    
    private func iRxInit() {
        var error: CInt = 0
        
        decoder = opus_decoder_create(opus_int32(sampleRate), Int32(numChannels), &error);
        if decoder == nil {
            print("couldn't create decoder: \(String(cString: opus_strerror(error)))")
            return;
        }
        ortp_init()
        ortp_scheduler_init()
        session = create_rtp_recv(addr, port, jitter)
    }
    
    private func runRx() {
        var timestamp: UInt32 = 0
        let bufsize = 32768
        var numBytesReceived: CInt
        var have_more: CInt = 0
        var packet: UnsafeMutablePointer<CChar>?
        
        while isPlayRequested {
            let buf = UnsafeMutablePointer<CChar>.allocate(capacity: bufsize)

            numBytesReceived = rtp_session_recv_with_ts(session, buf,
                                                        CInt(bufsize), timestamp, &have_more)
            if numBytesReceived == 0 {
                packet = nil
                NSLog("#")
            } else {
                packet = buf
            }
            let numDecodedSamples: Int32 = playOneFrame(packet: packet, length: numBytesReceived)
            if numDecodedSamples == -1 {
                break
                //TODO: send interruption in this case?
            }
            timestamp += UInt32(numDecodedSamples) * referenceRate / UInt32(sampleRate)
            buf.deallocate()
        }
    }
    
    private func playOneFrame(packet: UnsafeMutablePointer<CChar>?, length: CInt) -> Int32 {
        var numDecodedSamples: CInt
        let samples: CInt = 1920
        let pcm = UnsafeMutablePointer<Float>.allocate(capacity: Int(floatSize) * Int(samples) * Int(numChannels))
        
        if packet == nil {
            numDecodedSamples = opus_decode_float(decoder!, nil, 0, pcm, samples, 1)
        } else {
            numDecodedSamples = opus_decode_float(decoder!, packet, length, pcm, samples, 0)
        }
        if (numDecodedSamples < 0) {
            print("decoder error: \(String(cString: opus_strerror(numDecodedSamples)))")
            return -1
        }
        
        playerNode.scheduleBuffer(deinterleave(pcm)) {}
        
        pcm.deallocate()
        return numDecodedSamples
    }
    
    private func deinterleave(_ data: UnsafeMutablePointer<Float>) -> AVAudioPCMBuffer {
        let sampleCount = AVAudioFrameCount(frameSize * 2)
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: sampleCount)!
        for channel in 0..<Int(numChannels) {
            for sampleIndex in 0..<sampleCount {
                outputBuffer.floatChannelData![channel][Int(sampleIndex)] = data[Int(sampleIndex) * Int(numChannels) + channel]
            }
        }
        outputBuffer.frameLength = AVAudioFrameCount(sampleCount / numChannels)
        return outputBuffer
    }
    
    func stop() {
        isPlayRequested = false
        log_stats()
        playerNode.stop()
        engine.stop()
        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to stop audio session. Error: \(error)")
        }
        rxGroup.notify(queue: DispatchQueue.main) {
            NSLog("rxGroup finished")
            self.iRxDeinit()
        }
    }
    
    private func iRxDeinit() {
        rtp_session_destroy(session)
        session = nil
        //ortp_exit(); //can't start again after calling this. Bug in ortp? Caused by ortp_scheduler_init() failing on subsequent runs? Moving this to deinit above
        opus_decoder_destroy(decoder)
        decoder = nil
    }
}
