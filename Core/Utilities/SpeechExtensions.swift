import Foundation

extension String {
    public var expandedForSpeech: String {
        var spokenText = self.replacingOccurrences(of: "_", with: " ")
        
        let boundaryReplacements: [String: String] = [
            "LVL": "Level",
            "SIM": "Simulation",
            "INIT": "Initialization",
            "CALC": "Calculation",
            "EXP": "Experience",
            "VEL": "Velocity",
            "ACC": "Acceleration",
            "DST": "Distance",
            "EQN": "Equation",
            "PROB": "Probability",
            "VAR": "Variable",
            "VARS": "Variables",
            "SUB": "Subtopic",
            "v0": "v naught",
            "v₀": "v naught"
        ]
        
        for (short, full) in boundaryReplacements {
            spokenText = spokenText.replacingOccurrences(of: "\\b\(short)\\b", with: full, options: [.regularExpression, .caseInsensitive])
        }
        
        let exactReplacements: [String: String] = [
            "V INIT": "Initial Velocity",
            "v₀": "v naught",
            "m/s²": "meters per second squared",
            "m/s": "meters per second"
        ]
        
        for (short, full) in exactReplacements {
            spokenText = spokenText.replacingOccurrences(of: short, with: full, options: [.caseInsensitive])
        }
        
        return spokenText
    }
}
