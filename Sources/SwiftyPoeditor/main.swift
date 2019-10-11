import Foundation
import ConsoleKit

let console: Console = Terminal()
var input = CommandInput(arguments: CommandLine.arguments)

// creating of CLI command handlers and binding them to CLI
var config = CommandConfiguration()
config.use(UploadCommand(), as: "upload", isDefault: true)
config.use(DownloadCommand(), as: "download")

do {
    // start CLI commands handler
    let commands = try config.resolve()
        .group(help: "PoeditorI18n - command line tool to sync local translations with remote on POEditor service")
    try console.run(commands, input: input)
} catch {
    console.error("Error: \(error.localizedDescription)")
    exit(1)
}
