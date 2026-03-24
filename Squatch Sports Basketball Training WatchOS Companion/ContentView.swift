import SwiftUI

// MARK: - Shot Statistics Model

struct PositionStats: Identifiable, Codable {
    let id: UUID
    let position: CourtPosition
    var makes: Int
    var misses: Int
    var swishes: Int
    let timestamp: Date
    
    var totalShots: Int {
        makes + misses + swishes
    }
    
    var makePercentage: Double {
        guard totalShots > 0 else { return 0 }
        return Double(makes + swishes) / Double(totalShots) * 100
    }
    
    var swishPercentage: Double {
        guard totalShots > 0 else { return 0 }
        return Double(swishes) / Double(totalShots) * 100
    }
    
    init(position: CourtPosition) {
        self.id = UUID()
        self.position = position
        self.makes = 0
        self.misses = 0
        self.swishes = 0
        self.timestamp = Date()
    }
    
    mutating func recordShot(_ direction: ShotDirection) {
        switch direction {
        case .make:
            makes += 1
        case .miss:
            misses += 1
        case .swish:
            swishes += 1
        }
    }
}

struct WatchWorkoutSession: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    var endDate: Date?
    var positionStats: [PositionStats]
    var drillName: String?
    
    var totalShots: Int {
        positionStats.reduce(0) { $0 + $1.totalShots }
    }
    
    var totalMakes: Int {
        positionStats.reduce(0) { $0 + $1.makes + $1.swishes }
    }
    
    var totalMisses: Int {
        positionStats.reduce(0) { $0 + $1.misses }
    }
    
    var totalSwishes: Int {
        positionStats.reduce(0) { $0 + $1.swishes }
    }
    
    var overallPercentage: Double {
        guard totalShots > 0 else { return 0 }
        return Double(totalMakes) / Double(totalShots) * 100
    }
    
    init(drillName: String? = nil) {
        self.id = UUID()
        self.startDate = Date()
        self.positionStats = []
        self.drillName = drillName
    }
}

struct ContentView: View {
    @EnvironmentObject var connectivity: WorkoutConnectivity
    @State private var highlightedDirection: ShotDirection?
    @State private var lastShotStatus: ShotDirection?
    @State private var selectedPosition: CourtPosition?
    @State private var shotCount = 0
    @State private var currentSession: WatchWorkoutSession?
    @State private var currentPositionStats: PositionStats?
    @State private var showSummary = false
    @State private var currentDrill: String?
    @State private var drillPositions: [CourtPosition] = []
    @State private var currentPositionIndex = 0

    private let pillWidth: CGFloat = 80
    private let pillHeight: CGFloat = 28

    private let edgeInset: CGFloat = 4
    private let centerPadScale: CGFloat = 0.20
    private let barCornerRadius: CGFloat = 10
    
    // Shots per position - always 5 for consistency
    private let shotsPerPosition: Int = 5

