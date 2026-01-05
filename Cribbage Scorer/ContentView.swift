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
        .alert(viewModel.winner ?? "Winner!", isPresented: $viewModel.showWinnerModal) {
            Button("New Game") {
                viewModel.resetGame()
            }
        } message: {
            Text("\(viewModel.winner ?? "Someone") wins with \(viewModel.winner == "Player 1" ? viewModel.player1MainScore : viewModel.player2MainScore) points!")
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

// MARK: - Confetti View
struct ConfettiView: View {
    @State private var confettiPieces: [ConfettiPiece] = []

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ForEach(confettiPieces) { piece in
                    ConfettiPieceView(piece: piece)
                }
            }
            .onAppear {
                generateConfetti(in: geometry.size)
            }
        }
    }

    func generateConfetti(in size: CGSize) {
        confettiPieces = (0..<80).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: 0...size.width),
                y: CGFloat.random(in: -100...0),
                rotation: Double.random(in: 0...360),
                scale: CGFloat.random(in: 0.5...1.5),
                color: [Color.red, Color.blue, Color.green, Color.yellow, Color.orange, Color.purple].randomElement()!,
                fallDuration: Double.random(in: 2...3.5)
            )
        }
    }
}

struct ConfettiPiece: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let scale: CGFloat
    let color: Color
    let fallDuration: Double
}

struct ConfettiPieceView: View {
    let piece: ConfettiPiece
    @State private var yOffset: CGFloat = 0
    @State private var rotation: Double = 0

    var body: some View {
        Rectangle()
            .fill(piece.color)
            .frame(width: 10, height: 10)
            .scaleEffect(piece.scale)
            .rotationEffect(.degrees(rotation))
            .position(x: piece.x, y: piece.y + yOffset)
            .onAppear {
                withAnimation(
                    .linear(duration: piece.fallDuration)
                    .repeatForever(autoreverses: false)
                ) {
                    yOffset = UIScreen.main.bounds.height + 100
                }

                withAnimation(
                    .linear(duration: 1)
                    .repeatForever(autoreverses: false)
                ) {
                    rotation = 360
                }
            }
    }
}

#Preview {
    ContentView()
}
