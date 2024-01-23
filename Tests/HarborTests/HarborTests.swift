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
    
    func testCodable<T: Decodable>(type: T.Type) throws {
        for file in obtainFixtureFiles(path: String(describing: type)) {
            print(file.deletingLastPathComponent().lastPathComponent, ">", file.lastPathComponent)
            let data = try! Data(contentsOf: file)
            let decoder = JSONDecoder()
            _ = try decoder.decode([T].self, from: data)
        }
    }
    
    func testCodables() throws {
        try testCodable(type: DockerContainerInspect.self)
        try testCodable(type: DockerServiceInspect.self)
    }
}
