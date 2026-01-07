//
//  ContentView.swift
//  Cribbage Scorer
//
//  Created by Robert Bye on 02/01/2026.
//

import SwiftUI
import Combine

// MARK: - Game Model
struct Game: Identifiable, Codable {
    let id: UUID
    var name: String
    var player1MainScore: Int
    var player2MainScore: Int
    var player1GamesWon: Int
    var player2GamesWon: Int

    init(id: UUID = UUID(), name: String = "Player 1 vs Player 2", player1MainScore: Int = 0, player2MainScore: Int = 0, player1GamesWon: Int = 0, player2GamesWon: Int = 0) {
        self.id = id
        self.name = name
        self.player1MainScore = player1MainScore
        self.player2MainScore = player2MainScore
        self.player1GamesWon = player1GamesWon
        self.player2GamesWon = player2GamesWon
    }
}

// MARK: - Game View Model
class GameViewModel: ObservableObject {
    @Published var games: [Game] = [] {
        didSet {
            saveGames()
        }
    }
    @Published var activeGameID: UUID? {
        didSet {
            UserDefaults.standard.set(activeGameID?.uuidString, forKey: "activeGameID")
            saveActiveGameState()
        }
    }

    @Published var player1FloatingScore: Int = 0
    @Published var player2FloatingScore: Int = 0

    @Published var player1GamesWon: Int {
        didSet {
            UserDefaults.standard.set(player1GamesWon, forKey: "player1GamesWon")
        }
    }

    @Published var player2GamesWon: Int {
        didSet {
            UserDefaults.standard.set(player2GamesWon, forKey: "player2GamesWon")
        }
    }

    @Published var showWinnerModal = false
    @Published var showConfetti = false
    @Published var showSkunk = false
    @Published var winner: String?
    @Published var skunkedPlayer: Int? // 1 or 2, the player who got skunked

    let winningScore = 121
    let skunkDifference = 30

    // Computed properties for active game
    var player1MainScore: Int {
        get { activeGame?.player1MainScore ?? 0 }
        set {
            if let index = games.firstIndex(where: { $0.id == activeGameID }) {
                games[index].player1MainScore = newValue
            }
        }
    }

    var player2MainScore: Int {
        get { activeGame?.player2MainScore ?? 0 }
        set {
            if let index = games.firstIndex(where: { $0.id == activeGameID }) {
                games[index].player2MainScore = newValue
            }
        }
    }

    var player1GamesWon: Int {
        get { activeGame?.player1GamesWon ?? 0 }
        set {
            if let index = games.firstIndex(where: { $0.id == activeGameID }) {
                games[index].player1GamesWon = newValue
            }
        }
    }

    var player2GamesWon: Int {
        get { activeGame?.player2GamesWon ?? 0 }
        set {
            if let index = games.firstIndex(where: { $0.id == activeGameID }) {
                games[index].player2GamesWon = newValue
            }
        }
    }

    var activeGame: Game? {
        games.first(where: { $0.id == activeGameID })
    }

    init() {
        loadGames()
        if games.isEmpty {
            let defaultGame = Game()
            games.append(defaultGame)
            activeGameID = defaultGame.id
        } else if let savedActiveID = UserDefaults.standard.string(forKey: "activeGameID"),
                  let uuid = UUID(uuidString: savedActiveID) {
            activeGameID = uuid
        } else {
            activeGameID = games.first?.id
        }
    }

    private func saveGames() {
        if let encoded = try? JSONEncoder().encode(games) {
            UserDefaults.standard.set(encoded, forKey: "games")
        }
    }

    private func loadGames() {
        if let data = UserDefaults.standard.data(forKey: "games"),
           let decoded = try? JSONDecoder().decode([Game].self, from: data) {
            games = decoded
        }
    }

