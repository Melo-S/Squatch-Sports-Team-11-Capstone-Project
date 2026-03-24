//
//  CourtPosition.swift
//  Squatch Sports Basketball Training
//
//  Court position model for shot location tracking
//

import Foundation

struct CourtPosition: Codable, Equatable {
    let row: Int
    let column: Int
    let name: String?
    let rowPercent: Double      // 0.0 = top, 1.0 = bottom
    let columnPercent: Double   // 0.0 = left, 1.0 = right
    
    init(row: Int, column: Int, name: String? = nil, rowPercent: Double, columnPercent: Double) {
        self.row = row
        self.column = column
        self.name = name
        self.rowPercent = rowPercent
        self.columnPercent = columnPercent
    }
}

// Predefined court positions for different drills
// NOTE: Hoop is at TOP of watch screen (top = 0.0, bottom = 1.0)
// Three-point arc: center (0.5, 0.12), radius 0.52*width, angles 38° to 142°
struct CourtPositions {
    
    // Spot Shooting: 5 positions around the 3-point arc
    // Polished positions matching actual court geometry
    static let spotShooting: [CourtPosition] = [
        // Left Corner - where corner 3PT line meets left sideline (moved down from 0.06)
        CourtPosition(row: 0, column: 0, name: "Left Corner", rowPercent: 0.20, columnPercent: 0.10),
        
        // Left Wing - on the arc, moved back slightly from line
        CourtPosition(row: 0, column: 1, name: "Left Wing", rowPercent: 0.54, columnPercent: 0.27),
        
        // Top of Key - top of the arc
        CourtPosition(row: 0, column: 2, name: "Top of Key", rowPercent: 0.64, columnPercent: 0.50),
        
        // Right Wing - on the arc, moved back slightly from line
        CourtPosition(row: 0, column: 3, name: "Right Wing", rowPercent: 0.54, columnPercent: 0.73),
        
        // Right Corner - where corner 3PT line meets right sideline (matched to left)
        CourtPosition(row: 0, column: 4, name: "Right Corner", rowPercent: 0.20, columnPercent: 0.90)
    ]
    
    // Free Throws: Single position at the line (matches court free throw line at 0.37)
    static let freeThrow: [CourtPosition] = [
        CourtPosition(row: 0, column: 0, name: "Free Throw Line", rowPercent: 0.37, columnPercent: 0.50)
    ]
    
    // Form Shooting: Close to basket (inside the paint, near hoop)
    static let formShooting: [CourtPosition] = [
        CourtPosition(row: 0, column: 0, name: "Close Range", rowPercent: 0.22, columnPercent: 0.50)
    ]
    
    // Generic/default position
    static let defaultPosition = CourtPosition(
        row: 0,
        column: 0,
        name: "Center",
        rowPercent: 0.50,
        columnPercent: 0.50
    )
    
    static func positions(for drillName: String) -> [CourtPosition] {
        switch drillName {
        case "Spot Shooting":
            return spotShooting
        case "Free Throws":
            return freeThrow
        case "Form Shooting":
            return formShooting
        default:
            return [defaultPosition]
        }
    }
}
