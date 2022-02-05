import Foundation

protocol InterruptionNotifier {
    func interruptionDidOccur(cause: InterruptionCause)
}
