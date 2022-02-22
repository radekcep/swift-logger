//
//  FileLoggerTests.swift
//  
//
//  Created by Martin Troup on 30.09.2021.
//

@testable import Logger
import XCTest

class FileLoggerTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var fileManager: FileManager!
    private var fileLoggerManager: FileLoggerManager!

    override func setUp() {
        super.setUp()

        userDefaults = UserDefaults(suiteName: "testUserDefaults")!
        fileManager = FileManager.default
        fileLoggerManager = try! FileLoggerManager(
            fileManager: fileManager,
            userDefaults: userDefaults,
            dateFormatter: DateFormatter.dateTimeFormatter,
            numberOfLogFiles: 3
        )
    }

    override func tearDown() {
        try! FileManager.default.removeItem(atPath: fileLoggerManager.logDirURL.path)
        fileLoggerManager = nil

        userDefaults.removePersistentDomain(forName: "testUserDefaults")
        userDefaults = nil

        fileManager = nil

        super.tearDown()
    }

    func test_inicialization_of_FileLogger() {
        XCTAssertTrue(fileManager.directoryExists(at: fileLoggerManager.logDirURL))
        XCTAssertEqual(try! fileManager.numberOfFiles(inDirectory: fileLoggerManager.logDirURL), 0)

        let currentLogFileNumber = userDefaults.object(forKey: Constants.UserDefaultsKeys.currentLogFileNumber) as? Int
        XCTAssertEqual(currentLogFileNumber, 0)

        let dateOfLastLog = userDefaults.object(forKey: Constants.UserDefaultsKeys.dateOfLastLog) as? Date
        XCTAssertNotNil(dateOfLastLog)

        let numberOfLogFiles = userDefaults.object(forKey: Constants.UserDefaultsKeys.numberOfLogFiles) as? Int
        XCTAssertEqual(numberOfLogFiles, 3)
    }

    func test_archive_availability() {
        let fileLogger = FileLogger(fileLoggerManager: fileLoggerManager)

        fileLogger.log(.mock("Error message"))
        fileLogger.log(.mock("Warning message"))

        // Archived log files check
        let archiveUrl = fileLogger.getArchivedLogFilesUrl()
        XCTAssertNotNil(archiveUrl)
        XCTAssertTrue(try! archiveUrl!.checkResourceIsReachable())
        try! FileManager.default.removeItem(at: archiveUrl!)
    }

    func test_file_rotation() {
        let fileLogger = FileLogger(fileLoggerManager: fileLoggerManager)

        // Day 1 == File 0
        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLoggerManager.currentLogFileNumber, 0)
        XCTAssertEqual(
            fileLoggerManager.currentLogFileUrl,
            fileLoggerManager.logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )

        // Day 2 == File 1
        fileLoggerManager.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLoggerManager.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLoggerManager.currentLogFileNumber, 1)
        XCTAssertEqual(
            fileLoggerManager.currentLogFileUrl,
            fileLoggerManager.logDirURL.appendingPathComponent("1").appendingPathExtension("log")
        )

        // Day 3 == File 2
        fileLoggerManager.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLoggerManager.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLoggerManager.currentLogFileNumber, 2)
        XCTAssertEqual(
            fileLoggerManager.currentLogFileUrl,
            fileLoggerManager.logDirURL.appendingPathComponent("2").appendingPathExtension("log")
        )

       // Day 4 == File 0
        fileLoggerManager.dateOfLastLog = Calendar.current.date(byAdding: .day, value: 1, to: fileLoggerManager.dateOfLastLog)!

        fileLogger.log(.mock("Warning message"))

        XCTAssertEqual(fileLoggerManager.currentLogFileNumber, 0)
        XCTAssertEqual(
            fileLoggerManager.currentLogFileUrl,
            fileLoggerManager.logDirURL.appendingPathComponent("0").appendingPathExtension("log")
        )

        XCTAssertEqual(try! fileManager.numberOfFiles(inDirectory: fileLoggerManager.logDirURL), 3)
    }

    func test_single_logging_file() {
        let fileLogger = FileLogger(fileLoggerManager: fileLoggerManager)
        fileLogger.levels = [.error, .warn]

        let date = Date(timeIntervalSince1970: 0)

        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "file", function: "function", line: 1),
                message: "Error message"
            )
        )

        fileLogger.log(
            .init(
                header: .init(date: date, level: .info, dateFormatter: DateFormatter.dateTimeFormatter),
                location: .init(fileName: "file2", function: "function2", line: 20),
                message: "Warning message\nThis is test!"
            )
        )

        let fileLogs = try! fileLoggerManager.gettingRecordsFromLogFile(at: fileLoggerManager.currentLogFileUrl)

        XCTAssertEqual(fileLogs.count, 2)

        XCTAssertEqual(fileLogs[0].header.level, .info)
        XCTAssertEqual(fileLogs[0].header.date, date)
        XCTAssertEqual(fileLogs[0].location.fileName, "file")
        XCTAssertEqual(fileLogs[0].location.function, "function")
        XCTAssertEqual(fileLogs[0].location.line, 1)
        XCTAssertEqual(fileLogs[0].body, "Error message")

        XCTAssertEqual(fileLogs[1].header.level, .info)
        XCTAssertEqual(fileLogs[1].header.date, date)
        XCTAssertEqual(fileLogs[1].location.fileName, "file2")
        XCTAssertEqual(fileLogs[1].location.function, "function2")
        XCTAssertEqual(fileLogs[1].location.line, 20)
        XCTAssertEqual(fileLogs[1].body, "Warning message\nThis is test!")
    }
}

// MARK: - FileManager + helper functions

private extension FileManager {
    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return fileExists(atPath: url.path, isDirectory: &isDirectory)
    }

    func numberOfFiles(inDirectory url: URL) throws -> Int {
        try contentsOfDirectory(atPath: url.path).count
    }
}
