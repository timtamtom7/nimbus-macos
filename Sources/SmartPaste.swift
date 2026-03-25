import Foundation

struct SmartPasteRule: Identifiable, Codable {
    let id: UUID
    var trigger: String
    var action: PasteAction
    var isEnabled: Bool
}

enum PasteAction: String, Codable {
    case uppercase
    case lowercase
    case titleCase
    case trim
    case removeSpaces
    case addPrefix
    case addSuffix
}

final class SmartPasteManager {
    static let shared = SmartPasteManager()

    private let rulesKey = "smartPasteRules"

    private init() {}

    func fetchRules() -> [SmartPasteRule] {
        guard let data = UserDefaults.standard.data(forKey: rulesKey) else { return [] }
        do {
            return try JSONDecoder().decode([SmartPasteRule].self, from: data)
        } catch {
            return []
        }
    }

    func saveRule(_ rule: SmartPasteRule) {
        var rules = fetchRules()
        if let index = rules.firstIndex(where: { $0.id == rule.id }) {
            rules[index] = rule
        } else {
            rules.append(rule)
        }
        saveRules(rules)
    }

    func deleteRule(_ id: UUID) {
        var rules = fetchRules()
        rules.removeAll { $0.id == id }
        saveRules(rules)
    }

    func applyRules(to text: String) -> String {
        var result = text
        for rule in fetchRules().filter({ $0.isEnabled }) {
            result = applyAction(rule.action, to: result, rule: rule)
        }
        return result
    }

    private func applyAction(_ action: PasteAction, to text: String, rule: SmartPasteRule) -> String {
        switch action {
        case .uppercase:
            return text.uppercased()
        case .lowercase:
            return text.lowercased()
        case .titleCase:
            return text.capitalized
        case .trim:
            return text.trimmingCharacters(in: .whitespacesAndNewlines)
        case .removeSpaces:
            return text.replacingOccurrences(of: " ", with: "")
        case .addPrefix:
            return "\(rule.trigger)\(text)"
        case .addSuffix:
            return "\(text)\(rule.trigger)"
        }
    }

    private func saveRules(_ rules: [SmartPasteRule]) {
        do {
            let data = try JSONEncoder().encode(rules)
            UserDefaults.standard.set(data, forKey: rulesKey)
        } catch {
            print("Failed to save smart paste rules: \(error)")
        }
    }
}
