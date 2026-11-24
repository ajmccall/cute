import SwiftUI

/// The app's root destination: the board, whose turn or result, and the game actions.
struct BoardScreen: View {
    let game: LocalGame

    @State private var confirmation: Confirmation?

    private enum Confirmation: Identifiable {
        case resign, agreeDraw, replace
        var id: Self { self }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if game.hasUnsavedChange {
                    WriteFailureBanner(retry: game.retrySave)
                }
                // While the saved game is unread there is no board or turn to show.
                if game.couldNotReadSavedGame {
                    ReadFailureView(retry: game.retryRead, newGame: { confirmation = .replace })
                } else {
                    playSurface
                }
            }
            .padding(.vertical)
        }
        .scrollBounceBehavior(.basedOnSize)
        .alert(confirmationTitle, isPresented: isConfirming, presenting: confirmation) { confirmation in
            Button("Confirm", role: confirmation == .agreeDraw ? nil : .destructive) { perform(confirmation) }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Promote pawn", isPresented: isChoosingPromotion) {
            ForEach(PieceKind.promotionChoices, id: \.self) { kind in
                Button(BoardText.promotionChoice(kind)) { game.choosePromotion(kind) }
            }
            Button("Cancel", role: .cancel) { game.cancelPromotion() }
        }
        .onChange(of: BoardText.status(of: game)) { _, status in
            AccessibilityNotification.Announcement(status).post()
        }
    }

    private var playSurface: some View {
        VStack(spacing: 16) {
            Text(BoardText.status(of: game))
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("status")
            BoardView(game: game)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { actions }
                VStack(spacing: 12) { actions }
            }
            .gameActionStyle()
            .padding(.horizontal)
        }
    }

    /// New game is always offered; resigning and agreeing a draw only during play.
    @ViewBuilder
    private var actions: some View {
        Button("New game") {
            if game.newGameNeedsConfirmation {
                confirmation = .replace
            } else {
                game.newGame()
            }
        }
        if game.canResignOrAgreeDraw {
            Button("Resign") { confirmation = .resign }
            Button("Agree draw") { confirmation = .agreeDraw }
        }
    }

    private var confirmationTitle: String {
        switch confirmation {
        case .resign: BoardText.confirmResign(game.position.sideToMove)
        case .agreeDraw: String(localized: "Do both players agree to a draw?")
        case .replace: String(localized: "Replace this game?")
        case nil: ""
        }
    }

    private var isConfirming: Binding<Bool> {
        Binding(get: { confirmation != nil }, set: { if !$0 { confirmation = nil } })
    }

    /// Dismissing the choice any way other than picking a piece cancels the promotion.
    private var isChoosingPromotion: Binding<Bool> {
        Binding(get: { game.isChoosingPromotion }, set: { if !$0 { game.cancelPromotion() } })
    }

    private func perform(_ confirmation: Confirmation) {
        switch confirmation {
        case .resign: game.resign()
        case .agreeDraw: game.agreeDraw()
        case .replace: game.newGame()
        }
    }
}

private struct WriteFailureBanner: View {
    let retry: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Label("Change not saved.", systemImage: "exclamationmark.triangle.fill")
                .symbolRenderingMode(.multicolor)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityIdentifier("writeFailureNotice")
            Button("Retry", action: retry)
                .gameActionStyle()
                .accessibilityHint(Text("Saves the change again"))
                .accessibilityIdentifier("retrySave")
        }
        .font(.body)
        .padding()
        .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))
        .padding(.horizontal)
    }
}

/// Retry, or replace the saved game that couldn't be read once the players confirm.
private struct ReadFailureView: View {
    let retry: () -> Void
    let newGame: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn’t open the saved game.", systemImage: "exclamationmark.triangle")
                .accessibilityIdentifier("readFailureNotice")
        } actions: {
            Button("Retry", action: retry)
                .gameActionStyle()
                .accessibilityHint(Text("Opens the saved game again"))
                .accessibilityIdentifier("retryRead")
            Button("New game", action: newGame)
                .gameActionStyle()
        }
    }
}

private extension View {
    /// Stock bordered buttons in the primary colour, whose labels keep full text contrast.
    func gameActionStyle() -> some View {
        buttonStyle(.bordered).tint(.primary)
    }
}
