import Foundation
import XCTest
@testable import CodexThemeRuntime

final class RuntimeLocatorTests: XCTestCase {
    private func makeTemporaryDirectory() throws -> URL {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(
                "CodexThemeRuntimeTests-\(UUID().uuidString)",
                isDirectory: true
            )
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        addTeardownBlock {
            try? FileManager.default.removeItem(at: url)
        }
        return url
    }

    @discardableResult
    private func makeExecutable(at url: URL) throws -> URL {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        XCTAssertTrue(
            FileManager.default.createFile(
                atPath: url.path,
                contents: Data("#!/bin/sh\nexit 0\n".utf8)
            )
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: url.path
        )
        return url
    }

    func testHelperScriptCanBeLocatedAndExists() throws {
        let helper = try RuntimeLocator.helperScriptURL()
        XCTAssertTrue(FileManager.default.fileExists(atPath: helper.path))
        XCTAssertEqual(helper.lastPathComponent, "cli.js")
        XCTAssertEqual(
            helper.deletingLastPathComponent().lastPathComponent,
            "runtime"
        )
    }

    func testDefaultUserRootUsesDedicatedApplicationSupportDirectory() {
        let expected = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(
                "Library/Application Support/CodexThemeSwitcher",
                isDirectory: true
            )
        XCTAssertEqual(
            RuntimeLocator.defaultUserRoot.standardizedFileURL,
            expected.standardizedFileURL
        )
    }

    func testBundledNodeHasPriorityOverCuaAndPathFallbacks() throws {
        let root = try makeTemporaryDirectory()
        let app = root.appendingPathComponent("Codex.app", isDirectory: true)
        let bundled = try makeExecutable(
            at: app.appendingPathComponent("Contents/Resources/node")
        )
        _ = try makeExecutable(
            at: app.appendingPathComponent("Contents/Resources/cua_node/bin/node")
        )
        let pathDirectory = root.appendingPathComponent("path-bin")
        _ = try makeExecutable(at: pathDirectory.appendingPathComponent("node"))

        let resolved = RuntimeLocator.defaultNodeExecutable(
            codexApp: app,
            environment: ["PATH": pathDirectory.path]
        )

        XCTAssertEqual(resolved?.standardizedFileURL, bundled.standardizedFileURL)
    }

    func testCuaNodeIsUsedWhenPrimaryBundledNodeIsNotExecutable() throws {
        let root = try makeTemporaryDirectory()
        let app = root.appendingPathComponent("Codex.app", isDirectory: true)
        let primary = app.appendingPathComponent("Contents/Resources/node")
        try FileManager.default.createDirectory(
            at: primary.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        XCTAssertTrue(
            FileManager.default.createFile(
                atPath: primary.path,
                contents: Data()
            )
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: primary.path
        )
        let cua = try makeExecutable(
            at: app.appendingPathComponent("Contents/Resources/cua_node/bin/node")
        )

        let resolved = RuntimeLocator.defaultNodeExecutable(
            codexApp: app,
            environment: [:]
        )

        XCTAssertEqual(resolved?.standardizedFileURL, cua.standardizedFileURL)
    }

    func testPathFallbackHonorsDirectoryOrderAndExecutableBit() throws {
        let root = try makeTemporaryDirectory()
        let app = root.appendingPathComponent("Missing.app", isDirectory: true)
        let firstDirectory = root.appendingPathComponent("first")
        let firstNode = firstDirectory.appendingPathComponent("node")
        try FileManager.default.createDirectory(
            at: firstDirectory,
            withIntermediateDirectories: true
        )
        XCTAssertTrue(
            FileManager.default.createFile(
                atPath: firstNode.path,
                contents: Data()
            )
        )
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o600],
            ofItemAtPath: firstNode.path
        )
        let secondDirectory = root.appendingPathComponent("second")
        let secondNode = try makeExecutable(
            at: secondDirectory.appendingPathComponent("node")
        )
        let thirdDirectory = root.appendingPathComponent("third")
        _ = try makeExecutable(
            at: thirdDirectory.appendingPathComponent("node")
        )

        let resolved = RuntimeLocator.defaultNodeExecutable(
            codexApp: app,
            environment: [
                "PATH": [
                    firstDirectory.path,
                    secondDirectory.path,
                    thirdDirectory.path
                ].joined(separator: ":")
            ]
        )

        XCTAssertEqual(
            resolved?.standardizedFileURL,
            secondNode.standardizedFileURL
        )
    }

    func testLocationErrorsHaveActionableDescriptions() {
        XCTAssertEqual(
            RuntimeLocationError.missingHelper.errorDescription,
            "Bundled Codex Theme runtime helper was not found."
        )
        XCTAssertEqual(
            RuntimeLocationError.missingNode.errorDescription,
            "A compatible Node.js runtime was not found."
        )
    }
}
