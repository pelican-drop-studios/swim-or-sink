//
//  ContentView.swift
//  Swim or Sink
//
//  Created by Brayden Weismantel on 17/3/2026.
//

import SwiftUI
import AVFoundation
import StoreKit

// MARK: - Sound Manager
class SoundManager {
    static let shared = SoundManager()
    var isMuted: Bool = false

    private var popPlayer: AVAudioPlayer?
    private var drownPlayer: AVAudioPlayer?
    private var splashPlayer: AVAudioPlayer?

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
        try? AVAudioSession.sharedInstance().setActive(true)
        popPlayer = Self.makeBubblePopPlayer()
        popPlayer?.prepareToPlay()
        drownPlayer = Self.makeDrownPlayer()
        drownPlayer?.prepareToPlay()
        splashPlayer = Self.makeSplashPlayer()
        splashPlayer?.prepareToPlay()
    }

    func playBubblePop() {
        guard !isMuted else { return }
        popPlayer?.currentTime = 0
        popPlayer?.play()
    }

    func playDrown() {
        guard !isMuted else { return }
        drownPlayer?.currentTime = 0
        drownPlayer?.play()
    }

    func playSplash() {
        guard !isMuted else { return }
        splashPlayer?.currentTime = 0
        splashPlayer?.play()
    }

    private static func makeBubblePopPlayer() -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let duration: Double = 0.12
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)

        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            let progress = t / duration
            // Quick descending frequency (800Hz → 200Hz) with fast decay
            let freq = 800.0 - 600.0 * progress
            let envelope = (1.0 - progress) * (1.0 - progress)
            let sample = Float(sin(2.0 * .pi * freq * t) * envelope * 0.4)
            samples[i] = sample
        }

        // Build a WAV in memory
        let dataSize = sampleCount * 2
        let fileSize = 44 + dataSize
        var data = Data(capacity: fileSize)

        // RIFF header
        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46]) // "RIFF"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize - 8).littleEndian) { Array($0) })
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45]) // "WAVE"
        // fmt chunk
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20]) // "fmt "
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })  // PCM
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })  // mono
        data.append(contentsOf: withUnsafeBytes(of: UInt32(44100).littleEndian) { Array($0) }) // sample rate
        data.append(contentsOf: withUnsafeBytes(of: UInt32(44100 * 2).littleEndian) { Array($0) }) // byte rate
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })  // block align
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) }) // bits per sample
        // data chunk
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61]) // "data"
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        for sample in samples {
            let intSample = Int16(max(-1, min(1, sample)) * Float(Int16.max))
            data.append(contentsOf: withUnsafeBytes(of: intSample.littleEndian) { Array($0) })
        }

        return try? AVAudioPlayer(data: data)
    }

    private static func makeDrownPlayer() -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let duration: Double = 0.6
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)

        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            let progress = t / duration
            // Low descending gurgle: base tone drops from 300Hz to 80Hz
            let baseFreq = 300.0 - 220.0 * progress
            let base = sin(2.0 * .pi * baseFreq * t)
            // Wobble modulation for underwater gurgle effect
            let wobble = sin(2.0 * .pi * 18.0 * t) * 0.3
            // Bubble burst cluster in first half
            let bubbleBurst = progress < 0.4
                ? sin(2.0 * .pi * (500.0 - 300.0 * progress) * t) * (1.0 - progress / 0.4) * 0.25
                : 0.0
            // Envelope: quick attack, slow fade
            let envelope = (1.0 - progress * progress) * 0.45
            let sample = Float((base * (1.0 + wobble) + bubbleBurst) * envelope)
            samples[i] = sample
        }

        // Build WAV
        let dataSize = sampleCount * 2
        let fileSize = 44 + dataSize
        var data = Data(capacity: fileSize)

        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46])
        data.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize - 8).littleEndian) { Array($0) })
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45])
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20])
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(44100).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(44100 * 2).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) })
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61])
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        for sample in samples {
            let intSample = Int16(max(-1, min(1, sample)) * Float(Int16.max))
            data.append(contentsOf: withUnsafeBytes(of: intSample.littleEndian) { Array($0) })
        }

        return try? AVAudioPlayer(data: data)
    }

    private static func makeSplashPlayer() -> AVAudioPlayer? {
        let sampleRate: Double = 44100
        let duration: Double = 0.08
        let sampleCount = Int(sampleRate * duration)
        var samples = [Float](repeating: 0, count: sampleCount)

        for i in 0..<sampleCount {
            let t = Double(i) / sampleRate
            let progress = t / duration
            // White noise burst shaped by a fast decay for a quick splash
            let noise = Double.random(in: -1...1)
            // High-pass feel: mix noise with a brief high tone
            let tone = sin(2.0 * .pi * 1200.0 * (1.0 - progress * 0.5) * t) * 0.3
            let envelope = (1.0 - progress) * (1.0 - progress) * 0.25
            samples[i] = Float((noise * 0.7 + tone) * envelope)
        }

        let dataSize = sampleCount * 2
        let fileSize = 44 + dataSize
        var data = Data(capacity: fileSize)

        data.append(contentsOf: [0x52, 0x49, 0x46, 0x46])
        data.append(contentsOf: withUnsafeBytes(of: UInt32(fileSize - 8).littleEndian) { Array($0) })
        data.append(contentsOf: [0x57, 0x41, 0x56, 0x45])
        data.append(contentsOf: [0x66, 0x6D, 0x74, 0x20])
        data.append(contentsOf: withUnsafeBytes(of: UInt32(16).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(1).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(44100).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt32(44100 * 2).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(2).littleEndian) { Array($0) })
        data.append(contentsOf: withUnsafeBytes(of: UInt16(16).littleEndian) { Array($0) })
        data.append(contentsOf: [0x64, 0x61, 0x74, 0x61])
        data.append(contentsOf: withUnsafeBytes(of: UInt32(dataSize).littleEndian) { Array($0) })

        for sample in samples {
            let intSample = Int16(max(-1, min(1, sample)) * Float(Int16.max))
            data.append(contentsOf: withUnsafeBytes(of: intSample.littleEndian) { Array($0) })
        }

        return try? AVAudioPlayer(data: data)
    }
}

// MARK: - Pixel Helper
/// Draws a single "pixel" block at grid coordinates for 8-bit style art
struct Pixel: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        Rectangle()
            .fill(color)
            .frame(width: size, height: size)
    }
}

/// Positions pixel art on a grid. originX/Y is the top-left of the sprite in points.
struct PixelGrid<Content: View>: View {
    let pixelSize: CGFloat
    let content: Content

    init(pixelSize: CGFloat = 3, @ViewBuilder content: () -> Content) {
        self.pixelSize = pixelSize
        self.content = content()
    }

    var body: some View {
        content
    }

    func pixel(x: Int, y: Int, color: Color) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: pixelSize, height: pixelSize)
            .offset(x: CGFloat(x) * pixelSize, y: CGFloat(y) * pixelSize)
    }
}