    var body: some View {
        GeometryReader { geometry in
            Group {
                if showSummary {
                    workoutSummaryView
                } else if connectivity.workoutActive {
                    activeWorkoutView(for: geometry)
                } else {
                    waitingView
                }
            }
        }
        .onChange(of: connectivity.workoutActive) { _, newValue in
            if newValue {
                // Reset everything for new workout
                showSummary = false
                currentSession = WatchWorkoutSession(drillName: currentDrill)
                shotCount = 0
                currentPositionStats = nil
                currentPositionIndex = 0
                selectedPosition = nil
                
                // For general workout, immediately create a default position so user can start shooting
                if currentDrill == nil {
                    let defaultPos = CourtPosition(row: 0, column: 0, name: "General", rowPercent: 0.5, columnPercent: 0.5)
                    selectedPosition = defaultPos
                    currentPositionStats = PositionStats(position: defaultPos)
                }
            } else if !showSummary {
                // Workout stopped - show summary if we have any data (only if not already showing)
                if let session = currentSession {
                    var finalSession = session
                    
                    // Save any current position stats that haven't been saved yet
                    if let stats = currentPositionStats, stats.totalShots > 0 {
                        finalSession.positionStats.append(stats)
                    }
                    
                    // Only show summary if there's actual shot data
                    if !finalSession.positionStats.isEmpty {
                        finalSession.endDate = Date()
                        currentSession = finalSession
                        showSummary = true
                    }
                }
            }
        }
        .onChange(of: connectivity.currentDrill) { _, newDrill in
            if let drill = newDrill {
                currentDrill = drill
                drillPositions = CourtPositions.positions(for: drill)
            } else {
                currentDrill = nil
                drillPositions = []
            }
        }
        .onChange(of: connectivity.currentPosition) { _, newPosition in
            if let position = newPosition, connectivity.workoutActive {
                // Drill mode - accept position from iPhone and set it up immediately
                selectedPosition = position
                currentPositionStats = PositionStats(position: position)
                shotCount = 0
            }
        }
        .onChange(of: connectivity.receivedValue) { _, newValue in
            guard let value = newValue, connectivity.workoutActive else { return }
            
            // Receive shot from iPhone
            let direction: ShotDirection
            switch value {
            case 0:
                direction = .miss
            case 1:
                direction = .make
            case 2:
                direction = .swish
            default:
                return
            }
            
            // Record the shot
            currentPositionStats?.recordShot(direction)
            lastShotStatus = direction
            shotCount += 1
            
            // Check if position is complete
            if shotCount >= shotsPerPosition {
                handlePositionComplete()
            }
        }
    }

