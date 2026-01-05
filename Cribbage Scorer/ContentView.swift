//
//  ContentView.swift
//  Cribbage Scorer
//
//  Created by Robert Bye on 02/01/2026.
//

import SwiftUI
import Combine

// MARK: - Game View Model
class GameViewModel: ObservableObject {
    @Published var player1MainScore: Int {
        didSet {
            UserDefaults.standard.set(player1MainScore, forKey: "player1MainScore")
        }
    }

    @Published var player1FloatingScore: Int {
        didSet {
            UserDefaults.standard.set(player1FloatingScore, forKey: "player1FloatingScore")
        }
    }

    @Published var player2MainScore: Int {
        didSet {
            UserDefaults.standard.set(player2MainScore, forKey: "player2MainScore")
        }
    }

    @Published var player2FloatingScore: Int {
        didSet {
            UserDefaults.standard.set(player2FloatingScore, forKey: "player2FloatingScore")
        }
    }

    @Published var showWinnerModal = false
    @Published var showConfetti = false
    @Published var winner: String?

    let winningScore = 121

    init() {
        // Load persisted scores
        self.player1MainScore = UserDefaults.standard.integer(forKey: "player1MainScore")
        self.player1FloatingScore = UserDefaults.standard.integer(forKey: "player1FloatingScore")
        self.player2MainScore = UserDefaults.standard.integer(forKey: "player2MainScore")
        self.player2FloatingScore = UserDefaults.standard.integer(forKey: "player2FloatingScore")
    }

    func addToFloatingScore(player: Int, value: Int) {
        if player == 1 {
            player1FloatingScore += value
        } else {
            player2FloatingScore += value
        }
    }

    func commitFloatingScore(player: Int) {
        if player == 1 {
            player1MainScore += player1FloatingScore
            player1FloatingScore = 0
            checkForWinner(playerNumber: 1)
        } else {
            player2MainScore += player2FloatingScore
            player2FloatingScore = 0
            checkForWinner(playerNumber: 2)
        }
    }

    func checkForWinner(playerNumber: Int) {
        let score = playerNumber == 1 ? player1MainScore : player2MainScore
        if score >= winningScore {
            winner = "Player \(playerNumber)"
            showConfetti = true
            showWinnerModal = true
        }
    }

    func resetGame() {
        player1MainScore = 0
        player1FloatingScore = 0
        player2MainScore = 0
        player2FloatingScore = 0
        showWinnerModal = false
        showConfetti = false
        winner = nil
    }
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showResetConfirmation = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Player (Player 1) - Rotated 180°
                PlayerSection(
                    mainScore: viewModel.player1MainScore,
                    floatingScore: viewModel.player1FloatingScore,
                    backgroundColor: .black,
                    foregroundColor: .white,
                    isRotated: true,
                    onScoreButtonTap: { value in
                        viewModel.addToFloatingScore(player: 1, value: value)
                    },
                    onFloatingScoreTap: {
                        viewModel.commitFloatingScore(player: 1)
                    },
                    onLongPress: {
                        showResetConfirmation = true
                    }
                )

                // Bottom Player (Player 2)
                PlayerSection(
                    mainScore: viewModel.player2MainScore,
                    floatingScore: viewModel.player2FloatingScore,
                    backgroundColor: .white,
                    foregroundColor: .black,
                    isRotated: false,
                    onScoreButtonTap: { value in
                        viewModel.addToFloatingScore(player: 2, value: value)
                    },
                    onFloatingScoreTap: {
                        viewModel.commitFloatingScore(player: 2)
                    },
                    onLongPress: {
                        showResetConfirmation = true
                    }
                )
            }
            .ignoresSafeArea()

            // Confetti overlay
            if viewModel.showConfetti {
                ConfettiView()
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Crazy flashing New Game button
            if viewModel.showConfetti {
                CrazyNewGameButton {
                    viewModel.resetGame()
                }
            }
        }
        .ignoresSafeArea()
        .alert("Reset Game?", isPresented: $showResetConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetGame()
            }
        } message: {
            Text("This will reset both players' scores to 0.")
        }
    }
}

// MARK: - Player Section
struct PlayerSection: View {
    let mainScore: Int
    let floatingScore: Int
    let backgroundColor: Color
    let foregroundColor: Color
    let isRotated: Bool
    let onScoreButtonTap: (Int) -> Void
    let onFloatingScoreTap: () -> Void
    let onLongPress: () -> Void

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    // Main Score
                    Text("\(mainScore)")
                        .font(.system(size: 120, weight: .bold))
                        .foregroundColor(foregroundColor)
                        .onLongPressGesture {
                            onLongPress()
                        }
                        .padding(.bottom, 8)