// MARK: - 8-Bit Color Palette
struct Palette {
    // Skin
    static let skin = Color(red: 1.0, green: 0.82, blue: 0.68)
    static let skinShadow = Color(red: 0.90, green: 0.68, blue: 0.52)
    // Hair - flowing blue (Dreamstime 8-bit style)
    static let hair = Color(red: 0.20, green: 0.45, blue: 0.90)
    static let hairHighlight = Color(red: 0.45, green: 0.65, blue: 1.0)
    static let hairDark = Color(red: 0.12, green: 0.28, blue: 0.65)
    // Tail - teal/aqua scales
    static let tailLight = Color(red: 0.15, green: 0.85, blue: 0.75)
    static let tail = Color(red: 0.05, green: 0.65, blue: 0.60)
    static let tailDark = Color(red: 0.02, green: 0.45, blue: 0.42)
    static let fin = Color(red: 0.10, green: 0.75, blue: 0.68)
    static let finEdge = Color(red: 0.20, green: 0.90, blue: 0.80)
    // Shell bikini - purple/violet
    static let shell = Color(red: 0.75, green: 0.35, blue: 0.85)
    static let shellLight = Color(red: 0.88, green: 0.55, blue: 1.0)
    static let shellDark = Color(red: 0.50, green: 0.20, blue: 0.65)
    // Eyes
    static let eyeWhite = Color.white
    static let eyeIris = Color(red: 0.15, green: 0.55, blue: 0.85)
    static let eyePupil = Color(red: 0.05, green: 0.05, blue: 0.15)
    // Lips
    static let lips = Color(red: 0.95, green: 0.45, blue: 0.50)
    // Ocean
    static let oceanTop = Color(red: 0.05, green: 0.50, blue: 0.80)
    static let oceanMid = Color(red: 0.02, green: 0.32, blue: 0.65)
    static let oceanDeep = Color(red: 0.01, green: 0.18, blue: 0.48)
    static let oceanFloor = Color(red: 0.01, green: 0.10, blue: 0.30)
    // Coral obstacle
    static let coralBright = Color(red: 1.0, green: 0.30, blue: 0.35)
    static let coral = Color(red: 0.85, green: 0.20, blue: 0.25)
    static let coralDark = Color(red: 0.60, green: 0.12, blue: 0.15)
    // Jellyfish obstacle
    static let jellyGlow = Color(red: 0.80, green: 0.40, blue: 1.0)
    static let jelly = Color(red: 0.55, green: 0.15, blue: 0.80)
    static let jellyDark = Color(red: 0.35, green: 0.05, blue: 0.55)
    // Shark obstacle
    static let sharkLight = Color(red: 0.50, green: 0.55, blue: 0.62)
    static let shark = Color(red: 0.35, green: 0.40, blue: 0.48)
    static let sharkDark = Color(red: 0.22, green: 0.26, blue: 0.32)
    // Pearl
    static let pearlWhite = Color(red: 1.0, green: 0.98, blue: 0.95)
    static let pearlShine = Color(red: 0.92, green: 0.88, blue: 1.0)
    static let pearlShadow = Color(red: 0.78, green: 0.72, blue: 0.88)
    // Sand
    static let sandLight = Color(red: 0.85, green: 0.78, blue: 0.55)
    static let sand = Color(red: 0.72, green: 0.62, blue: 0.42)
    static let sandDark = Color(red: 0.55, green: 0.48, blue: 0.32)
    // Kelp
    static let kelp = Color(red: 0.10, green: 0.55, blue: 0.25)
    static let kelpDark = Color(red: 0.05, green: 0.38, blue: 0.18)
}

// MARK: - Game Constants
enum Difficulty: String, CaseIterable {
    case easy, medium, hard

    var label: String {
        switch self {
        case .easy: return "EASY"
        case .medium: return "MEDIUM"
        case .hard: return "HARD"
        }
    }

    var description: String {
        switch self {
        case .easy: return "Calm waters"
        case .medium: return "Choppy seas"
        case .hard: return "The deep"
        }
    }

    var color: Color {
        switch self {
        case .easy: return Color(red: 0.3, green: 0.85, blue: 0.5)
        case .medium: return Color(red: 1.0, green: 0.78, blue: 0.2)
        case .hard: return Color(red: 1.0, green: 0.35, blue: 0.35)
        }
    }

    var scrollSpeed: CGFloat {
        switch self {
        case .easy: return 130
        case .medium: return 155
        case .hard: return 180
        }
    }

    var gapHeight: CGFloat {
        switch self {
        case .easy: return 280
        case .medium: return 250
        case .hard: return 220
        }
    }

    var gravity: CGFloat {
        switch self {
        case .easy: return 600
        case .medium: return 700
        case .hard: return 800
        }
    }

    var flapImpulse: CGFloat {
        switch self {
        case .easy: return -250
        case .medium: return -265
        case .hard: return -280
        }
    }

    var spawnInterval: CGFloat {
        switch self {
        case .easy: return 2.0
        case .medium: return 1.7
        case .hard: return 1.5
        }
    }
}

struct GameConfig {
    static let mermaiddSize: CGSize = CGSize(width: 54, height: 54)
    static let pearlSize: CGFloat = 22
    static let pixelSize: CGFloat = 3
}

// MARK: - Game Models
enum GameState { case menu, chooseDifficulty, playing, dead }
// Coral color schemes for variety
struct CoralColors {
    let bright: Color
    let mid: Color
    let dark: Color

    static let schemes: [CoralColors] = [
        // Classic red/pink coral
        CoralColors(bright: Color(red: 1.0, green: 0.30, blue: 0.35),
                    mid: Color(red: 0.85, green: 0.20, blue: 0.25),
                    dark: Color(red: 0.60, green: 0.12, blue: 0.15)),
        // Orange coral
        CoralColors(bright: Color(red: 1.0, green: 0.55, blue: 0.20),
                    mid: Color(red: 0.90, green: 0.40, blue: 0.12),
                    dark: Color(red: 0.65, green: 0.28, blue: 0.08)),
        // Purple coral
        CoralColors(bright: Color(red: 0.80, green: 0.35, blue: 0.85),
                    mid: Color(red: 0.60, green: 0.20, blue: 0.70),
                    dark: Color(red: 0.40, green: 0.10, blue: 0.50)),
        // Pink coral
        CoralColors(bright: Color(red: 1.0, green: 0.50, blue: 0.65),
                    mid: Color(red: 0.90, green: 0.35, blue: 0.50),
                    dark: Color(red: 0.65, green: 0.20, blue: 0.35)),
        // Teal/green coral
        CoralColors(bright: Color(red: 0.20, green: 0.85, blue: 0.70),
                    mid: Color(red: 0.10, green: 0.65, blue: 0.55),
                    dark: Color(red: 0.05, green: 0.45, blue: 0.38)),
        // Yellow coral
        CoralColors(bright: Color(red: 1.0, green: 0.82, blue: 0.25),
                    mid: Color(red: 0.90, green: 0.68, blue: 0.15),
                    dark: Color(red: 0.65, green: 0.48, blue: 0.10)),
    ]

    static func random() -> CoralColors {
        schemes.randomElement()!
    }
}

enum PearlType {
    case normal, gold, diamond

    var points: Int {
        switch self {
        case .normal: return 5
        case .gold: return 10
        case .diamond: return 20
        }
    }
}

struct Obstacle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var gapY: CGFloat
    var colorScheme: CoralColors
    var hasPearl: Bool
    var pearlType: PearlType = .normal
    var pearlCollected: Bool = false
    var scored: Bool = false
}

struct Bubble: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var speed: CGFloat
}

struct Particle: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var speed: CGFloat
}

struct TrailBubble: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var opacity: Double
    var life: CGFloat // 0..1, counts down
    var vx: CGFloat
    var vy: CGFloat
}

// MARK: - Game ViewModel
@Observable
class GameViewModel {
    var state: GameState = .menu
    var mermaidY: CGFloat = 0
    var mermaidVelocity: CGFloat = 0
    var obstacles: [Obstacle] = []
    var bubbles: [Bubble] = []
    var particles: [Particle] = []
    var trailBubbles: [TrailBubble] = []
    var score: Int = 0
    var pearls: Int = 0
    var bestScore: Int = 0
    var mermaidAngle: Double = 0
    var isDead: Bool = false
    var flashRed: Bool = false
    var swimFrame: Int = 0 // 0-3 for 4-frame swim cycle
    var flapStrength: CGFloat = 0 // 1.0 on flap, decays to 0

    var difficulty: Difficulty = .hard
    var screenWidth: CGFloat = 390
    var screenHeight: CGFloat = 844

    private var lastTime: Date = Date()
    private var timer: Timer?
    private var obstacleTimer: CGFloat = 0
    private var bubbleTimer: CGFloat = 0
    private var particleTimer: CGFloat = 0
    private var distanceTraveled: CGFloat = 0
    private var swimTimer: CGFloat = 0

    func startGame(width: CGFloat, height: CGFloat, difficulty: Difficulty) {
        self.difficulty = difficulty
        screenWidth = width
        screenHeight = height
        mermaidY = height / 2
        mermaidVelocity = 0
        obstacles = []
        bubbles = []
        particles = []
        trailBubbles = []
        score = 0
        pearls = 0
        isDead = false
        flashRed = false
        swimFrame = 0
        flapStrength = 0
        obstacleTimer = 0
        bubbleTimer = 0
        particleTimer = 0
        swimTimer = 0
        distanceTraveled = 0
        state = .playing
        lastTime = Date()
        spawnInitialBubbles()
        spawnInitialParticles()
        startLoop()
    }

