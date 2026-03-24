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
struct CourtPositions {
    
    // Spot Shooting: 5 spots around the arc
    static let spotShooting: [CourtPosition] = [
        CourtPosition(row: 0, column: 0, name: "Left Corner", rowPercent: 0.75, columnPercent: 0.15),
        CourtPosition(row: 0, column: 1, name: "Left Wing", rowPercent: 0.45, columnPercent: 0.25),
        CourtPosition(row: 0, column: 2, name: "Top of Key", rowPercent: 0.30, columnPercent: 0.50),
        CourtPosition(row: 0, column: 3, name: "Right Wing", rowPercent: 0.45, columnPercent: 0.75),
        CourtPosition(row: 0, column: 4, name: "Right Corner", rowPercent: 0.75, columnPercent: 0.85)
    ]
    
    // Free Throws: Single position at the line
    static let freeThrow: [CourtPosition] = [
        CourtPosition(row: 0, column: 0, name: "Free Throw Line", rowPercent: 0.55, columnPercent: 0.50)
    ]
    
    // Form Shooting: Close to basket
    static let formShooting: [CourtPosition] = [
        CourtPosition(row: 0, column: 0, name: "Close Range", rowPercent: 0.70, columnPercent: 0.50)
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