                    // Floating Score
                    Text("\(floatingScore)")
                        .font(.system(size: 45, weight: .medium))
                        .foregroundColor(foregroundColor.opacity(0.6))
                        .onTapGesture {
                            onFloatingScoreTap()
                        }
                        .onLongPressGesture {
                            onLongPress()
                        }

                    Spacer()

                    // Score Buttons at bottom edge
                    HStack(spacing: 16) {
                        ScoreButton(value: "+1", color: foregroundColor, backgroundColor: backgroundColor) {
                            onScoreButtonTap(1)
                        }
                        ScoreButton(value: "+2", color: foregroundColor, backgroundColor: backgroundColor) {
                            onScoreButtonTap(2)
                        }
                        ScoreButton(value: "+3", color: foregroundColor, backgroundColor: backgroundColor) {
                            onScoreButtonTap(3)
                        }
                        ScoreButton(value: "+4", color: foregroundColor, backgroundColor: backgroundColor) {
                            onScoreButtonTap(4)
                        }
                        ScoreButton(value: "-1", color: foregroundColor, backgroundColor: backgroundColor) {
                            onScoreButtonTap(-1)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .rotationEffect(.degrees(isRotated ? 180 : 0))
    }
}

// MARK: - Score Button
struct ScoreButton: View {
    let value: String
    let color: Color
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(backgroundColor == .black ? Color.white : Color.black)
                    .frame(width: 50, height: 50)

                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(backgroundColor == .black ? Color.black : Color.white)
            }
        }
    }
}

// MARK: - DISCO INFERNO 🪩✨
struct ConfettiView: View {
    @State private var discoBallRotation: Double = 0
    @State private var discoBallScale: CGFloat = 0.1
    @State private var spotlightRotation: Double = 0
    @State private var strobeOpacity: Double = 0
    @State private var rainbowHue: Double = 0
    @State private var emojis: [DiscoEmoji] = []
    @State private var winnerTextScale: CGFloat = 0.1
    @State private var winnerTextOffset: CGFloat = -100

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Rainbow background alternation
                LinearGradient(
                    colors: [
                        Color(hue: rainbowHue, saturation: 0.6, brightness: 1),
                        Color(hue: rainbowHue + 0.3, saturation: 0.6, brightness: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Spotlights
                ForEach(0..<3, id: \.self) { index in
                    SpotlightView(rotation: spotlightRotation + Double(index) * 120)
                }

                // Emojis exploding from corners
                ForEach(emojis) { emoji in
                    DiscoEmojiView(emoji: emoji)
                }

                // 3D Rotating Disco Ball with Lasers
                ZStack {
                    // Laser beams shooting from disco ball
                    ForEach(0..<8, id: \.self) { index in
                        LaserBeamView(
                            rotation: discoBallRotation * 2 + Double(index) * 45,
                            color: [Color.red, Color.green, Color.blue, Color.purple, Color.cyan, Color.yellow].randomElement()!
                        )
                    }

                    // Disco ball shine/glow
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.white.opacity(0.8), .clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 100
                            )
                        )
                        .frame(width: 200, height: 200)
                        .blur(radius: 30)

                    // Actual disco ball emoji!
                    Text("🪩")
                        .font(.system(size: 120))
                        .shadow(color: .white, radius: 20)
                        .rotation3DEffect(.degrees(discoBallRotation), axis: (x: 0, y: 1, z: 0))
                        .rotation3DEffect(.degrees(discoBallRotation * 0.5), axis: (x: 1, y: 0, z: 0))
                }
                .scaleEffect(discoBallScale)
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2 - 50)

                // Winner text
                Text("WINNER!")
                    .font(.system(size: 60, weight: .black))
                    .foregroundColor(.white)
                    .shadow(color: .black.opacity(0.5), radius: 10)
                    .shadow(color: Color(hue: rainbowHue, saturation: 1, brightness: 1), radius: 20)
                    .scaleEffect(winnerTextScale)
                    .offset(y: winnerTextOffset)
                    .position(x: geometry.size.width / 2, y: geometry.size.height / 2 + 100)

