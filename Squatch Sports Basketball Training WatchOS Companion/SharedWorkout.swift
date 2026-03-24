// SharedWorkout.swift
// Shared model and connectivity code for iPhone <-> Watch workout coordination

import Foundation
import WatchConnectivity
import Combine

// Workout model (simplified for prototype)
struct Workout: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    var userValue: Int?
}

// State sync message types
enum WorkoutMessage: String, Codable {
    case workoutStarted
    case workoutStopped
    case sendValue
    case updatePosition
    case drillInfo
}

// Connectivity handler for iOS/WatchOS
class WorkoutConnectivity: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WorkoutConnectivity()
    @Published var workoutActive: Bool = false
    @Published var receivedValue: Int? = nil
    @Published var currentPosition: CourtPosition? = nil
    @Published var currentDrill: String? = nil

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        } else {
            print("WCSession is not supported on this device. Connectivity features are disabled.")
        }
    }

    // MARK: - Senders
    func sendWorkoutStarted() {
        sendMessage(["type": WorkoutMessage.workoutStarted.rawValue])
    }
    func sendWorkoutStopped() {
        sendMessage(["type": WorkoutMessage.workoutStopped.rawValue])
    }
    func sendValueToPhone(_ value: Int) {
        sendMessage(["type": WorkoutMessage.sendValue.rawValue, "value": value])
    }
    func sendPositionUpdate(_ position: CourtPosition) {
        if let encoded = try? JSONEncoder().encode(position),
           let json = try? JSONSerialization.jsonObject(with: encoded) as? [String: Any] {
            var message = json
            message["type"] = WorkoutMessage.updatePosition.rawValue
            sendMessage(message)
        }
    }
    func sendDrillInfo(_ drillName: String) {
        sendMessage(["type": WorkoutMessage.drillInfo.rawValue, "drillName": drillName])
    }

    private func sendMessage(_ dict: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(dict, replyHandler: nil, errorHandler: nil)
        }
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }
    #endif

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let type = message["type"] as? String, let msg = WorkoutMessage(rawValue: type) {
                switch msg {
                case .workoutStarted:
                    self.workoutActive = true
                case .workoutStopped:
                    self.workoutActive = false
                    self.currentPosition = nil
                    self.currentDrill = nil
                case .sendValue:
                    if let value = message["value"] as? Int {
                        self.receivedValue = value
                    }
                case .updatePosition:
                    // Decode position from message
                    var positionDict = message
                    positionDict.removeValue(forKey: "type")
                    if let data = try? JSONSerialization.data(withJSONObject: positionDict),
                       let position = try? JSONDecoder().decode(CourtPosition.self, from: data) {
                        self.currentPosition = position
                    }
                case .drillInfo:
                    if let drillName = message["drillName"] as? String {
                        self.currentDrill = drillName
                    }
                }
            }
        }
    }
}
