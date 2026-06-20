import AVFoundation

final class AudioManager {
    static let shared = AudioManager()

    private let mainTrackName = "bgm_main"
    private let fireTrackName = "bgm_fire"

    private let mainVolume: Float = 0.7
    private let fireVolume: Float = 0.85
    private let crossfade: TimeInterval = 1.0

    private var bgmMain: AVAudioPlayer?
    private var bgmFire: AVAudioPlayer?
    private var activeSFX: [AVAudioPlayer] = []
    private var inFireMode = false
    private(set) var isMuted = false

    private init() {
        configureSession()
    }

    // MARK: - API publique

    func startMainMusic() {
        guard !isMuted else { return }
        guard let player = makePlayer(named: mainTrackName, volume: 0) else { return }
        player.numberOfLoops = -1
        player.play()
        player.setVolume(mainVolume, fadeDuration: crossfade)
        bgmMain = player
    }

    func stopMusic() {
        fadeOutAndStop(bgmMain, duration: 0.6)
        fadeOutAndStop(bgmFire, duration: 0.6)
        bgmMain = nil
        bgmFire = nil
        inFireMode = false
    }

    func enterFire() {
        guard !isMuted, !inFireMode else { return }
        inFireMode = true
        guard let player = makePlayer(named: fireTrackName, volume: 0) else { return }
        player.numberOfLoops = -1
        player.play()
        player.setVolume(fireVolume, fadeDuration: crossfade)
        bgmFire = player
        bgmMain?.setVolume(0, fadeDuration: crossfade)
    }

    func exitFire() {
        guard inFireMode else { return }
        inFireMode = false
        fadeOutAndStop(bgmFire, duration: crossfade)
        bgmFire = nil
        bgmMain?.setVolume(mainVolume, fadeDuration: crossfade)
    }

    func playSwitch() { playSFX("sfx_switch", volume: 0.4) }
    func playCoin()   { playSFX("sfx_coin", volume: 0.55) }
    func playCrash()  { playSFX("sfx_crash", volume: 0.9) }

    func setMuted(_ muted: Bool) {
        guard muted != isMuted else { return }
        isMuted = muted
        if muted { stopMusic() }
    }

    // MARK: - Détails internes

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[Audio] session setup failed: \(error)")
        }
    }

    private func makePlayer(named name: String, volume: Float) -> AVAudioPlayer? {
        let exts = ["mp3", "m4a", "wav", "aac"]
        for ext in exts {
            if let url = Bundle.main.url(forResource: name, withExtension: ext) {
                do {
                    let p = try AVAudioPlayer(contentsOf: url)
                    p.volume = volume
                    p.prepareToPlay()
                    return p
                } catch {
                    print("[Audio] failed to load \(name).\(ext): \(error)")
                }
            }
        }
        return nil
    }

    private func playSFX(_ name: String, volume: Float) {
        guard !isMuted else { return }
        guard let player = makePlayer(named: name, volume: volume) else { return }
        activeSFX.append(player)
        player.play()
        let duration = player.duration + 0.05
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
            self?.activeSFX.removeAll { $0 === player }
        }
    }

    private func fadeOutAndStop(_ player: AVAudioPlayer?, duration: TimeInterval) {
        guard let player else { return }
        player.setVolume(0, fadeDuration: duration)
        DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.05) {
            player.stop()
        }
    }
}
