import Foundation
import AVFAudio

class Player {
    private let audioSession: AVAudioSession
    private let engine: AVAudioEngine
    private let playerNode: AVAudioPlayerNode
    private let outputFormat: AVAudioFormat
    private let frameSize = UInt32(FRAME_SIZE)
    private let numChannels = UInt32(CHANNELS)
    private let floatSize = UInt32(MemoryLayout<Float32>.stride)
    private let sampleRate = Double(RATE)
    private let bufferLength = UInt32(BUFFER_LENGTH)
    private let numSchedulers: UInt32 = 2
    
    private var isPlayRequested = false
    private var circularBuffer = TPCircularBuffer()
    private var availableBytes: UInt32 = 0
        
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
    
    //TODO: Is this necessary? Seems to only be run when user kills app.
    deinit {
        if isPlayRequested {
            iRx_stop()
        }
        iRx_deinit()
    }
    
    func isPlaying() -> Bool {
        return isPlayRequested
    }
    
    func isEngineRunning() -> Bool {
        return engine.isRunning
    }
    
    func start() {
        isPlayRequested = true
        _TPCircularBufferInit(&circularBuffer, bufferLength, MemoryLayout<TPCircularBuffer>.stride)
        iRx_start(&circularBuffer)
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
        
        for _ in 1...numSchedulers {
            scheduleNextData()
        }
        playerNode.play()
    }
    
    private func getAndDeinterleaveNextData () -> AVAudioPCMBuffer {
        let inputBufferTail = TPCircularBufferTail(&circularBuffer, &availableBytes)
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: bufferLength)!
        if inputBufferTail != nil {
            let sampleCount = Int(availableBytes / numSchedulers / floatSize)
            let tailFloatPointer = inputBufferTail!.bindMemory(to: Float.self, capacity: sampleCount)
            for channel in 0..<Int(numChannels) {
                for sampleIndex in 0..<sampleCount {
                    outputBuffer.floatChannelData![channel][sampleIndex] = tailFloatPointer[sampleIndex * Int(numChannels) + channel]
                }
            }
            outputBuffer.frameLength = AVAudioFrameCount(sampleCount / Int(numChannels))
            let outputBufferListPointer = UnsafeMutableAudioBufferListPointer(outputBuffer.mutableAudioBufferList)
            print(outputBufferListPointer[0])
            print(outputBufferListPointer[1])
            print("bytes in circular buffer = \(availableBytes)")
            print("sample count = \(sampleCount)")
            print("outputBuffer.frameLength = \(outputBuffer.frameLength)")
            print("Circular buffer head = \(circularBuffer.head)")
            print("Circular buffer tail before consume = \(circularBuffer.tail)")
            TPCircularBufferConsume(&circularBuffer, outputBuffer.frameLength * numChannels * floatSize)
        }
        return outputBuffer
    }
    
    private func scheduleNextData() {
        let outputBuffer = getAndDeinterleaveNextData()
        if isPlayRequested {
            playerNode.scheduleBuffer(outputBuffer, completionHandler: scheduleNextData)
        }
    }
    
    func stop() {
        isPlayRequested = false
        iRx_stop()
        playerNode.stop()
        engine.stop()
        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to stop audio session. Error: \(error)")
        }
        TPCircularBufferCleanup(&circularBuffer)
    }
}
