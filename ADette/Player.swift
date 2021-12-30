import Foundation
import AVFAudio

class Player {
    let engine: AVAudioEngine
    let audioSession: AVAudioSession
    let format: AVAudioFormat
    let playerNode: AVAudioPlayerNode
    let outputBuffer: AVAudioPCMBuffer
    let frameCapacity: UInt32 = 1920
    
    var inputBuffer: TPCircularBuffer
        
    init() {
        print("player initializing")
        engine = AVAudioEngine()
        playerNode = AVAudioPlayerNode()
        audioSession = AVAudioSession.sharedInstance()
        format = AVAudioFormat(standardFormatWithSampleRate: audioSession.sampleRate, channels: 2)!
        outputBuffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCapacity)!
        
        engine.attach(playerNode)
        engine.connect(playerNode, to: engine.outputNode, format: format)
        inputBuffer = TPCircularBuffer()
        _TPCircularBufferInit(&inputBuffer, frameCapacity, MemoryLayout<TPCircularBuffer>.stride)
        playerNode.scheduleBuffer(outputBuffer, completionHandler: fillOutputBuffer)
        engine.prepare()
    }
        
    func start() {
        print("from player.start(): \(Thread.current)")
        print(Thread.current.isMainThread)
        iRx_start(&inputBuffer)
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
    }
    
    func stop() {
        iRx_stop()
        playerNode.stop()
        engine.stop()
        do {
            try audioSession.setActive(false)
        } catch {
            print("Failed to stop audio session. Error: \(error)")
        }
        TPCircularBufferCleanup(&inputBuffer)
    }
    
    func fillOutputBuffer() {
        let availableBytes = UnsafeMutablePointer<UInt32>.allocate(capacity: 1)
        var inputBufferTail = UnsafeMutableRawPointer.allocate(byteCount: 1, alignment: 8)
        inputBufferTail = TPCircularBufferTail(&inputBuffer, availableBytes)
        memcpy(outputBuffer.mutableAudioBufferList.pointee.mBuffers.mData, inputBufferTail, Int(availableBytes.pointee))
        TPCircularBufferConsume(&inputBuffer, availableBytes.pointee)
    }
}
