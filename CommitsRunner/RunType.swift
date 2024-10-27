//
//  RunType.swift
//  CommitsRunner
//
//  Created by José María Jiménez on 22/10/24.
//

import Foundation

enum RunType {
    case validatePRtitle(_ firstWord: String)
    case updateVersion(branch: String)

    static func getRunType() -> RunType {
        let arguments = CommandLine.arguments
        guard arguments.count > 1 else { exit(1) }
        switch arguments[1] {
        case "validate": return .validatePRtitle(arguments[2])
        case "update": return .updateVersion(branch: arguments[2])
        default: exit(1)
        }
    }

    func run() async {
        switch self {
        case .validatePRtitle(let firstWord):
            print("Received title: \(firstWord)")
            let matches = ["MAJOR", "MINOR", "PATCH"].filter {
                firstWord.starts(with: $0)
            }
            guard matches.count > 0 else {
                print("PR title must start with [MAJOR, MINOR, PATCH]")
                exit(1)
            }
        case .updateVersion(let branch):
            if CommandLine.arguments.count > 3 {
                ZSH.appendCommand = "cd CommitsRunner;"
            }
            print("Checking out \(branch)...")
            try! await ZSH.run(command: "git checkout \(branch)")
            print("Pulling \(branch)...")
            try! await ZSH.run(command: "git pull")
            guard let output = try! await ZSH.run(command: "git tag") else {
                print("No tags found. Creating 0.0.1")
                try! await ZSH.run(command: "git tag 0.0.1")
                try! await ZSH.run(command: "git push origin 0.0.1")
                return
            }
            let split = output.split(separator: "\n").last?.split(separator: ".")
            guard let split,
                  split.count == 3,
                  var major = Int(split[0]),
                  var minor = Int(split[1]),
                  var patch = Int(split[2]) else {
                print("Invalid tag... skipping")
                exit(0)
            }
            let message = try! await ZSH.run(command: "git log -1 --pretty=%B")
            let matches = ["MAJOR", "MINOR", "PATCH"].filter { message?.starts(with: $0) ?? false }
            guard !matches.isEmpty else {
                print("Incorrect commit message... Skipping")
                exit(0)
            }
            switch matches[0] {
            case "MAJOR":
                major += 1
                minor = 0
                patch = 0
            case "MINOR":
                minor += 1
                patch = 0
            default: patch += 1
            }
            let newTag = "\(major).\(minor).\(patch)"
            print("Pushing new tag \(newTag)")
            try! await ZSH.run(command: "git tag \(newTag)")
            try! await ZSH.run(command: "git push origin \(newTag)")
        }
    }
}