    private func saveActiveGameState() {
        // Save floating scores for active game
        if activeGameID != nil {
            UserDefaults.standard.set(player1FloatingScore, forKey: "player1FloatingScore")
            UserDefaults.standard.set(player2FloatingScore, forKey: "player2FloatingScore")
        }
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
        let winnerScore = playerNumber == 1 ? player1MainScore : player2MainScore
        let loserScore = playerNumber == 1 ? player2MainScore : player1MainScore

        if winnerScore >= winningScore {
            winner = "Player \(playerNumber)"

            // Increment games won for the winner
            if playerNumber == 1 {
                player1GamesWon += 1
            } else {
                player2GamesWon += 1
            }

            // Check if opponent got SKUNKED! (loser has 90 or less when winner hits 121)
            if winnerScore - loserScore > skunkDifference {
                showSkunk = true
                showConfetti = false
                // Track which player got skunked (the loser)
                skunkedPlayer = playerNumber == 1 ? 2 : 1
            } else {
                showSkunk = false
                showConfetti = true
                skunkedPlayer = nil
            }

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
        showSkunk = false
        winner = nil
        skunkedPlayer = nil
    }

    func resetGamesWon() {
        player1GamesWon = 0
        player2GamesWon = 0
    }

    // Game management methods
    func createNewGame(name: String = "Player 1 vs Player 2") {
        let newGame = Game(name: name)
        games.append(newGame)
        switchToGame(id: newGame.id)
    }

    func deleteGame(id: UUID) {
        // Don't delete if it's the only game
        guard games.count > 1 else { return }

        games.removeAll { $0.id == id }

        // If we deleted the active game, switch to first available
        if id == activeGameID {
            activeGameID = games.first?.id
            player1FloatingScore = 0
            player2FloatingScore = 0
        }
    }

    func renameGame(id: UUID, newName: String) {
        if let index = games.firstIndex(where: { $0.id == id }) {
            games[index].name = newName
        }
    }

    func updateGame(id: UUID, newName: String, player1GamesWon: Int, player2GamesWon: Int) {
        if let index = games.firstIndex(where: { $0.id == id }) {
            games[index].name = newName
            games[index].player1GamesWon = player1GamesWon
            games[index].player2GamesWon = player2GamesWon
        }
    }

    func switchToGame(id: UUID) {
        // Save current floating scores before switching
        saveActiveGameState()

        activeGameID = id

        // Load floating scores for new game or reset them
        if let savedP1 = UserDefaults.standard.object(forKey: "player1FloatingScore") as? Int,
           let savedP2 = UserDefaults.standard.object(forKey: "player2FloatingScore") as? Int {
            player1FloatingScore = savedP1
            player2FloatingScore = savedP2
        } else {
            player1FloatingScore = 0
            player2FloatingScore = 0
        }

        // Reset celebration states
        showWinnerModal = false
        showConfetti = false
        showSkunk = false
        winner = nil
        skunkedPlayer = nil
    }
}

// MARK: - Content View
struct ContentView: View {
    @StateObject private var viewModel = GameViewModel()
    @State private var showResetConfirmation = false
    @State private var showResetGamesWonConfirmation = false
    @State private var showGameList = false

    // Danger color for when player is 30+ points behind (#EE0000)
    let dangerColor = Color(red: 0xEE / 255.0, green: 0x00 / 255.0, blue: 0x00 / 255.0)

    // Check if players are in danger of being skunked
    var player1InDanger: Bool {
        viewModel.player2MainScore - viewModel.player1MainScore >= 30
    }

