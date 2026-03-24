import SwiftUI

struct iPhoneWorkoutView: View {
    let selectedDrill: String

    @EnvironmentObject var appData: AppDataStore
    @ObservedObject var connectivity = WorkoutConnectivity.shared

    @State private var workoutActive = false
    @State private var workout: Workout? = nil
    @State private var workoutStartDate: Date? = nil
    @State private var lastReceivedValue: Int? = nil

    @State private var makes: Int = 0
    @State private var misses: Int = 0
    @State private var swishes: Int = 0
    @State private var currentPositionIndex: Int = 0
    @State private var shotsAtCurrentPosition: Int = 0
    
    private let shotsPerPosition: Int = 5 // Configurable shots per spot for drills

    private var totalMakes: Int { makes + swishes }
    private var attempts: Int { totalMakes + misses }

    private var subtitleText: String {
        if selectedDrill == "Spot Shooting" {
            let positions = CourtPositions.positions(for: selectedDrill)
            let totalShots = positions.count * shotsPerPosition
            if workoutActive {
                return "Position \(currentPositionIndex + 1) of \(positions.count) • \(attempts)/\(totalShots) shots"
            }
            return "25 total shots (5 per spot)"
        } else if selectedDrill == "Free Throws" {
            if workoutActive {
                return "Shot \(attempts) of \(shotsPerPosition)"
            }
            return "5 attempt routine"
        } else if selectedDrill == "Form Shooting" {
            if workoutActive {
                return "Shot \(attempts) of \(shotsPerPosition)"
            }
            return "Close range mechanics"
        } else {
            return workoutActive ? "Active drill session" : "Ready to start"
        }
    }

    private var fgPercent: Double {
        guard attempts > 0 else { return 0 }
        return (Double(totalMakes) / Double(attempts)) * 100.0
    }

    var body: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(selectedDrill)
                    .font(.title2)
                    .bold()

                Text(subtitleText)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .leading, spacing: 10) {
                Text(workoutActive ? "Active Workout" : "No Active Workout")
                    .font(.headline)

                HStack {
                    stat("Makes", "\(totalMakes)")
                    stat("Misses", "\(misses)")
                    stat("Swish", "\(swishes)")
                    stat("Att", "\(attempts)")
                }

                Text("FG%: \(fgPercent, specifier: "%.1f")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.thinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            HStack(spacing: 12) {
                Button("Start Workout") {
                    let start = Date()
                    let w = Workout(id: UUID(), startDate: start, userValue: nil)
                    workout = w
                    workoutStartDate = start
                    workoutActive = true

                    makes = 0
                    misses = 0
                    swishes = 0
                    lastReceivedValue = nil
                    currentPositionIndex = 0
                    shotsAtCurrentPosition = 0

                    connectivity.sendWorkoutStarted()
                    
                    // Send drill info to watch
                    connectivity.sendDrillInfo(selectedDrill)
                    
                    // Send initial position to watch
                    let positions = CourtPositions.positions(for: selectedDrill)
                    if !positions.isEmpty {
                        connectivity.sendPositionUpdate(positions[0])
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(workoutActive)

                Button("Stop Workout") {
                    finishWorkout()
                }
                .buttonStyle(.bordered)
                .frame(maxWidth: .infinity)
                .disabled(!workoutActive)
            }

            Group {
                if let v = lastReceivedValue {
                    Text("Last watch code: \(v)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Waiting for watch data…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Debug: Show current position info
                if workoutActive {
                    let positions = CourtPositions.positions(for: selectedDrill)
                    if currentPositionIndex < positions.count {
                        let currentPos = positions[currentPositionIndex]
                        Text("Position: \(currentPos.name ?? "Unknown") (\(currentPositionIndex + 1)/\(positions.count))")
                            .font(.caption2)
                            .foregroundStyle(.blue)
                    }
                }
            }

            VStack(spacing: 10) {
                Text("Quick Log (Debug)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                HStack(spacing: 10) {
                    Button("MAKE") {
                        if workoutActive {
                            recordManualShot(1)
                        }
                    }
                    .buttonStyle(.borderedProminent)

                    Button("MISS") {
                        if workoutActive {
                            recordManualShot(0)
                        }
                    }
                    .buttonStyle(.bordered)

                    Button("SWISH") {
                        if workoutActive {
                            recordManualShot(2)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            }

            if let w = workout {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Workout Summary")
                        .font(.title3)
                        .bold()

                    Text("Drill: \(selectedDrill)")
                        .foregroundStyle(.secondary)

                    Text("Started: \(w.startDate.formatted())")
                        .foregroundStyle(.secondary)

                    Text("Makes: \(totalMakes)  Misses: \(misses)  Swishes: \(swishes)")
                    Text("Attempts: \(attempts)   FG%: \(fgPercent, specifier: "%.1f")")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Spacer()
        }
        .padding()
        .navigationTitle("Workout")
        .navigationBarTitleDisplayMode(.inline)
        .onReceive(connectivity.$receivedValue) { newValue in
            guard let v = newValue else { return }
            lastReceivedValue = v
            if workoutActive {
                applyWatchValue(v)
            }
        }
    }

    private func applyWatchValue(_ v: Int) {
        switch v {
        case 0:
            misses += 1
        case 1:
            makes += 1
        case 2:
            swishes += 1
        default:
            break
        }
        
        shotsAtCurrentPosition += 1
        
        let positions = CourtPositions.positions(for: selectedDrill)
        
        // All drills use 5 shots per position
        if shotsAtCurrentPosition >= shotsPerPosition {
            shotsAtCurrentPosition = 0
            currentPositionIndex += 1
            
            if currentPositionIndex >= positions.count {
                // Drill complete
                finishWorkout()
            } else {
                // Send next position
                connectivity.sendPositionUpdate(positions[currentPositionIndex])
            }
        }
    }
    
    private func recordManualShot(_ shotType: Int) {
        // Apply locally
        applyWatchValue(shotType)
        // Send to watch so it updates its shot count
        connectivity.sendValueToPhone(shotType)
    }
    
    private func finishWorkout() {
        let endDate = Date()
        if workoutActive && attempts > 0 {
            let session = WorkoutSession(
                drill: selectedDrill,
                makes: totalMakes,
                misses: misses,
                swishes: swishes,
                attempts: attempts,
                startDate: workoutStartDate ?? endDate,
                endDate: endDate
            )
            appData.addSession(session)
        }
        workoutActive = false
        // Send stop to watch to trigger summary display
        connectivity.sendWorkoutStopped()
    }

    private func stat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .bold()

            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        iPhoneWorkoutView(selectedDrill: "Form Shooting")
            .environmentObject(AppDataStore())
    }
}
