import Foundation

protocol InterruptionNotifier {
    func sendInterruptionNotification(cause: InterruptionCause)
}