    private func activeWorkoutView(for geometry: GeometryProxy) -> some View {
        return ZStack {
            Color.black.ignoresSafeArea()
            
            // Court image with position marker (always present)
            courtView(for: geometry)

            // Show pills and center pad when we have an active position
            if currentPositionStats != nil {
                // Make — top center
                VStack {
                    edgePill(title: "Make", color: .green, direction: .make)
                        .frame(width: pillWidth, height: pillHeight)
                        .opacity(0.75)
                        .padding(.top, edgeInset)
                    Spacer()
                }

                // Miss — bottom center
                VStack {
                    Spacer()
                    edgePill(title: "Miss", color: .red, direction: .miss)
                        .frame(width: pillWidth, height: pillHeight)
                        .opacity(0.75)
                        .padding(.bottom, edgeInset)
                }

                // Swish — right center
                HStack {
                    Spacer()
                    edgePill(title: "Swish", color: .pink, direction: .swish)
                        .frame(width: pillHeight, height: pillWidth)
                        .opacity(0.75)
                        .padding(.trailing, edgeInset)
                }

                centerPad(for: geometry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            
            // Live stats indicator - positioned at BOTTOM LEFT corner (lifted up from edge)
            if let stats = currentPositionStats {
                VStack {
                    Spacer()
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 3) {
                                Text("\(stats.makes + stats.swishes)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.green)
                                Text("/")
                                    .font(.system(size: 8))
                                    .foregroundStyle(.white.opacity(0.6))
                                Text("\(stats.totalShots)")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                            
                            Text("\(shotsPerPosition - shotCount) left")
                                .font(.system(size: 7))
                                .foregroundStyle(.white.opacity(0.7))
                            
                            if let name = stats.position.name {
                                Text(name)
                                    .font(.system(size: 6))
                                    .foregroundStyle(.white.opacity(0.5))
                                    .lineLimit(1)
                            }
                            
                            if currentDrill != nil, !drillPositions.isEmpty {
                                Text("\(currentPositionIndex + 1)/\(drillPositions.count)")
                                    .font(.system(size: 6))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.black.opacity(0.4))
                        )
                        .padding(.leading, 6)
                        .padding(.bottom, 12) // Lifted from 6 to 12
                        
                        Spacer()
                    }
                }
            }
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
                .fill(color.opacity(highlightedDirection == direction ? 0.9 : 0.6))
                .overlay(
                    RoundedRectangle(cornerRadius: barCornerRadius, style: .continuous)
                        .stroke(color.opacity(0.8), lineWidth: 1.5)
                )

            Text(title)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(.white.opacity(0.95))
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
                
                // Record the shot in current position stats
                currentPositionStats?.recordShot(direction)
                
                // Send to phone
                connectivity.sendValueToPhone(direction.rawValue)
                lastShotStatus = direction
                
                // Increment shot count
                shotCount += 1
                
                // Check if position is complete
                if shotCount >= shotsPerPosition {
                    handlePositionComplete()
                }
            }
    }
    
    private func handlePositionComplete() {
        // Save current position stats to session
        if let stats = currentPositionStats {
            currentSession?.positionStats.append(stats)
        }
        
        // Check if this is a drill with multiple positions
        if currentDrill != nil, !drillPositions.isEmpty {
            currentPositionIndex += 1
            
            // Check if drill is complete
            if currentPositionIndex >= drillPositions.count {
                // Drill complete - finalize and show summary
                if var session = currentSession {
                    session.endDate = Date()
                    currentSession = session
                }
                
                // Show summary immediately
                showSummary = true
                selectedPosition = nil
                currentPositionStats = nil
            } else {
                // Move to next position automatically
                let nextPosition = drillPositions[currentPositionIndex]
                selectedPosition = nextPosition
                currentPositionStats = PositionStats(position: nextPosition)
                shotCount = 0
                connectivity.sendPositionUpdate(nextPosition)
            }
        } else {
            // General workout - reset for next set of 5 shots
            shotCount = 0
            // Keep same position, just reset stats
            if let currentPos = selectedPosition {
                currentPositionStats = PositionStats(position: currentPos)
            }
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
    
    // MARK: - Workout Summary View
    
    private var workoutSummaryView: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Header
                VStack(spacing: 2) {
                    Text(currentSession?.drillName ?? "Workout")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    
                    Text("Complete!")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
                
                if let session = currentSession {
                    // Overall Stats
                    HStack(spacing: 12) {
                        VStack(spacing: 1) {
                            Text("\(session.totalMakes)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.green)
                            Text("Makes")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 1) {
                            Text("\(session.totalMisses)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.red)
                            Text("Misses")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 1) {
                            Text("\(session.totalSwishes)")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.pink)
                            Text("Swish")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                        
                        VStack(spacing: 1) {
                            Text("\(Int(session.overallPercentage))%")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundStyle(.blue)
                            Text("FG%")
                                .font(.system(size: 8))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                    
                    // Total shots
                    Text("\(session.totalShots) total shots")
                        .font(.system(size: 9))
                        .foregroundStyle(.secondary)
                    
                    Divider()
                        .padding(.vertical, 2)
                    
                    // Position breakdown
                    if !session.positionStats.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("By Position")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                            
                            ForEach(Array(session.positionStats.enumerated()), id: \.element.id) { index, stats in
                                compactStatCard(stats: stats, number: index + 1)
                            }
                        }
                    }
                }
                
                // Dismiss button
                Button {
                    showSummary = false
                    currentSession = nil
                    currentPositionStats = nil
                    selectedPosition = nil
                    shotCount = 0
                    currentPositionIndex = 0
                    currentDrill = nil
                    drillPositions = []
                    
                    // Signal to iPhone that watch is done viewing summary
                    connectivity.sendWorkoutStopped()
                } label: {
                    Text("Done")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.blue)
                        )
                }
                .padding(.horizontal, 12)
                .padding(.top, 4)
                .padding(.bottom, 4)
            }
        }
        .background(Color.black)
    }
    
    private func compactStatCard(stats: PositionStats, number: Int) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(stats.position.name ?? "Spot \(number)")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Text("\(Int(stats.makePercentage))%")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(stats.makePercentage >= 60 ? .green : .orange)
            }
            