    func flap() {
        guard state == .playing else { return }
        mermaidVelocity = difficulty.flapImpulse
        flapStrength = 1.0
        SoundManager.shared.playSplash()
        // Spawn trail bubbles behind the mermaid
        let mermaidX = screenWidth * 0.25
        for _ in 0..<4 {
            let tb = TrailBubble(
                x: mermaidX - CGFloat.random(in: 10...25),
                y: mermaidY + CGFloat.random(in: -5...15),
                size: CGFloat.random(in: 3...8),
                opacity: Double.random(in: 0.5...0.9),
                life: 1.0,
                vx: CGFloat.random(in: -30 ... -10),
                vy: CGFloat.random(in: -40 ... -15)
            )
            trailBubbles.append(tb)
        }
    }

    private func startLoop() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1/60, repeats: true) { [weak self] _ in
            self?.update()
        }
    }

    private func update() {
        guard state == .playing else { return }
        let now = Date()
        let dt = min(now.timeIntervalSince(lastTime), 0.05)
        lastTime = now
        let dtF = CGFloat(dt)

        // Physics
        mermaidVelocity += difficulty.gravity * dtF
        mermaidY += mermaidVelocity * dtF
        mermaidAngle = Double(min(max(mermaidVelocity / 6, -25), 35))

        // Boundaries
        let mermaidTop = mermaidY - GameConfig.mermaiddSize.height / 2
        let mermaidBottom = mermaidY + GameConfig.mermaiddSize.height / 2
        if mermaidTop <= 0 || mermaidBottom >= screenHeight { triggerDeath(); return }

        // Obstacles
        obstacleTimer += dtF
        let spawnInterval = max(difficulty.spawnInterval - CGFloat(score) * 0.03, difficulty.spawnInterval * 0.65)
        if obstacleTimer >= spawnInterval {
            spawnObstacle()
            obstacleTimer = 0
        }

        for i in obstacles.indices {
            obstacles[i].x -= difficulty.scrollSpeed * dtF
        }

        // Score & collision
        let mermaidX: CGFloat = screenWidth * 0.25
        for i in obstacles.indices {
            let obs = obstacles[i]
            let gapTop = obs.gapY - difficulty.gapHeight / 2
            let gapBottom = obs.gapY + difficulty.gapHeight / 2
            let obsLeft = obs.x - 28
            let obsRight = obs.x + 28
            let mLeft = mermaidX - GameConfig.mermaiddSize.width / 2 + 16
            let mRight = mermaidX + GameConfig.mermaiddSize.width / 2 - 16
            let mTop = mermaidY - GameConfig.mermaiddSize.height / 2 + 16
            let mBottom = mermaidY + GameConfig.mermaiddSize.height / 2 - 16

            if mRight > obsLeft && mLeft < obsRight {
                if mTop < gapTop || mBottom > gapBottom {
                    triggerDeath(); return
                }
            }

            // Pearl collect
            if !obs.pearlCollected && obs.hasPearl {
                let pearlX = obs.x
                let pearlY = obs.gapY
                let dx = abs(pearlX - mermaidX)
                let dy = abs(pearlY - mermaidY)
                if dx < 24 && dy < 24 {
                    obstacles[i].pearlCollected = true
                    pearls += 1
                    score += obs.pearlType.points
                    SoundManager.shared.playBubblePop()
                }
            }
        }

        // Scoring — increment when obstacle passes mermaid
        for i in obstacles.indices {
            if !obstacles[i].scored && obstacles[i].x + 30 < mermaidX {
                obstacles[i].scored = true
                score += 1
            }
        }

        // Remove off-screen
        obstacles.removeAll { $0.x < -80 }

        // Bubbles
        bubbleTimer += dtF
        if bubbleTimer > 0.3 {
            spawnBubble()
            bubbleTimer = 0
        }
        for i in bubbles.indices {
            bubbles[i].y -= bubbles[i].speed * dtF
            bubbles[i].x += sin(bubbles[i].y / 30) * 0.3
        }
        bubbles.removeAll { $0.y < -20 }

        // Floating particles
        particleTimer += dtF
        if particleTimer > 0.8 {
            spawnParticle()
            particleTimer = 0
        }
        for i in particles.indices {
            particles[i].y -= particles[i].speed * dtF
            particles[i].x += sin(particles[i].y / 50 + particles[i].x / 20) * 0.15
        }
        particles.removeAll { $0.y < -10 }

        // Swim frame cycle (4 frames)
        swimTimer += dtF
        let swimSpeed: CGFloat = flapStrength > 0.3 ? 0.08 : 0.15
        if swimTimer >= swimSpeed {
            swimFrame = (swimFrame + 1) % 4
            swimTimer = 0
        }

        // Decay flap strength
        flapStrength = max(flapStrength - dtF * 2.5, 0)

        // Trail bubbles
        for i in trailBubbles.indices {
            trailBubbles[i].x += trailBubbles[i].vx * dtF
            trailBubbles[i].y += trailBubbles[i].vy * dtF
            trailBubbles[i].vy -= 20 * dtF // float up
            trailBubbles[i].life -= dtF * 1.5
            trailBubbles[i].opacity = Double(max(trailBubbles[i].life, 0))
            trailBubbles[i].size *= (1 + dtF * 0.5) // expand slightly
        }
        trailBubbles.removeAll { $0.life <= 0 }
    }

    private func spawnObstacle() {
        let minGap: CGFloat = 150
        let maxGap: CGFloat = screenHeight - 150
        let gapY = CGFloat.random(in: minGap...maxGap)
        let hasPearl = Bool.random() && Bool.random()
        let pearlType: PearlType = {
            guard hasPearl else { return .normal }
            let roll = Int.random(in: 0..<100)
            if roll < 3 { return .diamond }   // ~3% of pearls
            if roll < 18 { return .gold }      // ~15% of pearls
            return .normal
        }()
        obstacles.append(Obstacle(x: screenWidth + 30, gapY: gapY, colorScheme: CoralColors.random(), hasPearl: hasPearl, pearlType: pearlType))
    }

    private func spawnBubble() {
        let b = Bubble(
            x: CGFloat.random(in: 0...screenWidth),
            y: screenHeight + 10,
            size: CGFloat.random(in: 4...14),
            speed: CGFloat.random(in: 40...90)
        )
        bubbles.append(b)
    }

    private func spawnParticle() {
        let p = Particle(
            x: CGFloat.random(in: 0...screenWidth),
            y: screenHeight + 5,
            size: CGFloat.random(in: 2...5),
            opacity: Double.random(in: 0.15...0.4),
            speed: CGFloat.random(in: 15...35)
        )
        particles.append(p)
    }

    private func spawnInitialBubbles() {
        for _ in 0..<20 {
            let b = Bubble(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: 0...screenHeight),
                size: CGFloat.random(in: 4...14),
                speed: CGFloat.random(in: 40...90)
            )
            bubbles.append(b)
        }
    }

    private func spawnInitialParticles() {
        for _ in 0..<15 {
            let p = Particle(
                x: CGFloat.random(in: 0...screenWidth),
                y: CGFloat.random(in: 0...screenHeight),
                size: CGFloat.random(in: 2...5),
                opacity: Double.random(in: 0.15...0.4),
                speed: CGFloat.random(in: 15...35)
            )
            particles.append(p)
        }
    }

    private func triggerDeath() {
        state = .dead
        timer?.invalidate()
        if score > bestScore { bestScore = score }
        SoundManager.shared.playDrown()
        withAnimation { flashRed = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.flashRed = false
        }
    }
}

// MARK: - Main Content View
struct ContentView: View {
    @State private var vm = GameViewModel()
    @Environment(StoreManager.self) private var storeManager
    @Environment(AdManager.self) private var adManager

