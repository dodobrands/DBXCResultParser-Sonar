//
//  File.swift
//  
//
//  Created by Aleksey Berezka on 20.05.2024.
//

import Foundation

struct FSIndex {
    let classes: [String: String]
    
    init(path: URL) throws {
        self.classes = try Self.classes(in: path)
    }
}

extension FSIndex {
    private static func classes(in path: URL) throws -> [String: String] {
        let fileManager = FileManager.default

        var classDictionary: [String: String] = [:]
        
        // Create a DirectoryEnumerator to recursively search for .swift files
        let enumerator = fileManager.enumerator(
            at: URL(fileURLWithPath: path.relativePath),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) { (url, error) -> Bool in
            DBLogger.logWarning("Directory enumeration error at \(url)")
            DBLogger.logWarning(error.localizedDescription)
            return true
        }
        
        // Regular expression to find class names
        let regex = try NSRegularExpression(pattern: "class\\s+([A-Za-z_][A-Za-z_0-9]*)", options: [])

        // Iterate over each file found by the enumerator
        while let element = enumerator?.nextObject() as? URL {
            let isFile = try element.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile ?? false
            guard isFile,
                  element.pathExtension == "swift" else {
                continue
            }
            
            let fileContent = try String(contentsOf: element, encoding: .utf8)

            // Search for class definitions
            let nsRange = NSRange(fileContent.startIndex..<fileContent.endIndex, in: fileContent)
            let matches = regex.matches(in: fileContent, options: [], range: nsRange)

            // Extract class names from the matches and store them in the dictionary
            for match in matches {
                if let range = Range(match.range(at: 1), in: fileContent) {
                    let className = String(fileContent[range])
                    let relativePath = try element.relativePath(from: path) ?! Error.cantGetRelativePath(filePath: element, basePath: path)
                    classDictionary[className] = relativePath
                }
            }
        }
        
        return classDictionary
    }
    
    enum Error: Swift.Error {
        case cantGetRelativePath(filePath: URL, basePath: URL)
    }
}
