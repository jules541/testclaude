import Foundation
import CoreTransferable
import UniformTypeIdentifiers

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

    // MARK: - Quarter Archives

    /// Archive file URL for a quarter, e.g. "Q2 2026" → plan-archive-Q2-2026.json
    static func archiveFileURL(for quarter: String) -> URL? {
        let slug = quarter.replacingOccurrences(of: " ", with: "-")
        return containerURL?.appendingPathComponent("plan-archive-\(slug).json")
    }

    /// Archive a completed quarter's plan to a quarter-stamped file
    static func archivePlan(_ plan: Plan) throws {
        guard let fileURL = archiveFileURL(for: plan.quarter) else {
            throw SharedContainerError.containerNotFound
        }
        let data = try exportPlan(plan)
        try data.write(to: fileURL, options: [.atomic])
    }

    /// Load an archived plan for a given quarter, if one exists
    static func loadArchivedPlan(quarter: String) -> Plan? {
        guard let fileURL = archiveFileURL(for: quarter),
              let data = try? Data(contentsOf: fileURL) else { return nil }
        return try? JSONDecoder().decode(Plan.self, from: data)
    }
}

/// Shareable JSON export of a plan, offered to ShareLink as a named .json file
struct PlanExport: Transferable {
    let plan: Plan

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { export in
            try SharedContainer.exportPlan(export.plan)
        }
        .suggestedFileName { export in
            "GoalPlan-\(export.plan.quarter.replacingOccurrences(of: " ", with: "-")).json"
        }
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