    var body: some View {
        GeometryReader { geo in
            ZStack {
                OceanBackground(screenHeight: geo.size.height, screenWidth: geo.size.width)
                ParticleLayer(particles: vm.particles)
                BubbleLayer(bubbles: vm.bubbles)

                if vm.state == .menu || vm.state == .chooseDifficulty {
                    MenuBubbles(screenWidth: geo.size.width, screenHeight: geo.size.height)
                }

                if vm.state == .menu {
                    MenuView(onStart: { vm.state = .chooseDifficulty }, storeManager: storeManager)
                } else if vm.state == .chooseDifficulty {
                    DifficultySelectView { difficulty in
                        vm.startGame(width: geo.size.width, height: geo.size.height, difficulty: difficulty)
                    }
                    .transition(.opacity)
                } else {
                    GameView(vm: vm, size: geo.size)
                }

                // Banner ad — menu and death screens only
                if !storeManager.isAdsRemoved && (vm.state == .menu || vm.state == .playing || vm.state == .dead) {
                    VStack {
                        Spacer()
                        PlaceholderBannerAd()
                    }
                }

                // Interstitial ad overlay
                if adManager.showingInterstitial && !storeManager.isAdsRemoved {
                    PlaceholderInterstitialAd {
                        adManager.dismissInterstitial()
                    }
                }
            }
            .ignoresSafeArea()
            .onAppear {
                vm.screenWidth = geo.size.width
                vm.screenHeight = geo.size.height
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Menu Bubbles
struct MenuBubbles: View {
    let screenWidth: CGFloat
    let screenHeight: CGFloat

    struct FloatingBubble: Identifiable {
        let id = UUID()
        var x: CGFloat
        var y: CGFloat
        var size: CGFloat
        var speed: CGFloat
    }

    @State private var bubbles: [FloatingBubble] = []
    @State private var timer: Timer?

    var body: some View {
        Canvas { context, canvasSize in
            for b in bubbles {
                let rect = CGRect(x: b.x - b.size / 2, y: b.y - b.size / 2, width: b.size, height: b.size)
                // Ring
                context.stroke(Circle().path(in: rect), with: .color(.white.opacity(0.25)), lineWidth: 1.5)
                // Highlight dot
                let dotSize = max(b.size * 0.25, 1.5)
                let dotRect = CGRect(x: b.x - b.size * 0.2 - dotSize / 2,
                                     y: b.y - b.size * 0.2 - dotSize / 2,
                                     width: dotSize, height: dotSize)
                context.fill(Circle().path(in: dotRect), with: .color(.white.opacity(0.4)))
            }
        }
        .allowsHitTesting(false)
        .onAppear { startBubbles() }
        .onDisappear { timer?.invalidate(); timer = nil }
    }

    private func startBubbles() {
        // Seed initial bubbles spread across the screen
        for _ in 0..<20 {
            bubbles.append(FloatingBubble(
                x: .random(in: 0...screenWidth),
                y: .random(in: 0...screenHeight),
                size: .random(in: 4...14),
                speed: .random(in: 30...70)
            ))
        }
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { _ in
            let dt: CGFloat = 1.0 / 30.0
            for i in bubbles.indices {
                bubbles[i].y -= bubbles[i].speed * dt
                bubbles[i].x += sin(bubbles[i].y / 30) * 0.3
            }
            bubbles.removeAll { $0.y < -20 }
            // Spawn new ones from the bottom
            if Bool.random() {
                bubbles.append(FloatingBubble(
                    x: .random(in: 0...screenWidth),
                    y: screenHeight + 10,
                    size: .random(in: 4...14),
                    speed: .random(in: 30...70)
                ))
            }
        }
    }
}

// MARK: - Difficulty Select
struct DifficultySelectView: View {
    let onSelect: (Difficulty) -> Void
    @State private var appear = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("CHOOSE DEPTH")
                .font(.system(size: 32, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.6), radius: 0, x: 3, y: 3)
                .shadow(color: Palette.tailLight.opacity(0.5), radius: 10)

            VStack(spacing: 16) {
                ForEach(Difficulty.allCases, id: \.self) { difficulty in
                    Button {
                        onSelect(difficulty)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(difficulty.label)
                                    .font(.system(size: 20, weight: .heavy, design: .monospaced))
                                    .foregroundColor(.white)
                                Text(difficulty.description)
                                    .font(.system(size: 13, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            Spacer()
                            // Difficulty indicator dots
                            HStack(spacing: 4) {
                                let filled = difficulty == .easy ? 1 : difficulty == .medium ? 2 : 3
                                ForEach(0..<3, id: \.self) { i in
                                    Rectangle()
                                        .fill(i < filled ? difficulty.color : .white.opacity(0.2))
                                        .frame(width: 10, height: 10)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(difficulty.color.opacity(0.2))
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(difficulty.color.opacity(0.6), lineWidth: 2)
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 40)

            Spacer()
            Spacer()
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 30)
        .animation(.easeOut(duration: 0.4), value: appear)
        .onAppear { appear = true }
    }
}

// MARK: - Ocean Background
struct OceanBackground: View {
    let screenHeight: CGFloat
    let screenWidth: CGFloat

    var body: some View {
        ZStack {
            // Deep ocean gradient
            LinearGradient(
                colors: [
                    Palette.oceanTop,
                    Palette.oceanMid,
                    Palette.oceanDeep,
                    Palette.oceanFloor
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            // Volumetric light rays from surface
            ForEach(0..<7, id: \.self) { i in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.06), Color.white.opacity(0.0)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: CGFloat.random(in: 30...60), height: screenHeight * 0.7)
                    .rotationEffect(.degrees(Double(i) * 8 - 22))
                    .offset(x: CGFloat(i) * 60 - 180, y: -screenHeight * 0.15)
            }

            // Sandy seabed
            VStack {
                Spacer()
                ZStack(alignment: .bottom) {
                    // Sand base
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Palette.sand.opacity(0.0), Palette.sand.opacity(0.3), Palette.sandDark.opacity(0.4)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 60)

                    // Pixel sand bumps
                    HStack(spacing: 0) {
                        ForEach(0..<Int(screenWidth / 6), id: \.self) { i in
                            let h: CGFloat = [4, 7, 3, 8, 5, 6, 3, 7, 4, 8, 6, 5][i % 12]
                            Rectangle()
                                .fill(Palette.sandLight.opacity(0.35))
                                .frame(width: 6, height: h)
                        }
                    }
                    .frame(height: 10, alignment: .bottom)
                    .offset(y: -20)

                    // Decorative kelp strands
                    ForEach(0..<5, id: \.self) { i in
                        KelpStrand()
                            .offset(x: CGFloat(i) * (screenWidth / 5) - screenWidth / 2 + 40)
                    }
                }
            }
        }
    }
}

// MARK: - Kelp Strand
struct KelpStrand: View {
    @State private var sway = false
    let height: CGFloat = CGFloat.random(in: 40...80)

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<Int(height / 6), id: \.self) { i in
                RoundedRectangle(cornerRadius: 1)
                    .fill(i % 3 == 0 ? Palette.kelp : Palette.kelpDark)
                    .frame(width: CGFloat.random(in: 5...9), height: 6)
                    .offset(x: sway ? CGFloat(i % 2 == 0 ? 2 : -2) : CGFloat(i % 2 == 0 ? -2 : 2))
            }
        }
        .animation(.easeInOut(duration: Double.random(in: 2.0...3.5)).repeatForever(autoreverses: true), value: sway)
        .onAppear { sway = true }
    }
}

// MARK: - Particle Layer (floating plankton/dust)
struct ParticleLayer: View {
    let particles: [Particle]
    var body: some View {
        ForEach(particles) { p in
            Circle()
                .fill(Color.white.opacity(p.opacity))
                .frame(width: p.size, height: p.size)
                .position(x: p.x, y: p.y)
        }
    }
}

// MARK: - Bubble Layer
struct BubbleLayer: View {
    let bubbles: [Bubble]
    var body: some View {
        ForEach(bubbles) { b in
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.30), lineWidth: 1.5)
                    .frame(width: b.size, height: b.size)
                // Highlight pixel
                Circle()
                    .fill(Color.white.opacity(0.45))
                    .frame(width: max(b.size * 0.25, 1.5), height: max(b.size * 0.25, 1.5))
                    .offset(x: -b.size * 0.2, y: -b.size * 0.2)
            }
            .position(x: b.x, y: b.y)
        }
    }
}

// MARK: - Game View
struct GameView: View {
    var vm: GameViewModel
    let size: CGSize
    @Environment(StoreManager.self) private var storeManager
    @Environment(AdManager.self) private var adManager
    @State private var showingPurchaseSheet = false

    var body: some View {
        ZStack {
            // Obstacles
            ForEach(vm.obstacles) { obs in
                ObstacleView(obstacle: obs, screenHeight: size.height, gapHeight: vm.difficulty.gapHeight)
            }

            // Pearls
            ForEach(vm.obstacles.filter { $0.hasPearl && !$0.pearlCollected }) { obs in
                PearlView(pearlType: obs.pearlType)
                    .position(x: obs.x, y: obs.gapY)
            }

            // Trail bubbles behind mermaid
            ForEach(vm.trailBubbles) { tb in
                Circle()
                    .fill(Color.white.opacity(tb.opacity * 0.7))
                    .frame(width: tb.size, height: tb.size)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(tb.opacity * 0.4), lineWidth: 1)
                    )
                    .position(x: tb.x, y: tb.y)
            }

