import SwiftUI

/// The app's root destination: the board, whose turn or result, and the game actions.
struct BoardScreen: View {
    let game: LocalGame

    @State private var confirmation: Confirmation?

    private enum Confirmation: Identifiable {
        case resign, agreeDraw, replace, offerDouble
        var id: Self { self }
        /// Ending or replacing a game is destructive; agreeing a draw and offering a double aren't.
        var confirmRole: ButtonRole? {
            switch self {
            case .resign, .replace: .destructive
            case .agreeDraw, .offerDouble: nil
            }
        }
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
            Button("Confirm", role: confirmation.confirmRole) { perform(confirmation) }
            Button("Cancel", role: .cancel) {}
        }
        .alert("Promote pawn", isPresented: isChoosingPromotion) {
            ForEach(PieceKind.promotionChoices, id: \.self) { kind in
                Button(BoardText.promotionChoice(kind)) { game.choosePromotion(kind) }
            }
            Button("Cancel", role: .cancel) { game.cancelPromotion() }
        }
        .onChange(of: BoardText.announcement(of: game)) { _, announcement in
            AccessibilityNotification.Announcement(announcement).post()
        }
    }

    private var playSurface: some View {
        VStack(spacing: 16) {
            VStack(spacing: 4) {
                Text(BoardText.status(of: game))
                    .font(.title2.weight(.semibold))
                    .accessibilityAddTraits(.isHeader)
                    .accessibilityIdentifier("status")
                if let award = game.award {
                    Text(BoardText.award(award, spoken: false))
                        .font(.body)
                        .accessibilityLabel(BoardText.award(award, spoken: true))
                        .accessibilityIdentifier("award")
                }
            }
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal)
            if game.isInPlay, !game.isAwaitingDoubleResponse, let stake = game.stake {
                StakeView(stake: stake, doubleRight: BoardText.doubleRight(of: game))
            }
            BoardView(game: game)
            if game.isAwaitingDoubleResponse, let stake = game.stake {
                DoubleResponseView(
                    stake: stake, offerer: game.position.sideToMove,
                    take: game.takeDouble, decline: game.declineDouble)
            } else {
                ActionRow { actions }
                    .padding(.horizontal)
            }
        }
    }

    /// New game is offered except while an offer waits for its answer; resigning, agreeing a draw
    /// and offering a double only during play, and offering only for a side to move entitled to it.
    @ViewBuilder
    private var actions: some View {
        if game.canStartNewGame {
            Button("New game") {
                if game.newGameNeedsConfirmation {
                    confirmation = .replace
                } else {
                    game.newGame()
                }
            }
        }
        if game.canResignOrAgreeDraw {
            Button("Resign") { confirmation = .resign }
            Button("Agree draw") { confirmation = .agreeDraw }
            Button("Offer double") { confirmation = .offerDouble }
                .disabled(!game.canOfferDouble)
        }
    }

    private var confirmationTitle: String {
        switch confirmation {
        case .resign: BoardText.confirmResign(game.position.sideToMove)
        case .agreeDraw: String(localized: "Do both players agree to a draw?")
        case .replace: String(localized: "Replace this game?")
        case .offerDouble: BoardText.confirmOffer(stake: game.stake ?? 1)
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
        case .offerDouble: game.offerDouble()
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
        .panelStyle()
    }
}

/// The points in play and who may offer the next double, shown throughout play whoever's turn it is.
private struct StakeView: View {
    let stake: Int
    let doubleRight: String

    var body: some View {
        VStack(spacing: 2) {
            Text(BoardText.stake(stake))
                .font(.headline)
                .accessibilityIdentifier("stake")
            Text(doubleRight)
                .font(.body)
                .accessibilityIdentifier("doubleRight")
        }
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal)
    }
}

/// The responder's choice, beside the board: the stake as it stands, what taking and declining each mean
/// in points, and the two actions. The status above the board names the responder; the panel doesn't
/// (product owner, 2026-11-24, on #17). Nothing else on the board can be done until one is chosen.
private struct DoubleResponseView: View {
    let stake: Int
    let offerer: PieceColor
    let take: () -> Void
    let decline: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(BoardText.stake(stake))
                    .font(.headline)
                    .accessibilityIdentifier("stake")
                Text(BoardText.takeEffect(stake: stake))
                    .accessibilityIdentifier("takeEffect")
                Text(BoardText.declineEffect(offerer: offerer, stake: stake))
                    .accessibilityIdentifier("declineEffect")
            }
            .font(.body)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            ActionRow {
                Button("Take", action: take)
                Button("Decline", action: decline)
            }
        }
        .panelStyle()
    }
}

/// Game actions side by side, or stacked when they don't fit across, as stock bordered buttons.
private struct ActionRow<Actions: View>: View {
    @ViewBuilder let actions: Actions

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) { actions }
            VStack(spacing: 12) { actions }
        }
        .gameActionStyle()
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

    /// A rounded panel on the secondary background, inset from the screen's edges.
    func panelStyle() -> some View {
        padding()
            .background(Color(.secondarySystemBackground), in: .rect(cornerRadius: 12))
            .padding(.horizontal)
    }
}
