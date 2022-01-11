import Foundation
import AVFAudio

class Player {
    let audioSession = AVAudioSession.sharedInstance()
    let engine: AVAudioEngine
    let outputFormat: AVAudioFormat
    let playerNode: AVAudioPlayerNode
    let frameSize = UInt32(FRAME_SIZE)
    let numChannels = UInt32(CHANNELS)
    let floatSize = UInt32(MemoryLayout<Float32>.stride)
    let sampleRate = Double(RATE)
    let bufferLength = UInt32(BUFFER_LENGTH)
    let numSchedulers: UInt32 = 2
    
    var isPlayRequested = false
    var circularBuffer: TPCircularBuffer
    var availableBytes: UInt32 = 0
        
    init() {
        print("player initializing")
        do {
            if #available(iOS 11.0, *) {
                try audioSession.setCategory(.playback, mode: .spokenAudio, policy: .longForm)
            } else {
                try audioSession.setCategory(.playback, mode: .spokenAudio)
            }
            print("audio session category set successfully")
        } catch {
            print("Failed to set audio session category. Error: \(error)")
        }
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        outputFormat = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: numChannels)!
        circularBuffer = TPCircularBuffer()
        
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.outputNode, format: outputFormat)
        engine.prepare()
    }
    deinit {
        iRx_stop()
        iRx_deinit()
    }
        
    func start() {
        isPlayRequested = true
        _TPCircularBufferInit(&circularBuffer, bufferLength, MemoryLayout<TPCircularBuffer>.stride)
        iRx_start(&circularBuffer)
        do {
            try audioSession.setActive(true)
        } catch {
            print("Failed to start audio session. Error: \(error)")
        }
        do {
            try engine.start()
        } catch {
            print("Failed to start audio engine. Error: \(error)")
        }
        
        for _ in 1...numSchedulers {
            scheduleNextData()
        }
        playerNode.play()
    }
    
    func getAndDeinterleaveNextData () -> AVAudioPCMBuffer {
        let inputBufferTail = TPCircularBufferTail(&circularBuffer, &availableBytes)
        let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: bufferLength)!
        if inputBufferTail != nil {
            let sampleCount = Int(availableBytes / numSchedulers / floatSize)
            let tailFloatPointer = inputBufferTail!.bindMemory(to: Float.self, capacity: sampleCount)
            for i in stride(from: 0, to: sampleCount - 2, by: 2) {
                outputBuffer.floatChannelData![0]
                    .advanced(by: i/2)
                    .initialize(to: tailFloatPointer
                                    .advanced(by: i)
                                    .pointee)
            }
            for i in stride(from: 1, to: sampleCount - 1, by: 2) {
                outputBuffer.floatChannelData![1]
                    .advanced(by: i/2)
                    .initialize(to: tailFloatPointer
                                    .advanced(by: i)
                                    .pointee)
            }
            outputBuffer.frameLength = AVAudioFrameCount(sampleCount / Int(numChannels))
            let outputBufferListPointer = UnsafeMutableAudioBufferListPointer(outputBuffer.mutableAudioBufferList)
            print(outputBufferListPointer[0])
            print(outputBufferListPointer[1])
            print("bytes in circular buffer = \(availableBytes)")
            print("outputBuffer.frameLength = \(outputBuffer.frameLength)")
            TPCircularBufferConsume(&circularBuffer, outputBuffer.frameLength * numChannels * floatSize)
        }
        return outputBuffer
    }
    
    func scheduleNextData() {
        if isPlayRequested {
            let outputBuffer = getAndDeinterleaveNextData()
            playerNode.scheduleBuffer(outputBuffer, completionHandler: scheduleNextData)
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
        iRx_stop()
        TPCircularBufferCleanup(&circularBuffer)
    }
}
