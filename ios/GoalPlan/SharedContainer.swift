import Foundation

/// Provides access to the App Group shared container for data sharing between the app and widget
enum SharedContainer {

    private static let appGroupIdentifier = "group.com.goalplan.GoalPlan"

    /// Get the shared container URL
    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier)
    }

    /// Get the plan.json file URL in the shared container
    static var planFileURL: URL? {
        containerURL?.appendingPathComponent("plan.json")
    }

    /// Load plan from shared container
    static func loadPlan() -> Plan? {
        guard let fileURL = planFileURL else { return nil }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let plan = try decoder.decode(Plan.self, from: data)
            return plan
        } catch {
            // File doesn't exist or is corrupted - return nil to trigger default plan
            return nil
        }
    }

    /// Save plan to shared container
    static func savePlan(_ plan: Plan) throws {
        guard let fileURL = planFileURL else {
            throw SharedContainerError.containerNotFound
        }

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(plan)
        try data.write(to: fileURL, options: [.atomic])
    }

    /// Export plan as JSON data for sharing
    static func exportPlan(_ plan: Plan) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return try encoder.encode(plan)
    }

    /// Import plan from JSON data
    static func importPlan(from data: Data) throws -> Plan {
        let decoder = JSONDecoder()
        return try decoder.decode(Plan.self, from: data)
    }
}

enum SharedContainerError: LocalizedError {
    case containerNotFound

    var errorDescription: String? {
        switch self {
        case .containerNotFound:
            return "App Group container not found. Check entitlements configuration."
        }
    }
}
