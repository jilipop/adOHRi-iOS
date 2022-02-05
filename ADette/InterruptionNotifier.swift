import Foundation

protocol InterruptionNotifier {
    func sendInterruptionNotification(type: InterruptionCause)
}
