import Foundation
import AVFAudio

class Player {
    let audioSession = AVAudioSession.sharedInstance()
    let engine: AVAudioEngine
    let inputFormat: AVAudioFormat
    let outputFormat: AVAudioFormat
    let playerNode: AVAudioPlayerNode
    let converter: AVAudioConverter
    let samplesPerPacket = UInt32(SAMPLES)
    let numChannels: UInt32 = 2
    let floatSize = UInt32(MemoryLayout<Float32>.stride)
    let inputSampleRate = Double(RATE)
    let circularBufferLength = UInt32(BUFFER_LENGTH)
    let packetSize: UInt32
    
    var isPlayRequested = false
    var circularBuffer: TPCircularBuffer
        
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
        packetSize = samplesPerPacket * floatSize * numChannels
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        inputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: inputSampleRate, channels: numChannels, interleaved: true)!
        outputFormat = AVAudioFormat(standardFormatWithSampleRate: inputSampleRate, channels: numChannels)!
        converter = AVAudioConverter(from: inputFormat, to: outputFormat)!
        
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.outputNode, format: outputFormat)
        circularBuffer = TPCircularBuffer()
        engine.prepare()
    }
        
    func start() {
        isPlayRequested = true
        _TPCircularBufferInit(&circularBuffer, circularBufferLength, MemoryLayout<TPCircularBuffer>.stride)
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
        playerNode.play()
        iRx_start(&circularBuffer)
        playNextData()
    }
    
    func playNextData() {
        if (isPlayRequested) {
            let interleavedBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: samplesPerPacket)!
            let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: samplesPerPacket)!
            var availableBytes: UInt32 = 0
            let inputBufferTail = TPCircularBufferTail(&circularBuffer, &availableBytes)
            if (inputBufferTail != nil) {
                interleavedBuffer.floatChannelData![0].initialize(from: inputBufferTail!.bindMemory(to: Float.self, capacity: Int(samplesPerPacket)), count: Int(samplesPerPacket))//copyMemory(from: inputBufferTail!, byteCount: Int(packetSize))
                interleavedBuffer.frameLength = AVAudioFrameCount(samplesPerPacket)
                do {
                    try converter.convert(to: outputBuffer, from: interleavedBuffer)
                } catch {
                    print("Buffer conversion has failed. Error: \(error)")
                }
            }
            let bufferListPointer = UnsafeMutableAudioBufferListPointer(outputBuffer.mutableAudioBufferList)
            print(bufferListPointer[0])
            print(bufferListPointer[1])
            print("interleavedBuffer.frameLength = \(interleavedBuffer.frameLength)")
            print("outputBuffer.frameLength = \(outputBuffer.frameLength)")
            TPCircularBufferConsume(&circularBuffer, availableBytes >= packetSize ? packetSize : availableBytes)
            playerNode.scheduleBuffer(outputBuffer, completionHandler: playNextData)
        }
    }
    
    func stop() {
        isPlayRequested = false
        playerNode.stop()
        engine.stop()
        iRx_stop()
        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to stop audio session. Error: \(error)")
        }
        TPCircularBufferCleanup(&circularBuffer)
    }
}
