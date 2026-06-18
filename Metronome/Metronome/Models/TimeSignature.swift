import Foundation

enum TimeSignature: String, CaseIterable, Identifiable {
    case fourFour = "4/4"
    case threeFour = "3/4"

    var id: String { rawValue }

    var beatsPerMeasure: Int {
        switch self {
        case .fourFour: 4
        case .threeFour: 3
        }
    }
}