                // Strobe effect
                Rectangle()
                    .fill(.white)
                    .opacity(strobeOpacity)
                    .ignoresSafeArea()
            }
            .onAppear {
                startDiscoInferno(in: geometry.size)
            }
        }
    }

    func startDiscoInferno(in size: CGSize) {
        // Disco ball entrance
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            discoBallScale = 1.0
        }

        // Continuous disco ball rotation
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            discoBallRotation = 360
        }

        // Spotlight sweep
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            spotlightRotation = 360
        }

        // Rainbow background cycling
        withAnimation(.linear(duration: 3.0).repeatForever(autoreverses: false)) {
            rainbowHue = 1.0
        }

        // Strobe effect
        startStrobing()

        // Emoji explosions from corners
        generateEmojis(in: size)

        // Winner text bounce
        withAnimation(.spring(response: 0.6, dampingFraction: 0.5).delay(0.3)) {
            winnerTextScale = 1.0
            winnerTextOffset = 0
        }

        // Haptic feedback
        startDiscoHaptics()
    }

    func startStrobing() {
        for i in 0..<30 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.2) {
                withAnimation(.easeIn(duration: 0.05)) {
                    strobeOpacity = 0.4
                }
                withAnimation(.easeOut(duration: 0.15)) {
                    strobeOpacity = 0
                }
            }
        }
    }

    func generateEmojis(in size: CGSize) {
        let emojiSymbols = ["🎉", "🏆", "💯", "🔥", "👑", "⭐️"]
        let corners: [(x: CGFloat, y: CGFloat)] = [
            (0, 0), // Top-left
            (size.width, 0), // Top-right
            (0, size.height), // Bottom-left
            (size.width, size.height) // Bottom-right
        ]

        for i in 0..<40 {
            let corner = corners[i % corners.count]
            let randomEmoji = emojiSymbols.randomElement()!
            let angle = Double.random(in: 0...(360)) * .pi / 180
            let distance = CGFloat.random(in: 100...400)

            emojis.append(DiscoEmoji(
                id: i,
                symbol: randomEmoji,
                startX: corner.x,
                startY: corner.y,
                targetX: corner.x + cos(angle) * distance,
                targetY: corner.y + sin(angle) * distance,
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.8...2.0),
                delay: Double(i) * 0.05
            ))
        }
    }

    func startDiscoHaptics() {
        let generator = UIImpactFeedbackGenerator(style: .medium)

        // Rhythmic disco beat haptics
        for i in 0..<16 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.25) {
                generator.impactOccurred(intensity: i % 2 == 0 ? 1.0 : 0.5)
            }
        }
    }
}

// MARK: - Laser Beam
struct LaserBeamView: View {
    let rotation: Double
    let color: Color

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        color.opacity(0.8),
                        color.opacity(0.4),
                        color.opacity(0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 4, height: 400)
            .blur(radius: 3)
            .rotationEffect(.degrees(rotation))
            .blendMode(.plusLighter)
    }
}

// MARK: - Spotlight
struct SpotlightView: View {
    let rotation: Double

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.yellow.opacity(0.6), Color.yellow.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: 100, height: 600)
            .blur(radius: 30)
            .rotationEffect(.degrees(rotation))
            .blendMode(.screen)
    }
}

// MARK: - Disco Emoji
struct DiscoEmoji: Identifiable {
    let id: Int
    let symbol: String
    let startX: CGFloat
    let startY: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let rotation: Double
    let scale: CGFloat
    let delay: Double
}

struct DiscoEmojiView: View {
    let emoji: DiscoEmoji
    @State private var position: CGPoint
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0

    init(emoji: DiscoEmoji) {
        self.emoji = emoji
        _position = State(initialValue: CGPoint(x: emoji.startX, y: emoji.startY))
    }

    var body: some View {
        Text(emoji.symbol)
            .font(.system(size: 50))
            .scaleEffect(emoji.scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(position)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0).delay(emoji.delay)) {
                    position = CGPoint(x: emoji.targetX, y: emoji.targetY)
                    rotation = emoji.rotation
                    opacity = 1.0
                }

                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false).delay(emoji.delay + 1.0)) {
                    rotation += 360
                }

                withAnimation(.easeIn(duration: 1.0).delay(emoji.delay + 3.0)) {
                    opacity = 0
                }
            }
    }
}

// MARK: - Crazy New Game Button
struct CrazyNewGameButton: View {
    let action: () -> Void
    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0
    @State private var glowIntensity: Double = 0
    @State private var rainbowHue: Double = 0

    var body: some View {
        Button(action: action) {
            Text("NEW GAME")
                .font(.system(size: 36, weight: .black))
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 20)
                .background(
                    ZStack {
                        // Rainbow animated background
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hue: rainbowHue, saturation: 1, brightness: 1),
                                        Color(hue: rainbowHue + 0.3, saturation: 1, brightness: 1)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        // Pulsing glow
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white, lineWidth: 4)
                            .blur(radius: glowIntensity)
                    }
                )
                .shadow(color: Color(hue: rainbowHue, saturation: 1, brightness: 1), radius: 20)
                .scaleEffect(scale)
                .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        }
        .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2 + 200)
        .onAppear {
            startCrazyAnimations()
        }
    }

    func startCrazyAnimations() {
        // Pulsing scale
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            scale = 1.2
        }

        // Rainbow color cycle
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rainbowHue = 1.0
        }

        // Glow pulse
        withAnimation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true)) {
            glowIntensity = 10
        }

        // Subtle 3D rotation
        withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }
}

#Preview {
    ContentView()
}
