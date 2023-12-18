//
//  SonarGenericTestExecutionReportFormatter.swift
//  
//
//  Created by Aleksey Berezka on 15.12.2023.
//

import Foundation
import DBXCResultParser
import XMLCoder
import DBThreadSafe
import ArgumentParser

@main
public class SonarGenericTestExecutionReportFormatter: ParsableCommand {
    required public init() { }
    
    @Option(help: "Path to .xcresult")
    public var xcresultPath: String
    
    @Option(help: "Path to folder with tests")
    public var testsPath: String
    
    public func run() throws {
        let xcresultPath = URL(fileURLWithPath: xcresultPath)
        
        let report = try DBXCReportModel(xcresultPath: xcresultPath)
        let result = try sonarTestReport(from: report)
        print(result)
    }
    
    public func sonarTestReport(from report: DBXCReportModel) throws -> String {
        let testsPath = URL(fileURLWithPath: testsPath)
        
        let sonarFiles = try report
            .modules
            .flatMap { $0.files }
            .sorted { $0.name < $1.name }
            .concurrentMap { try testExecutions.file($0, testsPath: testsPath) }
        
        let dto = testExecutions(file: sonarFiles)
        
        let encoder = XMLEncoder()
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(dto)
        return String(decoding: data, as: UTF8.self)
    }
}

fileprivate struct testExecutions: Encodable, DynamicNodeEncoding {
    let version = 1
    let file: [file]
    
    static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
        switch key {
        case Self.CodingKeys.version: 
            return .attribute
        default: 
            return .element
        }
    }
    
    struct file: Encodable, DynamicNodeEncoding {
        let path: String
        let testCase: [testCase]
        
        static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
            switch key {
            case Self.CodingKeys.path: 
                return .attribute
            default: 
                return .element
            }
        }
        
        struct testCase: Encodable, DynamicNodeEncoding {
            let name: String
            let duration: Int
            let skipped: skipped?
            let failure: failure?
            
            static func nodeEncoding(for key: CodingKey) -> XMLEncoder.NodeEncoding {
                switch key {
                case 
                    Self.CodingKeys.name,
                    Self.CodingKeys.duration: 
                    return .attribute
                default: 
                    return .element
                }
            }
            
            struct skipped: Encodable { }
            struct failure: Encodable { }
        }
    }
}

extension testExecutions.file.testCase {
    init(_ test: DBXCReportModel.Module.File.RepeatableTest) {
        self.init(
            name: test.name, 
            duration: Int(test.totalDuration.converted(to: .milliseconds).value),
            skipped: test.combinedStatus == .skipped ? .init() : nil,
            failure: test.combinedStatus == .failure ? .init() : nil
        )
    }
}

extension testExecutions.file {
    init(_ file: DBXCReportModel.Module.File, testsPath: URL) throws {
        let testCases = file.repeatableTests
            .sorted { $0.name < $1.name }
            .map { testExecutions.file.testCase.init($0) }
        
        let path = try Self.path(toFileWithClass: file.name, in: testsPath)
        
        self.init(
            path: path,
            testCase: testCases
        )
    }
    
    private static func path(toFileWithClass className: String, in path: URL) throws -> String {
        let testsPath = path.relativePath
        let command = "find \(testsPath) -name '*.swift' -exec grep -l '\(className)' {} + | head -n 1"
        let absouluteFilePath = try DBShell.execute(command)
        let relativeFilePath = absouluteFilePath.replacingOccurrences(of: testsPath, with: ".")
        return relativeFilePath
    }
}

extension Sequence {
    func concurrentMap<T>(_ transform: @escaping (Self.Element) throws -> T) rethrows -> [T] {
        let elements = Array(self)
        let results = DBThreadSafeContainer(Array<T?>(repeating: nil, count: elements.count))
        
        DispatchQueue.concurrentPerform(iterations: elements.count) { index in
            let transformed = try? transform(elements[index])
            results.write { $0[index] = transformed }
        }
        
        return results.read().compactMap { $0 }
    }
}
