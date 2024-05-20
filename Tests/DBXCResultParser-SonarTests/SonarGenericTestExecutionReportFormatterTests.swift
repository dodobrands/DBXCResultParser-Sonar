//
//  SonarGenericTestExecutionReportFormatterTests.swift
//  
//
//  Created by Aleksey Berezka on 15.12.2023.
//

import Foundation
import XCTest
import DBXCResultParser
import DBXCResultParserTestHelpers
import DBXCResultParser_Sonar

class SonarGenericTestExecutionReportFormatterTests: XCTestCase {
    
    func setUp(for report: DBXCReportModel) throws {
        try createTestDir()
        try createTestFiles(for: report)
    }
    
    override func tearDownWithError() throws {
        try removeTestDir()
    }
    
    func test_sort() throws {
        let report = DBXCReportModel.testReport
        try setUp(for: report)
        
        let formatter = SonarGenericTestExecutionReportFormatter()
        formatter.testsPath = try testsURL.relativePath
        let result = try formatter.sonarTestReport(from: report)
        XCTAssertEqual(result, """
<testExecutions version="1">
    <file path="ClassName_a_a.swift">
        <testCase name="test_expecting_fail" duration="0" />
        <testCase name="test_failure" duration="0">
            <failure message="Failure message" />
        </testCase>
        <testCase name="test_mixedFailureAndSuccess" duration="0" />
        <testCase name="test_skipped" duration="0">
            <skipped message="Skip message" />
        </testCase>
        <testCase name="test_success" duration="0" />
    </file>
    <file path="ClassName_a_b.swift" />
    <file path="ClassName_a_c.swift" />
    <file path="ClassName_b_a.swift" />
    <file path="ClassName_b_b.swift" />
    <file path="ClassName_b_c.swift" />
    <file path="ClassName_c_a.swift" />
    <file path="ClassName_c_b.swift" />
    <file path="ClassName_c_c.swift" />
</testExecutions>
"""
        )
    }
    
    func test_large_report_performance() throws {
        let report = DBXCReportModel.largeReport(filesCount: 1000)
        try setUp(for: report)
        
        let formatter = SonarGenericTestExecutionReportFormatter()
        formatter.testsPath = try testsURL.relativePath
        let result = try formatter.sonarTestReport(from: report)
    }
}

extension DBXCReportModel {
    static var testReport: DBXCReportModel {
        // Module with all possible tests
        let module_a = DBXCReportModel.Module.testMake(
            name: "Module_a",
            files: [
                .testMake(
                    name: "ClassName_a_a",
                    repeatableTests: [
                        .failed(named: "test_failure", message: "Failure message"),
                        .succeeded(named: "test_success"),
                        .mixedFailedSucceeded(named: "test_mixedFailureAndSuccess"),
                        .skipped(named: "test_skipped", message: "Skip message"),
                        .expectedFailed(named: "test_expecting_fail", message: "Failure message")
                    ]
                ),
                .testMake(
                    name: "ClassName_a_b"
                ),
                .testMake(
                    name: "ClassName_a_c"
                )
            ]
        )
        
        let module_b = DBXCReportModel.Module.testMake(
            name: "Module_b",
            files: [
                .testMake(
                    name: "ClassName_b_a"
                ),
                .testMake(
                    name: "ClassName_b_b"
                ),
                .testMake(
                    name: "ClassName_b_c"
                )
            ]
        )
        
        let module_c = DBXCReportModel.Module.testMake(
            name: "Module_c",
            files: [
                .testMake(
                    name: "ClassName_c_a"
                ),
                .testMake(
                    name: "ClassName_c_b"
                ),
                .testMake(
                    name: "ClassName_c_c"
                )
            ]
        )
        
        return .testMake(
            modules: [
                module_a,
                module_b,
                module_c
            ]
        )
    }
    
    static func largeReport(filesCount: Int) -> DBXCReportModel {
        let files = Array(0...filesCount).map {
            DBXCReportModel.Module.File.testMake(name: "TestClass_\($0)")
        }

        let module = DBXCReportModel.Module.testMake(
            name: "Module",
            files: files.toSet
        )
        
        return .testMake(
            modules: [
                module
            ]
        )
    }
}

extension Array where Element: Hashable {
    var toSet: Set<Element> {
        Set(self)
    }
}

extension SonarGenericTestExecutionReportFormatterTests {
    var testsURL: URL {
        get throws {
            try XCTUnwrap(FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first?.appending(path: "io.dodobrands.\(packageName())"))
        }
    }
    
    func createTestDir() throws {
        try FileManager.default.createDirectory(at: testsURL, withIntermediateDirectories: false)
    }
    
    func createTestFiles(for report: DBXCReportModel) throws {
        let path = try testsURL.relativePath
        
        report.modules.flatMap { $0.files }.concurrentForEach {
            let command = "cd \(path) && echo 'class \($0.name) { }' > \($0.name).swift"
            _ = try? DBShell.execute(command)
        }
    }
    
    func removeTestDir() throws {
        try FileManager.default.removeItem(at: testsURL)
    }
    
    func packageName(fileID: StaticString = #fileID) throws -> String {
        String(try XCTUnwrap(fileID.description.split(separator: "/").first))
    }
}

extension Sequence {
    func concurrentForEach(_ body: @escaping (Element) -> Void) {
        let group = DispatchGroup()
        
        for element in self {
            DispatchQueue.global().async(group: group) {
                body(element)
            }
        }
        
        group.wait() // Wait for all tasks to complete
    }
}
