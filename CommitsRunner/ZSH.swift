//
//  ZSH.swift
//  CommitsRunner
//
//  Created by José María Jiménez on 22/10/24.
//
import Foundation

struct ZSH {

    static var appendCommand = ""

    @discardableResult
    static func run(command: String) async throws -> String? {
        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", "\(appendCommand) \(command);"]

        let status = try await withCheckedThrowingContinuation { continuation in
            do {
                try process.run()
                process.waitUntilExit()
                continuation.resume(returning: process.terminationStatus)
            } catch {
                continuation.resume(throwing: CocoaError(.coderInvalidValue))
            }
        }

        guard status == 0 else { exit(1) }
        guard let data = try? pipe.fileHandleForReading.readToEnd() else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