            // Mermaid
            PixelMermaidView(velocity: vm.mermaidVelocity, swimFrame: vm.swimFrame, flapStrength: vm.flapStrength)
                .scaleEffect(x: 1.0 + vm.flapStrength * 0.05, y: 1.0 - vm.flapStrength * 0.03)
                .rotationEffect(.degrees(vm.mermaidAngle * 0.35))
                .position(x: size.width * 0.25, y: vm.mermaidY)
                .animation(.interpolatingSpring(stiffness: 120, damping: 10), value: vm.mermaidAngle)

            // HUD
            HUDView(score: vm.score, pearls: vm.pearls)

            // Flash on death
            if vm.flashRed {
                Color.red.opacity(0.35).ignoresSafeArea()
            }

            // Death screen
            if vm.state == .dead {
                DeathView(score: vm.score, best: vm.bestScore, pearls: vm.pearls,
                          difficulty: vm.difficulty, isAdsRemoved: storeManager.isAdsRemoved) {
                    vm.startGame(width: size.width, height: size.height, difficulty: vm.difficulty)
                } onMenu: {
                    vm.state = .menu
                } onRemoveAds: {
                    showingPurchaseSheet = true
                }
                .onAppear {
                    if !storeManager.isAdsRemoved {
                        adManager.recordDeath()
                        if adManager.shouldShowInterstitial() {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                adManager.showingInterstitial = true
                            }
                        }
                    }
                }
                .sheet(isPresented: $showingPurchaseSheet) {
                    RemoveAdsSheet(storeManager: storeManager)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { vm.flap() }
    }
}

// MARK: - 8-Bit Pixel Mermaid (in-game, side view swimming right)
// Chibi 8-bit style matching menu mermaid. Side profile facing right.
// Big head, cute dot eyes, blue hair trailing back, green tail with fin.
struct PixelMermaidView: View {
    var velocity: CGFloat = 0
    var swimFrame: Int = 0
    var flapStrength: CGFloat = 0
    let px: CGFloat = 3.0

    // Color key:
    // . = empty, H = hair, h = hair dark, * = hair highlight
    // S = skin, s = skin shadow, P = pupil (eye dot)
    // L = lips, B = shell, b = shell dark, c = shell light
    // T = tail, t = tail dark, l = tail light, F = fin, f = fin edge
    // A = arm (skin color)

    // Side-view swimming sprite: 22 wide x 14 tall
    // Head on right, long flowing hair trails left, tail on left with fin
    static let spriteBase: [[Character]] = [
        //  0         1         2
        //  0123456789012345678901
        list("......h*HHHHh........."),  // 0  hair flowing far back
        list("....h*HHHHHHHHh......."),  // 1  hair stream
        list("...h*HHHHHHHHHHh......"),  // 2  hair full trail
        list("....hHHHHHHHHHHH......"),  // 3  hair + head top
        list(".....hhHHSSSSSSh......"),  // 4  hair + forehead
        list("......hHSSPSSSS......."),  // 5  hair + eye (P=pupil)
        list(".......hSSSSSLS......."),  // 6  cheek + mouth
        list("......hhsSSSSsh......."),  // 7  hair behind + jaw
        list("...lTTTTtsBcSSs......."),  // 8  tail + shell + upper body
        list(".fFFTTTTTtBcSSA......."),  // 9  fin + tail + shell + body + arm
        list(".fFFTTTTTtssSsA......."),  // 10 fin + tail + lower body + arm
        list("...lTTTTtsssSs........"),  // 11 tail taper + waist
        list(".....tTTt............."),  // 12 tail tip
        list("......tt.............."),  // 13 tail end
    ]

    static func list(_ s: String) -> [Character] { Array(s) }

    func colorFor(_ ch: Character) -> Color? {
        switch ch {
        case "H": return Palette.hair
        case "h": return Palette.hairDark
        case "*": return Palette.hairHighlight
        case "S": return Palette.skin
        case "s": return Palette.skinShadow
        case "P": return Palette.eyePupil
        case "L": return Palette.lips
        case "B": return Palette.shell
        case "b": return Palette.shellDark
        case "c": return Palette.shellLight
        case "T": return Palette.tail
        case "t": return Palette.tailDark
        case "l": return Palette.tailLight
        case "F": return Palette.fin
        case "f": return Palette.finEdge
        case "A": return Palette.skin
        default: return nil
        }
    }