    var player2InDanger: Bool {
        viewModel.player1MainScore - viewModel.player2MainScore >= 30
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                // Top Player (Player 1) - Rotated 180°
                PlayerSection(
                    mainScore: viewModel.player1MainScore,
                    floatingScore: viewModel.player1FloatingScore,
                    gamesWon: viewModel.player1GamesWon,
                    backgroundColor: .black,
                    foregroundColor: player1InDanger ? dangerColor : .white,
                    isRotated: true,
                    onScoreButtonTap: { value in
                        viewModel.addToFloatingScore(player: 1, value: value)
                    },
                    onFloatingScoreTap: {
                        viewModel.commitFloatingScore(player: 1)
                    },
                    onLongPress: {
                        showResetConfirmation = true
                    },
                    onGamesWonTap: {
                        showGameList = true
                    },
                    onGamesWonLongPress: {
                        showResetGamesWonConfirmation = true
                    }
                )

                // Progress bars at the middle divider
                VStack(spacing: 0) {
                    // Top player's white progress bar
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(player1InDanger ? dangerColor : Color.white)
                                .frame(width: geometry.size.width * CGFloat(min(viewModel.player1MainScore, 121)) / 121.0)
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(height: 10)
                    .background(Color.black)

                    // Bottom player's black progress bar
                    GeometryReader { geometry in
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(player2InDanger ? dangerColor : Color.black)
                                .frame(width: geometry.size.width * CGFloat(min(viewModel.player2MainScore, 121)) / 121.0)
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(height: 10)
                    .background(Color.white)
                }
                .frame(height: 20)

                // Bottom Player (Player 2)
                PlayerSection(
                    mainScore: viewModel.player2MainScore,
                    floatingScore: viewModel.player2FloatingScore,
                    gamesWon: viewModel.player2GamesWon,
                    backgroundColor: .white,
                    foregroundColor: player2InDanger ? dangerColor : .black,
                    isRotated: false,
                    onScoreButtonTap: { value in
                        viewModel.addToFloatingScore(player: 2, value: value)
                    },
                    onFloatingScoreTap: {
                        viewModel.commitFloatingScore(player: 2)
                    },
                    onLongPress: {
                        showResetConfirmation = true
                    },
                    onGamesWonTap: {
                        showGameList = true
                    },
                    onGamesWonLongPress: {
                        showResetGamesWonConfirmation = true
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

            // SKUNK overlay
            if viewModel.showSkunk {
                SkunkView(skunkedPlayer: viewModel.skunkedPlayer ?? 2)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }

            // Crazy flashing New Game button
            if viewModel.showConfetti || viewModel.showSkunk {
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
        .alert("Reset Games Won?", isPresented: $showResetGamesWonConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                viewModel.resetGamesWon()
            }
        } message: {
            Text("This will reset the games won tally to 0 for both players. This cannot be undone.")
        }
        .sheet(isPresented: $showGameList) {
            GameListSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Player Section
struct PlayerSection: View {
    let mainScore: Int
    let floatingScore: Int
    let gamesWon: Int
    let backgroundColor: Color
    let foregroundColor: Color
    let isRotated: Bool
    let onScoreButtonTap: (Int) -> Void
    let onFloatingScoreTap: () -> Void
    let onLongPress: () -> Void
    let onGamesWonTap: () -> Void
    let onGamesWonLongPress: () -> Void

    // Adjustable margin from middle divider
    let gamesWonVerticalMargin: CGFloat = 30
    let gamesWonHorizontalMargin: CGFloat = 40

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

                // Games Won - positioned symmetrically from middle divider on right side
                GeometryReader { geo in
                    Text("\(gamesWon)")
                        .font(.system(size: 45, weight: .medium))
                        .foregroundColor(foregroundColor.opacity(0.6))
                        .rotationEffect(.degrees(isRotated ? 90 : -90))
                        .onTapGesture {
                            onGamesWonTap()
                        }
                        .onLongPressGesture {
                            onGamesWonLongPress()
                        }
                        .position(
                            x: isRotated ? gamesWonHorizontalMargin : geo.size.width - gamesWonHorizontalMargin,
                            y: gamesWonVerticalMargin
                        )
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

// MARK: - SKUNK ATTACK 🦨
struct SkunkView: View {
    let skunkedPlayer: Int // 1 = top player, 2 = bottom player
    @State private var skunks: [SpinningSkunk] = []
    @State private var rainbowHue: Double = 0
    @State private var skunkTextScale: CGFloat = 0.1
    @State private var skunkTextRotation: Double = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Rainbow background pulsing
                LinearGradient(
                    colors: [
                        Color(hue: rainbowHue, saturation: 0.8, brightness: 1),
                        Color(hue: rainbowHue + 0.5, saturation: 0.8, brightness: 1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                // Spinning skunks everywhere!
                ForEach(skunks) { skunk in
                    SpinningSkunkView(skunk: skunk)
                }

                // "YOU GOT SKUNKED!" text
                VStack(spacing: 10) {
                    Text("YOU GOT")
                        .font(.system(size: 50, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 10)

                    Text("SKUNKED!")
                        .font(.system(size: 70, weight: .black))
                        .foregroundColor(.white)
                        .shadow(color: .black, radius: 10)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                }
                .scaleEffect(skunkTextScale)
                .rotationEffect(.degrees(skunkTextRotation))
                .position(x: geometry.size.width / 2, y: geometry.size.height / 2)
            }
            .rotationEffect(.degrees(skunkedPlayer == 1 ? 180 : 0))
            .onAppear {
                startSkunkAttack(in: geometry.size)
            }
        }
    }

    func startSkunkAttack(in size: CGSize) {
        // Generate tons of spinning skunks
        for i in 0..<60 {
            let startX = CGFloat.random(in: 0...size.width)
            let startY = i % 2 == 0 ? CGFloat.random(in: -200...0) : CGFloat.random(in: size.height...(size.height + 200))

            skunks.append(SpinningSkunk(
                id: i,
                x: startX,
                y: startY,
                targetX: CGFloat.random(in: 0...size.width),
                targetY: CGFloat.random(in: 0...size.height),
                scale: CGFloat.random(in: 0.8...2.5),
                delay: Double(i) * 0.03
            ))
        }

        // Text explosion
        withAnimation(.spring(response: 0.6, dampingFraction: 0.4)) {
            skunkTextScale = 1.0
        }

        // Text wobble
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
            skunkTextRotation = 5
        }

        // Rainbow background
        withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
            rainbowHue = 1.0
        }

        // Haptics
        startSkunkHaptics()
    }

    func startSkunkHaptics() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)

        // Intense haptic pattern
        for i in 0..<25 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                generator.impactOccurred(intensity: 1.0)
            }
        }
    }
}

struct SpinningSkunk: Identifiable {
    let id: Int
    let x: CGFloat
    let y: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    let scale: CGFloat
    let delay: Double
}

struct SpinningSkunkView: View {
    let skunk: SpinningSkunk
    @State private var position: CGPoint
    @State private var rotation: Double = 0
    @State private var opacity: Double = 0

    init(skunk: SpinningSkunk) {
        self.skunk = skunk
        _position = State(initialValue: CGPoint(x: skunk.x, y: skunk.y))
    }

    var body: some View {
        Text("🦨")
            .font(.system(size: 60))
            .scaleEffect(skunk.scale)
            .rotationEffect(.degrees(rotation))
            .opacity(opacity)
            .position(position)
            .onAppear {
                // Fly to target
                withAnimation(.easeOut(duration: 1.2).delay(skunk.delay)) {
                    position = CGPoint(x: skunk.targetX, y: skunk.targetY)
                    opacity = 1.0
                }

                // Spin like crazy (2D only)
                withAnimation(.linear(duration: 0.8).repeatForever(autoreverses: false).delay(skunk.delay)) {
                    rotation = 360
                }

                // Fade out eventually
                withAnimation(.easeIn(duration: 1.0).delay(skunk.delay + 4.0)) {
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

// MARK: - Game List Sheet
struct GameListSheet: View {
    @ObservedObject var viewModel: GameViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showNewGameAlert = false
    @State private var newGameName = ""
    @State private var gameToDelete: UUID?
    @State private var showDeleteConfirmation = false
    @State private var gameToRename: UUID?
    @State private var showRenameAlert = false
    @State private var renameGameName = ""
    @State private var renamePlayer1GamesWon = ""
    @State private var renamePlayer2GamesWon = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(viewModel.games) { game in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(game.name)
                                .font(.system(size: 17, weight: .medium))
                            Text("\(game.player1GamesWon)-\(game.player2GamesWon)")
                                .font(.system(size: 15))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Active game indicator
                        if game.id == viewModel.activeGameID {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.switchToGame(id: game.id)
                        dismiss()
                    }
                    .onLongPressGesture {
                        gameToRename = game.id
                        renameGameName = game.name
                        renamePlayer1GamesWon = String(game.player1GamesWon)
                        renamePlayer2GamesWon = String(game.player2GamesWon)
                        showRenameAlert = true
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            gameToDelete = game.id
                            showDeleteConfirmation = true
                        } label: {
                            Image(systemName: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Games")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.system(size: 17))
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showNewGameAlert = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 17, weight: .medium))
                    }
                }
            }
            .alert("New Game", isPresented: $showNewGameAlert) {
                TextField("Game Name", text: $newGameName)
                Button("Cancel", role: .cancel) {
                    newGameName = ""
                }
                Button("Create") {
                    let name = newGameName.isEmpty ? "Player 1 vs Player 2" : newGameName
                    viewModel.createNewGame(name: name)
                    newGameName = ""
                    dismiss()
                }
            } message: {
                Text("Enter a name for the new game (e.g., \"Robert vs Natalie\")")
            }
            .alert("Delete Game?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {
                    gameToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let id = gameToDelete {
                        viewModel.deleteGame(id: id)
                    }
                    gameToDelete = nil
                }
            } message: {
                Text("This will permanently delete this game and all its scores. This cannot be undone.")
            }
            .alert("Edit Game", isPresented: $showRenameAlert) {
                TextField("Game Name", text: $renameGameName)
                TextField("Player 1 Games Won", text: $renamePlayer1GamesWon)
                    .keyboardType(.numberPad)
                TextField("Player 2 Games Won", text: $renamePlayer2GamesWon)
                    .keyboardType(.numberPad)
                Button("Cancel", role: .cancel) {
                    gameToRename = nil
                    renameGameName = ""
                    renamePlayer1GamesWon = ""
                    renamePlayer2GamesWon = ""
                }
                Button("Save") {
                    if let id = gameToRename, !renameGameName.isEmpty {
                        let p1GamesWon = Int(renamePlayer1GamesWon) ?? 0
                        let p2GamesWon = Int(renamePlayer2GamesWon) ?? 0
                        viewModel.updateGame(id: id, newName: renameGameName, player1GamesWon: p1GamesWon, player2GamesWon: p2GamesWon)
                    }
                    gameToRename = nil
                    renameGameName = ""
                    renamePlayer1GamesWon = ""
                    renamePlayer2GamesWon = ""
                }
            } message: {
                Text("Edit game name and total games won")
            }
        }
        .presentationDetents([.large])
    }
}

#Preview {
    ContentView()
}