            HStack(spacing: 8) {
                Label("\(stats.makes)", systemImage: "checkmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.green)
                
                Label("\(stats.swishes)", systemImage: "sparkles")
                    .font(.system(size: 9))
                    .foregroundStyle(.pink)
                
                Label("\(stats.misses)", systemImage: "xmark.circle.fill")
                    .font(.system(size: 9))
                    .foregroundStyle(.red)
                
                Spacer()
                
                Text("\(stats.totalShots) shots")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.1))
        )
        .padding(.horizontal, 8)
    }
    
    // MARK: - Court Position Display
    
    private func courtView(for geometry: GeometryProxy) -> some View {
        GeometryReader { courtGeo in
            ZStack {
                // Lightweight court diagram drawn with SwiftUI
                SimplifiedCourtView()
                
                // Position marker
                if let position = selectedPosition {
                    PositionMarker()
                        .position(
                            x: courtGeo.size.width * position.columnPercent,
                            y: courtGeo.size.height * position.rowPercent
                        )
                }
            }
            .contentShape(Rectangle())
            .highPriorityGesture(
                TapGesture()
                    .onEnded { _ in
                        // Get tap location using DragGesture with 0 distance
                    }
            )
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        // ONLY allow tapping for general workout (drills are unaffected)
                        guard connectivity.workoutActive else { return }
                        guard currentDrill == nil else { return }
                        
                        let tapX = value.location.x / courtGeo.size.width
                        let tapY = value.location.y / courtGeo.size.height
                        
                        let position = CourtPosition(
                            row: 0,
                            column: 0,
                            name: nil,
                            rowPercent: tapY,
                            columnPercent: tapX
                        )
                        
                        selectedPosition = position
                        
                        // Only create new stats if we don't have one yet
                        if currentPositionStats == nil {
                            currentPositionStats = PositionStats(position: position)
                            shotCount = 0
                        }
                        
                        // Send to iPhone
                        connectivity.sendPositionUpdate(position)
                    }
            )
        }
    }
}

// MARK: - Simplified Court View

