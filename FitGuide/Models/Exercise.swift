import Foundation
import SwiftUI

struct Exercise: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: String
    let bodyPart: String
    let equipment: String
    let instructions: [String: String]
    let instructionSteps: [String: [String]]
    let muscleGroup: String
    let secondaryMuscles: [String]
    let target: String
    let mediaId: String
    let image: String
    let gifUrl: String
    let attribution: String
    let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id, name, category
        case bodyPart = "body_part"
        case equipment
        case instructions
        case instructionSteps = "instruction_steps"
        case muscleGroup = "muscle_group"
        case secondaryMuscles = "secondary_muscles"
        case target
        case mediaId = "media_id"
        case image
        case gifUrl = "gif_url"
        case attribution
        case createdAt = "created_at"
    }

    static let gymVisualAttribution = "© Gym visual — https://gymvisual.com/"
}