    var body: some View {
        let tailWag: [CGFloat] = [0, -1.5, 0, 1.5]
        let tw = tailWag[swimFrame % 4]
        let normalizedVel = min(max(velocity / 300, -1), 1)
        let hairDrift = normalizedVel * 1.5

        Canvas { context, size in
            let p = px
            let rows = Self.spriteBase
            let spriteH = rows.count
            let spriteW = rows.first?.count ?? 0
            let originX = (size.width - CGFloat(spriteW) * p) / 2
            let originY = (size.height - CGFloat(spriteH) * p) / 2

            for row in 0..<spriteH {
                for col in 0..<rows[row].count {
                    let ch = rows[row][col]
                    guard let color = colorFor(ch) else { continue }

                    var yOff: CGFloat = 0

                    // Tail wag: pixels left of column 10 get progressive vertical offset
                    if col < 10 {
                        let factor = CGFloat(10 - col) / 10.0
                        yOff += tw * factor
                    }

                    // Fin gets extra wag
                    if ch == "F" || ch == "f" {
                        yOff += tw * 0.6
                    }

                    // Scale shimmer: alternate tail highlight per frame
                    if ch == "l" && swimFrame % 2 != 0 {
                        yOff += 0.5
                    }

                    // Hair drift from velocity (top rows drift more)
                    if (ch == "H" || ch == "h" || ch == "*") && row < 4 {
                        let factor = CGFloat(4 - row) / 4.0
                        yOff += hairDrift * factor
                    }

                    // Arm stroke animation on flap
                    if ch == "A" {
                        yOff -= flapStrength * 2.0
                    }

                    let x = originX + CGFloat(col) * p
                    let y = originY + CGFloat(row) * p + yOff * p
                    let rect = CGRect(x: x, y: y, width: p, height: p)
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: 22 * px, height: 14 * px)
    }
}

// MARK: - Menu Mermaid (upright portrait pose for title screen)
// Detailed 8-bit pixel mermaid in the classic cross-stitch / game asset style.
// Dark outlines, big anime eyes, long blue hair, purple shell top, green scaled tail.
struct MenuMermaidView: View {
    @State private var swimFrame: Int = 0
    let px: CGFloat = 2.5

    // 22 wide x 34 tall — detailed front-facing mermaid
    // Color key:
    // . = empty (transparent)
    // O = dark outline (near-black)
    // H = hair, h = hair dark, * = hair highlight
    // S = skin, s = skin shadow, K = skin highlight (forehead/cheek shine)
    // W = eye white, I = iris, P = pupil, G = eye shine (white dot)
    // R = rosy cheek blush
    // L = lips, M = lips dark
    // B = shell, b = shell dark, c = shell light
    // T = tail, t = tail dark, l = tail light
    // F = fin, f = fin edge
    // A = arm skin, a = arm shadow
    static let spriteRows: [[Character]] = [
        list("........OhhO........."),  // 0  hair tip top
        list("......OhHHHHhO......."),  // 1  hair crown
        list(".....OhH*HHH*HhO....."),  // 2  hair wide
        list("....OhHHHHHHHHHhO...."),  // 3  hair full
        list("...OhHHHHHHHHHHHhO..."),  // 4  hair widest
        list("...OHHH*HHHHHH*HHO..."),  // 5  hair + highlight
        list("..OhHHHOOOOOOOHHHhO.."),  // 6  hair framing face top
        list("..OHHHOSSSSSSSSOHHHO."),  // 7  hair + forehead
        list("..OHHOSSSSSSSSSOHhO.."),  // 8  brow area
        list("..OHhOSOOOSOOOSOHhO.."),  // 9  eyelashes (dark top)
        list("..OHhOWGIWSWGIWOHhO.."),  // 10 eyes upper (white+shine+iris)
        list("..OHhOWIPWSWIPWOHhO.."),  // 11 eyes mid (iris+pupil)
        list("..OHhOSWWWSWWWSOHhO.."),  // 12 eyes bottom (white round)
        list("..OHhOSSRSSSRSSOHhO.."),  // 13 cheeks (R=blush)
        list("..OHHhOSSLLLSSOhHHO.."),  // 12 mouth
        list("..OhHHhOSSSSSSOhHhO.."),  // 13 chin + hair sides
        list("...OhHHhOSSSSOhHhO..."),  // 14 jaw + hair
        list("...OhHHhOsSSOhHHhO..."),  // 15 neck + hair drape
        list("..OhHHhOABcBcAOhHhO.."),  // 16 shoulders + shell top
        list("..OhHhOAsBbbBsAOhHO.."),  // 17 shell lower + arms
        list("..OhHhOaSSSSSSaOhHO.."),  // 18 upper torso + arms
        list("...OhHOaSSSSSSaOHO..."),  // 19 torso mid + hair
        list("...OhHhOSSSSSSOhHO..."),  // 20 waist + hair drape
        list("....OhhOlTTTTlOhhO..."),  // 21 tail start + hair tips
        list(".....OOOTtTlTTOOO...."),  // 22 tail upper scales
        list("......OlTTTTTlO......"),  // 23 tail scales
        list("......OTtTlTtTO......"),  // 24 tail pattern
        list("......OlTTTTTlO......"),  // 25 tail scales
        list(".......OTtTtTO......."),  // 26 tail narrowing
        list(".......OlTTTlO......."),  // 27 tail narrow
        list("........OTtTO........"),  // 28 tail taper
        list("........OlTlO........"),  // 29 tail thin
        list(".......OfFFFfO......."),  // 30 fin top spread
        list("......OfFFFFFfO......"),  // 31 fin wide
        list(".....OfFF..FFfO......"),  // 32 fin split
        list("....Off....ffO......."),  // 33 fin tips
    ]

    static func list(_ s: String) -> [Character] { Array(s) }

    func colorFor(_ ch: Character) -> Color? {
        switch ch {
        case "O": return Color(red: 0.10, green: 0.08, blue: 0.18)  // dark outline
        case "H": return Palette.hair
        case "h": return Palette.hairDark
        case "*": return Palette.hairHighlight
        case "S": return Palette.skin
        case "s": return Palette.skinShadow
        case "K": return Color(red: 1.0, green: 0.92, blue: 0.82)  // skin highlight
        case "W": return Palette.eyeWhite
        case "I": return Palette.eyeIris
        case "P": return Palette.eyePupil
        case "G": return .white  // eye shine
        case "R": return Color(red: 1.0, green: 0.60, blue: 0.60)  // rosy blush
        case "L": return Palette.lips
        case "M": return Color(red: 0.80, green: 0.30, blue: 0.35)  // lip shadow
        case "B": return Palette.shell
        case "b": return Palette.shellDark
        case "c": return Palette.shellLight
        case "T": return Palette.tail
        case "t": return Palette.tailDark
        case "l": return Palette.tailLight
        case "F": return Palette.fin
        case "f": return Palette.finEdge
        case "A": return Palette.skin  // arm
        case "a": return Palette.skinShadow  // arm shadow
        default: return nil
        }
    }

    var body: some View {
        let wiggle: CGFloat = swimFrame % 2 == 0 ? 1 : -1

        Canvas { context, size in
            let p = px
            let rows = Self.spriteRows
            let spriteH = rows.count
            let spriteW = rows.first?.count ?? 0
            let originX = (size.width - CGFloat(spriteW) * p) / 2
            let originY = (size.height - CGFloat(spriteH) * p) / 2

            for row in 0..<spriteH {
                for col in 0..<rows[row].count {
                    let ch = rows[row][col]
                    guard let color = colorFor(ch) else { continue }

                    var xOff: CGFloat = 0

                    // Gentle hair sway at top
                    if (ch == "H" || ch == "h" || ch == "*") && row < 6 {
                        xOff += wiggle * CGFloat(6 - row) * 0.12
                    }

                    // Fin wag at bottom
                    if ch == "F" || ch == "f" {
                        xOff += wiggle * CGFloat(row - 29) * 0.25
                    }

                    let x = originX + CGFloat(col) * p + xOff * p
                    let y = originY + CGFloat(row) * p
                    let rect = CGRect(x: x, y: y, width: p, height: p)
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: 21 * px, height: 36 * px)
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { _ in
                swimFrame += 1
            }
        }
    }
}


// MARK: - Obstacle View
struct ObstacleView: View {
    let obstacle: Obstacle
    let screenHeight: CGFloat
    let gapHeight: CGFloat

    var body: some View {
        let gapTop = obstacle.gapY - gapHeight / 2
        let gapBottom = obstacle.gapY + gapHeight / 2
        let topHeight = gapTop
        let bottomHeight = screenHeight - gapBottom
        let colors = obstacle.colorScheme

        ZStack {
            CoralObstacle(height: topHeight, flipped: true, colors: colors)
                .position(x: obstacle.x, y: topHeight / 2)

            CoralObstacle(height: bottomHeight, flipped: false, colors: colors)
                .position(x: obstacle.x, y: gapBottom + bottomHeight / 2)
        }
    }
}

// MARK: - Coral Obstacle (pixel-art seaweed/coral style)
// Organic branching coral with rounded blobby segments, side fronds, and rounded tips.
struct CoralObstacle: View {
    let height: CGFloat
    let flipped: Bool
    var colors: CoralColors = CoralColors.schemes[0]

    private var seed: UInt64 {
        UInt64(abs(height * 100)) &+ (flipped ? 7 : 13)
    }

    var body: some View {
        let px: CGFloat = 3  // pixel size for 8-bit look

        Canvas { context, size in
            let h = max(height, 0)
            guard h > 0 else { return }
            let midX = size.width / 2
            var s = seed

            func rand() -> CGFloat {
                s = s &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat((s >> 33) % 1000) / 1000.0
            }

            // Helper: draw a rounded blob (ellipse made of pixel rects)
            func drawBlob(cx: CGFloat, cy: CGFloat, rw: CGFloat, rh: CGFloat, color: Color) {
                let steps = Int(rw / px) + 1
                for ix in -steps...steps {
                    let xOff = CGFloat(ix) * px
                    let xNorm = xOff / rw
                    guard abs(xNorm) <= 1 else { continue }
                    let ySpan = rh * sqrt(1 - xNorm * xNorm)
                    let ySteps = Int(ySpan / px)
                    for iy in -ySteps...ySteps {
                        let rect = CGRect(x: cx + xOff - px / 2,
                                          y: cy + CGFloat(iy) * px - px / 2,
                                          width: px, height: px)
                        context.fill(Path(rect), with: .color(color))
                    }
                }
            }

            // Helper: draw blob with outline + highlight
            func drawCoralBlob(cx: CGFloat, cy: CGFloat, rw: CGFloat, rh: CGFloat) {
                // Dark outline (slightly larger)
                drawBlob(cx: cx, cy: cy, rw: rw + px, rh: rh + px, color: colors.dark)
                // Main fill
                drawBlob(cx: cx, cy: cy, rw: rw, rh: rh, color: colors.mid)
                // Highlight on upper-left
                drawBlob(cx: cx - rw * 0.2, cy: cy - rh * 0.2, rw: rw * 0.5, rh: rh * 0.5, color: colors.bright)
            }

            // --- Main trunk: stack of blobby segments ---
            let segH: CGFloat = 18  // height of each blob segment
            let segCount = max(Int(h / segH) + 1, 2)

            for i in 0..<segCount {
                let progress = CGFloat(i) / CGFloat(segCount)  // 0=base, 1=tip
                let y: CGFloat
                if flipped {
                    y = h - CGFloat(i) * segH - segH / 2
                } else {
                    y = CGFloat(i) * segH + segH / 2
                }
                guard y > -segH && y < h + segH else { continue }

                // Trunk width: wider at base, narrower at tip
                let baseRW: CGFloat = 22 - progress * 8
                let wave = sin(progress * .pi * 2.5 + CGFloat(seed % 80) * 0.1) * 3
                let rw = baseRW + wave
                let rh = segH / 2 + 2

                // Slight horizontal sway
                let drift = sin(progress * .pi * 3 + CGFloat(seed % 60) * 0.15) * 5
                let cx = midX + drift

                drawCoralBlob(cx: cx, cy: y, rw: rw, rh: rh)

                // --- Side branches/fronds at some segments ---
                if i > 0 && i % 2 == Int(seed % 2) {
                    let side: CGFloat = (i % 4 < 2) ? -1 : 1
                    let branchLen = 2 + Int(rand() * 2)  // 2-3 blobs per branch

                    for j in 0..<branchLen {
                        let jf = CGFloat(j + 1)
                        let bRW = rw * 0.45 * (1 - jf * 0.2)
                        let bRH = rh * 0.6
                        let bx = cx + side * (rw + jf * bRW * 1.2)
                        let by: CGFloat
                        if flipped {
                            by = y + jf * bRH * 0.6 * (flipped ? -1 : 1)
                        } else {
                            by = y - jf * bRH * 0.6
                        }
                        drawCoralBlob(cx: bx, cy: by, rw: max(bRW, 4), rh: max(bRH, 4))
                    }
                }
            }

            // --- Rounded polyp tips at the opening ---
            let tipDir: CGFloat = flipped ? -1 : 1
            let tipBaseY = flipped ? 0 : h
            let tipCount = 3 + Int(rand() * 2)
            for t in 0..<tipCount {
                let tx = midX + (CGFloat(t) - CGFloat(tipCount) / 2) * 12 + rand() * 4
                let ty = tipBaseY - tipDir * (8 + rand() * 14)
                let tr: CGFloat = 5 + rand() * 5
                drawCoralBlob(cx: tx, cy: ty, rw: tr, rh: tr)
                // Smaller tip on top
                drawCoralBlob(cx: tx + rand() * 3 - 1.5, cy: ty - tipDir * tr * 0.8, rw: tr * 0.6, rh: tr * 0.6)
            }
        }
        .frame(width: 80, height: max(height, 0))
    }
}



// MARK: - Pearl View (8-bit style)
struct PearlView: View {
    @State private var glow = false
    @State private var bob = false
    @State private var sparkle = false
    let size = GameConfig.pearlSize
    var pearlType: PearlType = .normal

    private var glowColor: Color {
        switch pearlType {
        case .normal: return Palette.pearlShine
        case .gold: return Color(red: 1.0, green: 0.85, blue: 0.2)
        case .diamond: return Color(red: 0.7, green: 0.85, blue: 1.0)
        }
    }
    private var bodyColors: [Color] {
        switch pearlType {
        case .normal:
            return [Palette.pearlWhite, Palette.pearlShine, Palette.pearlShadow]
        case .gold:
            return [Color(red: 1.0, green: 0.95, blue: 0.5),
                    Color(red: 1.0, green: 0.78, blue: 0.15),
                    Color(red: 0.80, green: 0.55, blue: 0.05)]
        case .diamond:
            return [Color(red: 0.9, green: 0.95, blue: 1.0),
                    Color(red: 0.6, green: 0.8, blue: 1.0),
                    Color(red: 0.35, green: 0.5, blue: 0.85)]
        }
    }
    private var borderColor: Color {
        switch pearlType {
        case .normal: return Palette.pearlShadow
        case .gold: return Color(red: 0.80, green: 0.55, blue: 0.05)
        case .diamond: return Color(red: 0.35, green: 0.5, blue: 0.85)
        }
    }

    var body: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(glowColor.opacity(glow ? 0.5 : 0.15))
                .frame(width: size + 12, height: size + 12)
                .animation(.easeInOut(duration: 0.8).repeatForever(), value: glow)

            // Pearl body
            Circle()
                .fill(
                    RadialGradient(
                        colors: bodyColors,
                        center: UnitPoint(x: 0.35, y: 0.3),
                        startRadius: 1,
                        endRadius: size / 2
                    )
                )
                .frame(width: size, height: size)

            // Pixel highlight
            Rectangle()
                .fill(Color.white)
                .frame(width: 4, height: 4)
                .offset(x: -size * 0.18, y: -size * 0.18)

            // Pixel border
            Circle()
                .stroke(borderColor.opacity(0.6), lineWidth: 1.5)
                .frame(width: size, height: size)

            // Diamond sparkle cross
            if pearlType == .diamond {
                Rectangle()
                    .fill(Color.white.opacity(sparkle ? 0.9 : 0.2))
                    .frame(width: 2, height: size + 8)
                Rectangle()
                    .fill(Color.white.opacity(sparkle ? 0.9 : 0.2))
                    .frame(width: size + 8, height: 2)
                Rectangle()
                    .fill(Color.white.opacity(sparkle ? 0.7 : 0.1))
                    .frame(width: 2, height: size + 4)
                    .rotationEffect(.degrees(45))
                Rectangle()
                    .fill(Color.white.opacity(sparkle ? 0.7 : 0.1))
                    .frame(width: size + 4, height: 2)
                    .rotationEffect(.degrees(45))
            }
        }
        .offset(y: bob ? -3 : 3)
        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bob)
        .onAppear {
            glow = true
            bob = true
            if pearlType == .diamond { sparkle = true }
        }
        .animation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true), value: sparkle)
    }
}

