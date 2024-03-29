import XCTest
@testable import Harbor

final class HarborTests: XCTestCase {
    func obtainFixtureFiles(path: String) -> [URL] {
        let url = Bundle(for: HarborTests.self)
            .resourceURL!
            .appendingPathComponent("Harbor_HarborTests.bundle/Contents/Resources/Fixtures", isDirectory: true)
            .appendingPathComponent(path, isDirectory: true)
            .absoluteURL
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        
        let files = try! FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: [],
            options: [.skipsHiddenFiles, .skipsPackageDescendants, .skipsSubdirectoryDescendants]
        ).filter { $0.pathExtension == "json" }
        return files
    }
    
    func testCodable<T: Decodable>(folder: String, type: T.Type) throws {
        for file in obtainFixtureFiles(path: folder) {
            print(file.deletingLastPathComponent().lastPathComponent, ">", file.lastPathComponent)
            let data = try! Data(contentsOf: file)
            let decoder = JSONDecoder()
            _ = try decoder.decode(T.self, from: data)
        }
    }
    
    func testCodables() throws {
        try testCodable(folder: "DockerContainer", type: [DockerContainer].self)
        try testCodable(folder: "DockerService", type: [DockerService].self)
        try testCodable(folder: "KubernetesDeployments", type: KubernetesList<KubernetesDeployment>.self)
        try testCodable(folder: "HerokuApp", type: [HerokuApp].self)
        try testCodable(folder: "HerokuAddon", type: [HerokuAddon].self)
        try testCodable(folder: "HerokuDyno", type: [HerokuDyno].self)
    }
}

class HarborRunTests: XCTestCase {
    static let tempDir: URL = {
        let url = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }()
    
    override class func setUp() {
        FileManager.default.changeCurrentDirectoryPath(tempDir.path)
    }
    
    var args: [String] {
        return []
    }

    func testRun() throws {
        guard args.isNotEmpty else { return }

        print("-------------------------------------------------------------------------")
        print("Testing args:", args)
        Harbor.main(args)
        try validateRun()
        print("")
    }
    
    func validateRun() throws {
    }
}

class HarborSwarmStatsTests: HarborRunTests {
    override var args: [String] {
        return ["stats", "vps", "--no-stream"]
    }
}

class HarborSwarmExecTests: HarborRunTests {
    override var args: [String] {
        return  ["exec", "vps", "hapier_app", "rails db:migrate"]
    }
}

class HarborSwarmLogsTests: HarborRunTests {
    override var args: [String] {
        return ["logs", "vps", "hapier_app", "--no-stream"]
    }
}

class HarborSwarmReloadTests: HarborRunTests {
    override var args: [String] {
        return ["reload", "vps", "ota_app"]
    }
}

class HarborSwarmDbBackupTests: HarborRunTests {
    override var args: [String] {
        return ["db-backup", "vps", "hapier_db", "hapier.dump"]
    }
    
    override func validateRun() throws {
        let dumpFile = type(of: self).tempDir.appending(path: "hapier.dump")
        XCTAssert(FileManager.default.fileExists(atPath: dumpFile.path))
        
        let outputFile = type(of: self).tempDir.appending(path: "hapier.sql")
        
        let dump = Process()
        dump.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        dump.arguments = ["pg_restore", dumpFile.path, "-f", outputFile.path]
        try dump.run()
        dump.waitUntilExit()
        
        let sql = try! String(contentsOf: outputFile).components(separatedBy: .newlines)
        XCTAssert(sql.count > 3)
        XCTAssert(sql[0] == "--")
        XCTAssert(sql[1] == "-- PostgreSQL database dump")
        XCTAssert(sql[2] == "--")
    }
}

class HarborK3sStatsTests: HarborRunTests {
    override var args: [String] {
        return ["stats", "nas", "--no-stream"]
    }
}

class HarborK3sExecTests: HarborRunTests {
    override var args: [String] {
        return  ["exec", "nas", "plex", "/bin/sh -c 'echo test'"]
    }
}

class HarborK3sLogsTests: HarborRunTests {
    override var args: [String] {
        return ["logs", "nas", "plex", "--no-stream"]
    }
}

class HarborK3sReloadTests: HarborRunTests {
    override var args: [String] {
        return ["reload", "nas", "sane"]
    }
}
