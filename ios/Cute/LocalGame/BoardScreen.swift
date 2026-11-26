import SwiftUI

/// The app's root destination: the match score, the board, whose turn or result, and the game actions.
struct BoardScreen: View {
    let game: LocalGame

    @State private var confirmation: Confirmation?

    private enum Confirmation: Identifiable {
        case resign, agreeDraw, replace
        var id: Self { self }
        /// Ending or replacing a game is destructive; agreeing a draw isn't.
        var confirmRole: ButtonRole? {
            switch self {
            case .resign, .replace: .destructive
            case .agreeDraw: nil
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
                    ReadFailureView(retry: game.retryRead, newMatch: { confirmation = .replace })
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
            MatchScoreView(score: game.score)
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
                if game.isMatchOver {
                    Text(BoardText.matchResult(game.score, spoken: false))
                        .font(.headline)
                        .accessibilityLabel(BoardText.matchResult(game.score, spoken: true))
                        .accessibilityIdentifier("matchResult")
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
                    stake: stake, offerer: game.position.sideToMove, endsMatch: game.declineEndsMatch,
                    take: game.takeDouble, decline: game.declineDouble)
            } else {
                ActionRow { actions }
                    .padding(.horizontal)
            }
        }
    }

    /// Next game is offered once a game has finished short of the target, at once without confirmation.
    /// New match is offered except while an offer waits for its answer, and is the only action once the match
    /// is over; resigning, agreeing a draw and offering a double only during play, and offering only for a
    /// side to move entitled to it. Offer double makes the binding offer on one tap, without confirmation.
    @ViewBuilder
    private var actions: some View {
        if game.canStartNextGame {
            Button("Next game", action: game.nextGame)
        }
        if game.canStartNewMatch {
            Button("New match") {
                if game.newMatchNeedsConfirmation {
                    confirmation = .replace
                } else {
                    game.newMatch()
                }
            }
        }
        if game.canResignOrAgreeDraw {
            Button("Resign") { confirmation = .resign }
            Button("Agree draw") { confirmation = .agreeDraw }
            Button("Offer double", action: game.offerDouble)
                .disabled(!game.canOfferDouble)
        }
    }

    private var confirmationTitle: String {
        switch confirmation {
        case .resign: BoardText.confirmResign(game.position.sideToMove)
        case .agreeDraw: String(localized: "Do both players agree to a draw?")
        case .replace: String(localized: "Replace this match?")
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
        case .replace: game.newMatch()
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

/// White's and Black's totals and the target, in every state of the board, with halves spoken in words.
private struct MatchScoreView: View {
    let score: MatchScore

    var body: some View {
        Text(BoardText.matchScore(score, spoken: false))
            .font(.subheadline.weight(.medium))
            .monospacedDigit()
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal)
            .accessibilityLabel(BoardText.matchScore(score, spoken: true))
            .accessibilityIdentifier("matchScore")
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
    let endsMatch: Bool
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
                Text(BoardText.declineEffect(offerer: offerer, stake: stake, endsMatch: endsMatch))
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

/// Retry, or replace the saved game that couldn't be read with a new match once the players confirm.
private struct ReadFailureView: View {
    let retry: () -> Void
    let newMatch: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Couldn’t open the saved game.", systemImage: "exclamationmark.triangle")
                .accessibilityIdentifier("readFailureNotice")
        } actions: {
            Button("Retry", action: retry)
                .gameActionStyle()
                .accessibilityHint(Text("Opens the saved game again"))
                .accessibilityIdentifier("retryRead")
            Button("New match", action: newMatch)
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
