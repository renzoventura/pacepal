import AVFoundation
import SwiftUI

class SoundService: ObservableObject {
    static let shared = SoundService()
    
    private var audioPlayer: AVAudioPlayer?
    private var isSoundEnabled: Bool = true
    
    private init() {
        // Initialize sound service
    }
    
    // MARK: - Sound Control
    func setSoundEnabled(_ enabled: Bool) {
        isSoundEnabled = enabled
    }
    
    func isSoundOn() -> Bool {
        return isSoundEnabled
    }
    
    // MARK: - Sound Effects
    func playButtonTap() {
        playSound(named: "button_tap", volume: 0.3)
    }
    
    func playRedeemCoupon() {
        playSound(named: "coin_collect", volume: 0.5)
    }
    
    func playGainXP() {
        playSound(named: "xp_gain", volume: 0.4)
    }
    
    func playBuyItem() {
        playSound(named: "purchase", volume: 0.5)
    }
    
    func playFeedCreature() {
        playSound(named: "eat", volume: 0.4)
    }
    
    func playEvolution() {
        playSound(named: "evolution", volume: 0.6)
    }
    
    func playError() {
        playSound(named: "error", volume: 0.4)
    }
    
    func playSuccess() {
        playSound(named: "success", volume: 0.5)
    }
    
    // MARK: - Private Methods
    private func playSound(named soundName: String, volume: Float) {
        guard isSoundEnabled else { return }
        
        // For now, we'll use system sounds as placeholders
        // In a real app, you would load actual sound files from the bundle
        let systemSound: SystemSoundID
        
        switch soundName {
        case "button_tap":
            systemSound = 1104 // Tock sound
        case "coin_collect":
            systemSound = 1057 // Coin sound
        case "xp_gain":
            systemSound = 1053 // Glass sound
        case "purchase":
            systemSound = 1054 // Glass sound
        case "eat":
            systemSound = 1105 // Pop sound
        case "evolution":
            systemSound = 1005 // New mail sound (more dramatic)
        case "error":
            systemSound = 1006 // Error sound
        case "success":
            systemSound = 1057 // Success sound
        default:
            systemSound = 1104 // Default tock sound
        }
        
        AudioServicesPlaySystemSound(systemSound)
    }
    
    // MARK: - Haptic Feedback
    func playHapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        let impactFeedback = UIImpactFeedbackGenerator(style: style)
        impactFeedback.impactOccurred()
    }
    
    func playNotificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let notificationFeedback = UINotificationFeedbackGenerator()
        notificationFeedback.notificationOccurred(type)
    }
}
