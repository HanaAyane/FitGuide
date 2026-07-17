import Foundation
import SwiftUI
import os

@MainActor
final class ExerciseStore: ObservableObject {
    @Published private(set) var exercises: [Exercise] = []
    @Published private(set) var byBodyPart: [String: [Exercise]] = [:]
    @Published private(set) var bodyParts: [String] = []

    private let log = Logger(subsystem: "com.local.fitguide", category: "ExerciseStore")

    init() {
        Task { await load() }
    }

    func load() async {
        guard let url = Bundle.main.url(forResource: "exercises", withExtension: "json", subdirectory: "data") ?? Bundle.main.url(forResource: "exercises", withExtension: "json") else {
            log.error("exercises.json not found in bundle")
            assertionFailure("exercises.json not found in bundle")
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode([Exercise].self, from: data)
            self.exercises = decoded
            self.byBodyPart = Dictionary(grouping: decoded, by: { $0.bodyPart })
            self.bodyParts = byBodyPart.keys.sorted { a, b in
                let orderA = BodyPartOrder.indexOf(a)
                let orderB = BodyPartOrder.indexOf(b)
                if orderA != orderB { return orderA < orderB }
                return a < b
            }
            log.info("loaded \(decoded.count) exercises, \(self.bodyParts.count) body parts")
        } catch {
            log.error("Failed to decode exercises.json: \(String(describing: error))")
            assertionFailure("Failed to decode exercises.json: \(error)")
        }
    }

    func distinctValues(for keyPath: KeyPath<Exercise, String>) -> [String] {
        Set(exercises.map { $0[keyPath: keyPath] }).sorted()
    }

    func filtered(bodyParts: Set<String>, equipments: Set<String>, targets: Set<String>) -> [Exercise] {
        exercises.filter { ex in
            (bodyParts.isEmpty || bodyParts.contains(ex.bodyPart))
            && (equipments.isEmpty || equipments.contains(ex.equipment))
            && (targets.isEmpty || targets.contains(ex.target))
        }
    }

    func search(query: String) -> [Exercise] {
        let q = query.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return exercises }
        return exercises.filter { ex in
            let nameEn = ex.name.lowercased()
            let nameZh = ex.nameZH.lowercased()
            let targetEn = ex.target.lowercased()
            let targetZh = ex.targetZH.lowercased()
            let mgEn = ex.muscleGroup.lowercased()
            let mgZh = ex.muscleGroupZH.lowercased()
            let eqEn = ex.equipment.lowercased()
            let eqZh = ex.equipmentZH.lowercased()
            let bpEn = ex.bodyPart.lowercased()
            let bpZh = ex.bodyPartZH.lowercased()
            return nameEn.contains(q) || nameZh.contains(q)
                || targetEn.contains(q) || targetZh.contains(q)
                || mgEn.contains(q) || mgZh.contains(q)
                || eqEn.contains(q) || eqZh.contains(q)
                || bpEn.contains(q) || bpZh.contains(q)
        }
    }

    static func imageURL(for exercise: Exercise) -> URL? {
        let filename = (exercise.image as NSString).lastPathComponent
        if let url = Bundle.main.url(forResource: filename, withExtension: nil, subdirectory: "images") {
            return url
        }
        return Bundle.main.url(forResource: filename, withExtension: nil)
    }

    static func gifURL(for exercise: Exercise) -> URL? {
        let filename = (exercise.gifUrl as NSString).lastPathComponent
        if let url = Bundle.main.url(forResource: filename, withExtension: nil, subdirectory: "videos") {
            return url
        }
        return Bundle.main.url(forResource: filename, withExtension: nil)
    }
}