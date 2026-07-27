import Darwin
import Foundation

@main
struct CodexThemeAgentMain {
    @MainActor
    static func main() async {
        let arguments = Array(CommandLine.arguments.dropFirst())
        let standardInput: Data
        if CodexThemeAgentCLI.requiresStandardInput(arguments: arguments) {
            standardInput = (
                try? FileHandle.standardInput.read(
                    upToCount: CodexThemeAgentCLI.maximumInputBytes + 1
                )
            ) ?? Data()
        } else {
            standardInput = Data()
        }

        let execution = await CodexThemeAgentCLI().run(
            arguments: arguments,
            standardInput: standardInput
        )
        if !execution.standardOutput.isEmpty {
            FileHandle.standardOutput.write(execution.standardOutput)
        }
        if !execution.standardError.isEmpty {
            FileHandle.standardError.write(execution.standardError)
        }
        exit(execution.exitCode)
    }
}