struct PearlLegendItem: View {
    let label: String
    let pearlType: PearlType

    private var colors: [Color] {
        switch pearlType {
        case .normal:
            return [Palette.pearlWhite, Palette.pearlShadow]
        case .gold:
            return [Color(red: 1.0, green: 0.95, blue: 0.5), Color(red: 0.80, green: 0.55, blue: 0.05)]
        case .diamond:
            return [Color(red: 0.9, green: 0.95, blue: 1.0), Color(red: 0.35, green: 0.5, blue: 0.85)]
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Circle()
                .fill(RadialGradient(colors: colors,
                                     center: UnitPoint(x: 0.35, y: 0.35),
                                     startRadius: 1, endRadius: 7))
                .frame(width: 14, height: 14)
                .overlay(
                    Circle().stroke(colors.last!.opacity(0.6), lineWidth: 1)
                )
            Text(label)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
        }
    }
}

// MARK: - HUD (8-bit style)
struct HUDView: View {
    let score: Int
    let pearls: Int

    var body: some View {
        VStack {
            HStack(alignment: .top) {
                // Pearl counter
                HStack(spacing: 6) {
                    // Mini pixel pearl
                    ZStack {
                        Circle()
                            .fill(RadialGradient(colors: [Palette.pearlWhite, Palette.pearlShadow],
                                                 center: UnitPoint(x: 0.35, y: 0.35),
                                                 startRadius: 1, endRadius: 8))
                            .frame(width: 18, height: 18)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 3, height: 3)
                            .offset(x: -3, y: -3)
                    }
                    Text("\(pearls)")
                        .font(.system(size: 20, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black.opacity(0.35))
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Palette.tailLight.opacity(0.4), lineWidth: 1)
                        )
                )

                Spacer()

                // Score
                Text("\(score)")
                    .font(.system(size: 48, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 3, y: 3)
                    .shadow(color: Palette.oceanTop.opacity(0.5), radius: 8)

                Spacer()
                Color.clear.frame(width: 80)
            }
            .padding(.top, 56)
            .padding(.horizontal, 20)
            Spacer()
        }
    }
}

