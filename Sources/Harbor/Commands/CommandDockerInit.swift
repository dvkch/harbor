//
//  CommandDockerInit.swift
//
//
//  Created by syan on 16/02/2023.
//

import Foundation
import ArgumentParser

struct CommandDockerInit: ParsableCommand, RuntimeAvailability {
    static var configuration = CommandConfiguration(
        commandName: "docker-init",
        abstract: "Create default files for Docker deployment"
    )
    
    static var isAvailable: Bool {
        return Bundle.moduleBundleAvailable
    }
    
    @Argument(help: "Service name")
    var slug: String
    
    mutating func run() throws {
        self.slug = slug.slugified
        print("Preparing Docker config for \(slug)")

        let projectKind = Prompt.choice("Select your project kind", options: ProjectKind.self)
        print("")

        var params: [ProjectKind.Param: String] = [:]
        params[.init(name: "SLUG", description: "Service name")] = slug
        
        projectKind.autogeneratedParams.forEach { param, value in
            params[param] = value
        }

        print("Please fill out the following template variables:")
        projectKind.requiredParams.forEach { param in
            params[param] = Prompt.input("\(param.description):", default: param.default)
        }
        print("")

        let files = projectKind.fileList
        print("Will now write the following files:")
        files.forEach { print("    \($0.destination)") }
        print("")

        print("With the following parameters:")
        params.forEach { print("    \($0.description): \($1)") }
        print("")
        
        try writeFiles(files: files, params: params)
        finalNotes(checklist: projectKind.checklist)
    }
}


// MARK: Inner workings
fileprivate extension CommandDockerInit {
    func writeFiles(files: [ProjectKind.TemplateFile], params: [ProjectKind.Param: String]) throws {
        let destinationFolderURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)

        try files.forEach { file in
            let destinationURL = destinationFolderURL.appendingPathComponent(file.destination)
            if destinationURL.exists && !Prompt.confirm("\(file.destination) already exists, overwrite?") {
                return
            }
            
            var content = try String(contentsOf: file.sourceURL)
            params.forEach { content = content.replacingOccurrences(of: "|\($0.name)|", with: $1) }
            try content.write(to: destinationURL, atomically: true, encoding: .utf8)
        }
        
        print("")
    }
    
    func finalNotes(checklist: [String]) {
        print("Your Docker config has been created")
        print("")
        print("Here is a checklist for your next steps:")
        checklist.forEach { print("    \($0)") }
   }
}

