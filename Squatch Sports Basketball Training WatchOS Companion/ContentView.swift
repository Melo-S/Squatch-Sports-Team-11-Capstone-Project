import SwiftUI

struct ContentView: View {
    @EnvironmentObject var connectivity: WorkoutConnectivity
    @State private var highlightedDirection: ShotDirection?
    @State private var lastShotStatus: ShotDirection?

    private let pillWidth: CGFloat = 150
    private let pillHeight: CGFloat = 40

    private let edgeInset: CGFloat = 4
    private let centerPadScale: CGFloat = 0.34
    private let barCornerRadius: CGFloat = 14

    var body: some View {

        GeometryReader { geometry in
            Group {
                if connectivity.workoutActive {
                    activeWorkoutView(for: geometry)
                } else {
                    waitingView
                }
            }
        }
    }

    private func activeWorkoutView(for geometry: GeometryProxy) -> some View {
        return ZStack {
            Color.black.ignoresSafeArea()

            // Make — top center
            VStack {
                edgePill(title: "Make", color: .green, direction: .make)
                    .frame(width: pillWidth, height: pillHeight)
                    .padding(.top, edgeInset)
                Spacer()
            }

            // Miss — bottom center
            VStack {
                Spacer()
                edgePill(title: "Miss", color: .red, direction: .miss)
                    .frame(width: pillWidth, height: pillHeight)
                    .padding(.bottom, edgeInset)
            }

            // Swish — right center
            HStack {
                Spacer()
                edgePill(title: "Swish", color: .pink, direction: .swish)
                    .frame(width: pillHeight, height: pillWidth)
                    .padding(.trailing, edgeInset)
            }

            centerPad(for: geometry)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
    }

    private var waitingView: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 8) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.8))

                Text("Waiting for workout")
                    .font(.headline)

                Text("Start a session on iPhone to enable shot logging.")
                    .font(.caption2)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
        }
    }

    private func centerPad(for geometry: GeometryProxy) -> some View {
        let size = min(geometry.size.width, geometry.size.height) * centerPadScale

        return ZStack {
            Circle()
                .fill(Color.white.opacity(0.08))
            Circle()
                .stroke(borderColor, lineWidth: 1.5)
            Image(systemName: "hand.draw")
                .font(.title3)
                .foregroundStyle(.white.opacity(0.85))
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(centerSwipeGesture())
    }

    private func edgePill(
        title: String,
        color: Color,
        direction: ShotDirection
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: barCornerRadius, style: .continuous)
                .fill(color.opacity(highlightedDirection == direction ? 1.0 : 0.75))

            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .lineLimit(1)
                .rotationEffect(direction == .swish ? .degrees(-90) : .zero)
        }
    }

    private func centerSwipeGesture() -> some Gesture {
        DragGesture(minimumDistance: 18, coordinateSpace: .local)
            .onChanged { value in
                highlightedDirection = resolvedDirection(for: value.translation)
            }
            .onEnded { value in
                let direction = resolvedDirection(for: value.translation)
                highlightedDirection = nil

                guard let direction else { return }
                connectivity.sendValueToPhone(direction.rawValue)
                lastShotStatus = direction
            }
    }

    private func resolvedDirection(for translation: CGSize) -> ShotDirection? {
        let horizontal = translation.width
        let vertical = translation.height
        let threshold: CGFloat = 24

        if abs(horizontal) < threshold, abs(vertical) < threshold {
            return nil
        }

        if abs(vertical) >= abs(horizontal) {
            return vertical < 0 ? .make : .miss
        }

        if horizontal > 0 {
            return .swish
        }

        return nil
    }

    private var borderColor: Color {
        lastShotStatus?.color.opacity(0.9) ?? .white.opacity(0.18)
    }
}

private enum ShotDirection: Int {
    case miss = 0
    case make = 1
    case swish = 2

    var color: Color {
        switch self {
        case .miss:
            .red
        case .make:
            .green
        case .swish:
            .pink
        }
    }
}

#Preview {
    let connectivity = WorkoutConnectivity.shared
    connectivity.workoutActive = true
    return ContentView().environmentObject(connectivity)
}