// MARK: - Menu View
struct MenuView: View {
    let onStart: () -> Void
    let storeManager: StoreManager
    @State private var bounce = false
    @State private var shimmer = false
    @State private var soundOff = SoundManager.shared.isMuted
    @State private var showingPurchaseSheet = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            // Pixel mermaid preview (upright portrait)
            MenuMermaidView()
                .scaleEffect(2.5)
                .scaleEffect(bounce ? 1.05 : 0.95)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: bounce)
                .frame(height: 160)
                .offset(y: -30)

            // Title — centered between mermaid and instructions
            VStack(spacing: 6) {
                Text("SWIM")
                    .font(.system(size: 46, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 3, y: 3)
                    .shadow(color: Palette.tailLight.opacity(0.6), radius: 12)

                Text("OR SINK")
                    .font(.system(size: 38, weight: .heavy, design: .monospaced))
                    .foregroundColor(Palette.tailLight)
                    .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
                    .shadow(color: Palette.tailLight.opacity(0.4), radius: 8)
            }

            // Instructions
            VStack(spacing: 10) {
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Palette.tailLight)
                        .frame(width: 6, height: 6)
                    Text("TAP to swim")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.9))
                }
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Palette.shell)
                        .frame(width: 6, height: 6)
                    Text("Dodge hazards")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                HStack(spacing: 8) {
                    Rectangle()
                        .fill(Palette.pearlWhite)
                        .frame(width: 6, height: 6)
                    Text("Collect pearls")
                        .font(.system(size: 14, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }

                // Pearl values legend
                HStack(spacing: 16) {
                    PearlLegendItem(label: "+5", pearlType: .normal)
                    PearlLegendItem(label: "+10", pearlType: .gold)
                    PearlLegendItem(label: "+20", pearlType: .diamond)
                }
            }

            // Start Button
            Button(action: onStart) {
                Text("DIVE IN")
                    .font(.system(size: 22, weight: .heavy, design: .monospaced))
                    .foregroundColor(Palette.oceanFloor)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 14)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Palette.tailLight)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            // Pixel border
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Palette.tailDark, lineWidth: 2)
                        }
                    )
                    .shadow(color: Palette.tailDark.opacity(0.6), radius: 0, x: 3, y: 3)
            }

            Button {
                SoundManager.shared.isMuted.toggle()
                soundOff = SoundManager.shared.isMuted
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: soundOff ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 14, weight: .bold))
                    Text(soundOff ? "SOUND OFF" : "SOUND ON")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)

            if !storeManager.isAdsRemoved {
                Button {
                    showingPurchaseSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14, weight: .bold))
                        Text("REMOVE ADS")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.8))
                }
                .buttonStyle(.plain)
                .sheet(isPresented: $showingPurchaseSheet) {
                    RemoveAdsSheet(storeManager: storeManager)
                }
            }

            Spacer()
        }
        .onAppear { bounce = true }
    }
}

// MARK: - Death View
struct DeathView: View {
    let score: Int
    let best: Int
    let pearls: Int
    let difficulty: Difficulty
    let isAdsRemoved: Bool
    let onRestart: () -> Void
    let onMenu: () -> Void
    let onRemoveAds: () -> Void
    @State private var appear = false
    @State private var isSharing = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            VStack(spacing: 8) {
                // Pixel skull
                Text("GAME OVER")
                    .font(.system(size: 36, weight: .heavy, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.6), radius: 0, x: 3, y: 3)
                    .shadow(color: Color.red.opacity(0.3), radius: 12)
            }
            .scaleEffect(appear ? 1 : 0.5)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: appear)

            // Stats panel
            VStack(spacing: 14) {
                PixelStatRow(label: "SCORE", value: "\(score)", color: .white)
                PixelStatRow(label: "BEST", value: "\(best)", color: Color(red: 1.0, green: 0.85, blue: 0.2))
                PixelStatRow(label: "PEARLS", value: "\(pearls)", color: Palette.pearlShine)
                PixelStatRow(label: "MODE", value: difficulty.label, color: Color(red: 0.6, green: 0.8, blue: 1.0))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Palette.tailLight.opacity(0.3), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 36)
            .opacity(appear ? 1 : 0)
            .animation(.easeIn.delay(0.2), value: appear)

            Spacer()

            Button(action: onRestart) {
                Text("TRY AGAIN")
                    .font(.system(size: 20, weight: .heavy, design: .monospaced))
                    .foregroundColor(Palette.oceanFloor)
                    .padding(.horizontal, 44)
                    .padding(.vertical, 14)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Palette.tailLight)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(Palette.tailDark, lineWidth: 2)
                        }
                    )
                    .shadow(color: Palette.tailDark.opacity(0.6), radius: 0, x: 3, y: 3)
            }
            .opacity(appear ? 1 : 0)
            .animation(.easeIn.delay(0.35), value: appear)

            Button(action: onMenu) {
                Text("MAIN MENU")
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(.white.opacity(0.35), lineWidth: 1.5)
                    )
            }
            .opacity(appear ? 1 : 0)
            .animation(.easeIn.delay(0.45), value: appear)

            Button {
                guard !isSharing else { return }
                isSharing = true
                let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene
                let renderer = ImageRenderer(content: ScoreboardImage(score: score, best: best, pearls: pearls, difficulty: difficulty))
                renderer.scale = windowScene?.screen.scale ?? 3.0
                if let image = renderer.uiImage {
                    let text = "I scored \(score) points on \(difficulty.label) in Swim or Sink! Can you beat me?\nDownload: https://apps.apple.com/app/id6760926427"
                    let ac = UIActivityViewController(activityItems: [image, text], applicationActivities: nil)
                    ac.completionWithItemsHandler = { _, _, _, _ in isSharing = false }
                    if let root = windowScene?.windows.first?.rootViewController {
                        root.present(ac, animated: true)
                    } else {
                        isSharing = false
                    }
                } else {
                    isSharing = false
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .bold))
                    Text("SHARE SCORE")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                }
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 32)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(.white.opacity(0.35), lineWidth: 1.5)
                )
            }
            .opacity(appear ? 1 : 0)
            .animation(.easeIn.delay(0.50), value: appear)

            if !isAdsRemoved {
                Button(action: onRemoveAds) {
                    Text("Remove Ads")
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.2).opacity(0.6))
                }
                .buttonStyle(.plain)
                .opacity(appear ? 1 : 0)
                .animation(.easeIn.delay(0.55), value: appear)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.55))
        .onAppear { appear = true }
    }
}

struct PixelStatRow: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .monospaced))
                .foregroundColor(color)
                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)
        }
    }
}

// MARK: - Shareable Scoreboard Image
struct ScoreboardImage: View {
    let score: Int
    let best: Int
    let pearls: Int
    let difficulty: Difficulty

    var body: some View {
        VStack(spacing: 16) {
            Text("SWIM OR SINK")
                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: Palette.tailLight.opacity(0.6), radius: 8)

            VStack(spacing: 10) {
                PixelStatRow(label: "SCORE", value: "\(score)", color: .white)
                PixelStatRow(label: "BEST", value: "\(best)", color: Color(red: 1.0, green: 0.85, blue: 0.2))
                PixelStatRow(label: "PEARLS", value: "\(pearls)", color: Palette.pearlShine)
                PixelStatRow(label: "MODE", value: difficulty.label, color: Color(red: 0.6, green: 0.8, blue: 1.0))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 4)
                            .stroke(Palette.tailLight.opacity(0.3), lineWidth: 1)
                    )
            )

            Text("Can you beat me?")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(32)
        .frame(width: 320)
        .background(
            LinearGradient(
                colors: [Palette.oceanTop, Palette.oceanDeep, Palette.oceanFloor],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}



// MARK: - Remove Ads Sheet
struct RemoveAdsSheet: View {
    let storeManager: StoreManager
    @Environment(\.dismiss) private var dismiss
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("REMOVE ADS")
                .font(.system(size: 28, weight: .heavy, design: .monospaced))
                .foregroundColor(.white)
                .shadow(color: .black.opacity(0.5), radius: 0, x: 2, y: 2)

            VStack(spacing: 8) {
                Text("Enjoy Swim or Sink")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
                Text("completely ad-free!")
                    .font(.system(size: 16, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.8))
            }

            Spacer()

            if let product = storeManager.product {
                Button {
                    Task {
                        do {
                            try await storeManager.purchase()
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    }
                } label: {
                    Text("BUY \(product.displayPrice)")
                        .font(.system(size: 20, weight: .heavy, design: .monospaced))
                        .foregroundColor(Palette.oceanFloor)
                        .padding(.horizontal, 44)
                        .padding(.vertical, 14)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(red: 1.0, green: 0.85, blue: 0.2))
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.3), Color.clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color(red: 0.8, green: 0.6, blue: 0.0), lineWidth: 2)
                            }
                        )
                        .shadow(color: Color(red: 0.8, green: 0.6, blue: 0.0).opacity(0.6), radius: 0, x: 3, y: 3)
                }
                .disabled(storeManager.purchaseState == .purchasing)
            } else {
                ProgressView()
                    .tint(.white)
            }

            Button {
                Task { await storeManager.restorePurchases() }
            } label: {
                Text("RESTORE PURCHASE")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            .buttonStyle(.plain)

            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                colors: [Palette.oceanTop, Palette.oceanDeep],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .onChange(of: storeManager.isAdsRemoved) { _, newValue in
            if newValue { dismiss() }
        }
        .alert("Purchase Failed", isPresented: $showError) {
            Button("OK") {}
        } message: {
            Text(errorMessage)
        }
    }
}

// MARK: - Preview
#Preview {
    ContentView()
}
