//
//  RawMode.swift
//  
//
//  Created by syan on 03/02/2023.
//

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

// https://gist.github.com/dduan/272d8c20bb6521695bd04e290b489774

enum RawModeError: Error {
    case notATerminal
    case failedToGetTerminalSetting
    case failedToSetTerminalSetting
}

func runInRawMode(fd: Int32 = STDIN_FILENO, clearScreen: Bool = false, _ task: @escaping () throws -> Void) throws {
    var originalTermSetting = termios()
    guard isatty(fd) != 0 else {
        throw RawModeError.notATerminal
    }

    guard tcgetattr(fd, &originalTermSetting) >= 0 else {
        throw RawModeError.failedToGetTerminalSetting
    }


    var raw = originalTermSetting
    cfmakeraw(&raw)
    /*
    raw.c_iflag &= ~(UInt(BRKINT) | UInt(ICRNL) | UInt(INPCK) | UInt(ISTRIP) | UInt(IXON))
    raw.c_oflag &= ~(UInt(OPOST))
    raw.c_cflag |= UInt(CS8)
    raw.c_lflag &= ~(UInt(ECHO) | UInt(ICANON) | UInt(IEXTEN) | UInt(ISIG))
    raw.c_cc.16 = 0
    raw.c_cc.17 = 1
*/
    
    guard tcsetattr(fd, TCSAFLUSH, &raw) >= 0 else {
        throw RawModeError.failedToSetTerminalSetting
    }

    defer {
        tcsetattr(fd, TCSAFLUSH, &originalTermSetting)
    }

    if clearScreen {
        print("\u{1b}[2J")
    }

    try task()
}
