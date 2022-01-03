import Foundation
import AVFAudio

class Player {
    let audioSession = AVAudioSession.sharedInstance()
    let engine: AVAudioEngine
    let inputFormat: AVAudioFormat
    let outputFormat: AVAudioFormat
    let playerNode: AVAudioPlayerNode
    let converter: AVAudioConverter
    let frameCapacity: UInt32 = 1920
    let numChannels: UInt32 = 2
    let floatSize = UInt32(MemoryLayout<Float32>.stride)
    let inputSampleRate = Double(DEFAULT_RATE)
    
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
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        inputFormat = AVAudioFormat(commonFormat: AVAudioCommonFormat.pcmFormatFloat32, sampleRate: inputSampleRate, channels: numChannels, interleaved: true)!
        outputFormat = AVAudioFormat(standardFormatWithSampleRate: inputSampleRate, channels: numChannels)!
        converter = AVAudioConverter(from: inputFormat, to: outputFormat)!
        
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.outputNode, format: outputFormat)
        circularBuffer = TPCircularBuffer()
        _TPCircularBufferInit(&circularBuffer, frameCapacity, MemoryLayout<TPCircularBuffer>.stride)
        engine.prepare()
    }
        
    func start() {
        isPlayRequested = true
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
        playNextData()
        playerNode.play()
    }
    
    func playNextData() {
        if (isPlayRequested) {
            let interleavedBuffer = AVAudioPCMBuffer(pcmFormat: inputFormat, frameCapacity: frameCapacity)!
            let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: frameCapacity)!
            var availableBytes: UInt32 = 0
            let inputBufferTail = TPCircularBufferTail(&circularBuffer, &availableBytes)
            if (inputBufferTail != nil) {
                interleavedBuffer.floatChannelData![0].initialize(from: inputBufferTail!.bindMemory(to: Float.self, capacity: Int(availableBytes)), count: Int(availableBytes))//copyMemory(from: inputBufferTail!, byteCount: Int(availableBytes))
                interleavedBuffer.frameLength = AVAudioFrameCount(availableBytes / floatSize / numChannels)
                var frameLength = interleavedBuffer.frameLength
                var bytesize = interleavedBuffer.audioBufferList[0].mBuffers.mDataByteSize
                do {
                    try converter.convert(to: outputBuffer, from: interleavedBuffer)
                } catch {
                    print("Buffer conversion has failed. Error: \(error)")
                }
            }
            //outputBuffer.frameLength = AVAudioFrameCount(availableBytes / floatSize)
            let bufferListPointer = UnsafeMutableAudioBufferListPointer(outputBuffer.mutableAudioBufferList)
            print(bufferListPointer.unsafeMutablePointer.pointee.mBuffers.mDataByteSize)
            print(bufferListPointer.unsafeMutablePointer.advanced(by: 1).pointee.mBuffers.mDataByteSize)
            print("outputBuffer.frameLength = \(outputBuffer.frameLength)")
            print("outputBuffer.mutableAudioBufferList[0].mBuffers.mDataByteSize = \(outputBuffer.mutableAudioBufferList[0].mBuffers.mDataByteSize)")
            print("outputBuffer.mutableAudioBufferList[1].mBuffers.mDataByteSize = \(outputBuffer.mutableAudioBufferList[1].mBuffers.mDataByteSize)")
            print("outputBuffer.mutableAudioBufferList.pointee.mNumberBuffers = \(outputBuffer.mutableAudioBufferList.pointee.mNumberBuffers)")
            TPCircularBufferConsume(&circularBuffer, availableBytes)
            playerNode.scheduleBuffer(outputBuffer, completionHandler: playNextData)
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
