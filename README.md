# DBXCResultParser-Sonar

`DBXCResultParser-Sonar` is a Swift Package Manager tool designed to convert Xcode's test result files (`.xcresult`) into Sonar Generic Test Execution Report format (`.xml`). It can be integrated into your CI/CD pipeline to enhance the visibility of test results in SonarQube or SonarCloud.

## Installation

### As a Dependency

To use `DBXCResultParser-Sonar` as a dependency in your project, add it to the dependencies in your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/dodobrands/DBXCResultParser-Sonar.git", from: "1.0.0")
]
```

Then import `DBXCResultParser-Sonar` in your Swift files where you want to use it:

```swift
import DBXCResultParserSonar
```

### As a Command Line Tool

You can use `DBXCResultParser-Sonar` as a command line tool in two ways:

1. **Prebuilt Binary from Xcode Archive**:
   Download the prebuilt binary from the [Releases](https://github.com/dodobrands/DBXCResultParser-Sonar/releases) page on the project's GitHub repository.

2. **Using Swift Run**:
   Clone the repository and run the tool using the Swift Package Manager:

   ```bash
   git clone https://github.com/dodobrands/DBXCResultParser-Sonar.git
   cd DBXCResultParser-Sonar
   swift run DBXCResultParser-Sonar <arguments>
   ```

## Usage

### As a Dependency

Create an instance of `SonarGenericTestExecutionReportFormatter` and use it to generate the `.xml` report:

```swift
let formatter = SonarGenericTestExecutionReportFormatter()
// Use formatter to generate the report
```

### As a Command Line Tool

To generate a Sonar Generic Test Execution Report from the command line, use the following command:

```bash
swift run DBXCResultParser-Sonar --xcresult-path path/to/tests.xcresult --tests-path path/to/test-files > report.xml
```

Replace `path/to/tests.xcresult` with the path to your `.xcresult` file and `path/to/test-files` with the path to your test files.

## Contributing

Contributions are welcome! Please feel free to submit a pull request or open an issue on the [GitHub repository](https://github.com/dodobrands/DBXCResultParser-Sonar).

## License

This project is licensed under the Apache License - see the [LICENSE](LICENSE) file for details.
```