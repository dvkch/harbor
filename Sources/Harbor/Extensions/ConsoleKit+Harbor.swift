//
//  ConsoleKit+Harbor.swift
//  
//
//  Created by syan on 22/02/2023.
//

import Foundation
import ConsoleKit

extension Terminal {
    private func setupRawMode(fd: Int32) -> termios? {
        var originalTermSetting = termios()
        guard isatty(fd) != 0 else {
            return nil
        }

        guard tcgetattr(fd, &originalTermSetting) >= 0 else {
            return nil
        }

        var raw = originalTermSetting
        cfmakeraw(&raw)
        
        guard tcsetattr(fd, TCSAFLUSH, &raw) >= 0 else {
            return nil
        }

        return originalTermSetting
    }
    
    private func runInRawMode<T>(fd: Int32, _ task: @escaping () throws -> T) rethrows -> T {
        let originalTermSetting = setupRawMode(fd: fd)
        defer {
            if var originalTermSetting {
                tcsetattr(fd, TCSAFLUSH, &originalTermSetting)
            }
        }

        return try task()
    }

    func getKeyPress() -> [UInt8] {
        return runInRawMode(fd: FileHandle.standardInput.fileDescriptor) {
            var bytes: [UInt8] = .init(repeating: 0, count: 32)
            bytes.withUnsafeMutableBytes { mutableBytes in
                _ = read(FileHandle.standardInput.fileDescriptor, mutableBytes.baseAddress, 10)
            }
            return bytes
        }
    }
    
    func numberOfLines(for string: String) -> Int {
        return string.count / size.width + 1
    }
    
    func showOptions<T>(title: String, options: [T], display: (T) -> String) -> T {
        // Validate input
        guard options.isNotEmpty else {
            fatalError("Showing an empty list of options")
        }
        let optionNames = options.map { display($0) }

        // Define drawing methods
        func clearOptions() {
            let terminalWidth = size.width
            let printedLines = optionNames.map { $0.countTerminalLines(width: terminalWidth) }.reduce(0, +)
            clear(lines: printedLines)
        }
        func drawOptions(selected: Int) {
            optionNames.enumerated().forEach { i, optionName in
                if selected == i {
                    output("‣ " + optionName, style: .init(color: .green))
                }
                else {
                    output("  " + optionName, style: .plain)
                }
            }
        }
        
        // Initial screen
        var selected = 0
        output("\(title)", newLine: true)
        drawOptions(selected: selected)
        
        // Runloop
        while true {
            let keys = getKeyPress()
            if keys[0] == 27 && keys[1] == 91 {
                // UP
                if keys[2] == 65 {
                    selected -= 1
                }
                // DOWN
                if keys[2] == 66 {
                    selected += 1
                }
                selected = max(0, selected)
                selected = min(selected, options.count - 1)

                clearOptions()
                drawOptions(selected: selected)
            }
            else if keys[0] == 13 {
                // ENTER
                clearOptions()
                clear(lines: title.countTerminalLines(width: size.width))
                output("\(title) ", newLine: false)
                output(optionNames[selected], style: .init(color: .green))
                return options[selected]
            }
            else if keys[0] == 3 {
                // CTRL + C
                exit(0)
            }
        }
        fatalError("Should never reach here")
    }
}

private extension String {
    func countTerminalLines(width: Int) -> Int {
        return count / width + 1
    }
}
