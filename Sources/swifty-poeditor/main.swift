import Foundation
import ConsoleKit

let console: Console = Terminal()
var input = CommandInput(arguments: CommandLine.arguments)

// creating of CLI command handlers and binding them to CLI
var context = CommandContext(console: console, input: input)
var commands = Commands(enableAutocomplete: true)

commands.use(UploadCommand(), as: "upload")
commands.use(DownloadCommand(), as: "download", isDefault: true)

do {
    // start CLI commands handler
    
    let group = commands.group(help: "SwiftyPoeditor - command line tool to sync local translations with remote on POEditor service")
    try console.run(group, input: input)
} catch {
    console.error("Error: \(error.localizedDescription)")
    exit(1)
}
