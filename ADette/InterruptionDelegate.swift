import Foundation

protocol InterruptionDelegate: AnyObject {
    func reactToInterruption(_ sender: InterruptionNotifier, type: InterruptionCause)
}