private struct SimplifiedCourtView: View {
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            
            ZStack {
                // WOOD FLOOR - Brighter polished look
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.70, blue: 0.52),
                                Color(red: 0.78, green: 0.62, blue: 0.45),
                                Color(red: 0.82, green: 0.66, blue: 0.48)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Polished shine overlay
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.12),
                                Color.clear,
                                Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                
                // Wood grain lines - smaller planks for watch size
                ForEach(0..<20, id: \.self) { i in
                    Rectangle()
                        .fill(Color.black.opacity(0.08))
                        .frame(width: 1, height: height)
                        .position(x: CGFloat(i) * width / 20 + width / 40, y: height / 2)
                }
                
                // Horizontal wood plank lines
                ForEach(0..<12, id: \.self) { i in
                    Rectangle()
                        .fill(Color.black.opacity(0.06))
                        .frame(width: width, height: 0.5)
                        .position(x: width / 2, y: CGFloat(i) * height / 12 + height / 24)
                }
                
                // Outer court boundary - WHITE LINES with colored sections
                // Top edge - GREEN
                Rectangle()
                    .fill(Color.green.opacity(0.6))
                    .frame(width: width, height: 4)
                    .position(x: width / 2, y: 2)
                
                // Bottom edge - RED
                Rectangle()
                    .fill(Color.red.opacity(0.6))
                    .frame(width: width, height: 4)
                    .position(x: width / 2, y: height - 2)
                
                // Left edge - WHITE
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 4, height: height)
                    .position(x: 2, y: height / 2)
                
                // Right edge - PINK
                Rectangle()
                    .fill(Color.pink.opacity(0.6))
                    .frame(width: 4, height: height)
                    .position(x: width - 2, y: height / 2)
                
                // HOOP AT TOP (rim)
                Circle()
                    .fill(Color.red.opacity(0.9))
                    .frame(width: width * 0.095, height: width * 0.095)
                    .position(x: width / 2, y: height * 0.14)
                
                Circle()
                    .stroke(Color.orange, lineWidth: 2)
                    .frame(width: width * 0.095, height: width * 0.095)
                    .position(x: width / 2, y: height * 0.14)
                
                // Backboard - More detailed rectangular shape
                ZStack {
                    // Main backboard rectangle
                    Rectangle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: width * 0.24, height: height * 0.055)
                    
                    // Border to make it stand out
                    Rectangle()
                        .stroke(Color.white, lineWidth: 2)
                        .frame(width: width * 0.24, height: height * 0.055)
                    
                    // Inner box (target square)
                    Rectangle()
                        .stroke(Color.white, lineWidth: 1.5)
                        .frame(width: width * 0.12, height: height * 0.035)
                }
                .position(x: width / 2, y: height * 0.085)
                
                // Paint area (rectangular, proportional)
                Rectangle()
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: width * 0.36, height: height * 0.29)
                    .position(x: width / 2, y: height * 0.26)
                
                // Free throw line (matches paint width)
                Rectangle()
                    .fill(Color.white)
                    .frame(width: width * 0.36, height: 2)
                    .position(x: width / 2, y: height * 0.37)
                
                // Large solid semi-circle BELOW the free throw line (bottom half of circle)
                Circle()
                    .trim(from: 0.0, to: 0.5)
                    .stroke(Color.white, lineWidth: 2)
                    .frame(width: width * 0.36, height: width * 0.36)
                    .position(x: width / 2, y: height * 0.37)
                
                // Dashed semi-circle at TOP of the key (inside the paint, near backboard)
                Circle()
                    .trim(from: 0.5, to: 1.0) // Bottom half of circle
                    .stroke(Color.white, style: StrokeStyle(lineWidth: 2, dash: [3, 2]))
                    .frame(width: width * 0.36, height: width * 0.36)
                    .rotationEffect(.degrees(180)) // Flip it so the arc faces down
                    .position(x: width / 2, y: height * 0.13)
                
                // Lane hash marks - Left side
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 8, height: 2)
                        .position(x: width / 2 - width * 0.18, y: height * 0.15 + CGFloat(i) * height * 0.055)
                }
                
                // Lane hash marks - Right side
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 8, height: 2)
                        .position(x: width / 2 + width * 0.18, y: height * 0.15 + CGFloat(i) * height * 0.055)
                }
                
                // THREE-POINT LINE (larger, fills watch properly)
                Path { path in
                    let centerX = width / 2
                    let centerY = height * 0.12
                    let radius = width * 0.52
                    
                    // Arc
                    path.addArc(
                        center: CGPoint(x: centerX, y: centerY),
                        radius: radius,
                        startAngle: .degrees(38),
                        endAngle: .degrees(142),
                        clockwise: false
                    )
                    
                    // Calculate endpoints
                    let angle = 38.0 * .pi / 180.0
                    let leftX = centerX - radius * cos(angle)
                    let leftY = centerY + radius * sin(angle)
                    let rightX = centerX + radius * cos(angle)
                    let rightY = centerY + radius * sin(angle)
                    
                    // Left corner line UP to top (with spacing)
                    path.move(to: CGPoint(x: leftX, y: leftY))
                    path.addLine(to: CGPoint(x: leftX, y: height * 0.06))
                    
                    // Right corner line UP to top (with spacing)
                    path.move(to: CGPoint(x: rightX, y: rightY))
                    path.addLine(to: CGPoint(x: rightX, y: height * 0.06))
                }
                .stroke(Color.white, lineWidth: 2.5)
                
                // SQUATCH LOGO at center court with circle background
                ZStack {
                    // White circle background
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: width * 0.28, height: width * 0.28)
                    
                    // Black ring border
                    Circle()
                        .stroke(Color.black, lineWidth: 2)
                        .frame(width: width * 0.28, height: width * 0.28)
                    
                    // Logo
                    Image("Mascot_BigFoot")
                        .resizable()
                        .scaledToFit()
                        .frame(width: width * 0.22, height: width * 0.22)
                }
                .position(x: width / 2, y: height * 0.78)
            }
        }
    }
}

// MARK: - Position Marker View (Compact for small watch screen)

private struct PositionMarker: View {
    private let size: CGFloat = 24
    
    var body: some View {
        ZStack {
            // Outer circle with glow
            Circle()
                .fill(Color.blue.opacity(0.3))
                .frame(width: size + 4, height: size + 4)
                .blur(radius: 2)
            
            // Main outer circle
            Circle()
                .stroke(Color.blue, lineWidth: 2.5)
                .frame(width: size, height: size)
            
            // Center dot for precision
            Circle()
                .fill(Color.blue)
                .frame(width: 6, height: 6)
        }
    }
}

enum ShotDirection: Int {
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
