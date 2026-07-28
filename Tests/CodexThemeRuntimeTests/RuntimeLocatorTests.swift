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

    private func makeCodexApp(at url: URL) throws -> URL {
        let executableName = "Codex"
        _ = try makeExecutable(
            at: url.appendingPathComponent(
                "Contents/MacOS/\(executableName)"
            )
        )
        let info: [String: Any] = [
            "CFBundleExecutable": executableName,
            "CFBundleIdentifier": RuntimeLocator.codexBundleIdentifier,
            "CFBundleName": "Codex",
            "CFBundlePackageType": "APPL"
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try data.write(
            to: url.appendingPathComponent("Contents/Info.plist")
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

    func testResolverHonorsSavedRunningRegisteredAndKnownOrder() {
        let root = FileManager.default.temporaryDirectory
        let saved = root.appendingPathComponent("Saved.app")
        let running = root.appendingPathComponent("Running.app")
        let registered = root.appendingPathComponent("Registered.app")
        let known = root.appendingPathComponent("Known.app")
        let validPaths = Set([
            saved.path,
            running.path,
            registered.path,
            known.path
        ])

        let resolved = RuntimeLocator.resolveCodexApp(
            persistedURL: saved,
            runningURLs: [running],
            registeredURL: registered,
            candidates: [known],
            validator: { validPaths.contains($0.path) }
        )
        XCTAssertEqual(resolved?.path, saved.path)

        let automatic = RuntimeLocator.resolveCodexApp(
            persistedURL: nil,
            runningURLs: [running],
            registeredURL: registered,
            candidates: [known],
            validator: { validPaths.contains($0.path) }
        )
        XCTAssertEqual(automatic?.path, running.path)

        let registeredFallback = RuntimeLocator.resolveCodexApp(
            persistedURL: nil,
            runningURLs: [root.appendingPathComponent("Invalid.app")],
            registeredURL: registered,
            candidates: [known],
            validator: { validPaths.contains($0.path) }
        )
        XCTAssertEqual(registeredFallback?.path, registered.path)
    }

    func testCustomCodexAppRoundTripsOutsideApplicationsDirectory() throws {
        let root = try makeTemporaryDirectory()
        let userRoot = root.appendingPathComponent("Theme Switcher Data")
        let app = try makeCodexApp(
            at: root.appendingPathComponent(
                "External Volume/Custom Codex Name.app"
            )
        )

        XCTAssertTrue(RuntimeLocator.isCodexDesktopApp(app))
        try RuntimeLocator.persistCodexApp(app, userRoot: userRoot)

        XCTAssertEqual(
            RuntimeLocator.persistedCodexApp(userRoot: userRoot)?
                .standardizedFileURL,
            app.standardizedFileURL
        )
        let preference = userRoot.appendingPathComponent(
            "Runtime/codex-app-path"
        )
        let attributes = try FileManager.default.attributesOfItem(
            atPath: preference.path
        )
        let permissions = try XCTUnwrap(
            attributes[.posixPermissions] as? NSNumber
        )
        XCTAssertEqual(permissions.intValue & 0o777, 0o600)

        try RuntimeLocator.clearPersistedCodexApp(userRoot: userRoot)
        XCTAssertNil(RuntimeLocator.persistedCodexApp(userRoot: userRoot))
        XCTAssertFalse(
            FileManager.default.fileExists(atPath: preference.path)
        )
    }

    func testPersistRejectsAnUnrelatedApplicationBundle() throws {
        let root = try makeTemporaryDirectory()
        let unrelated = root.appendingPathComponent("Other.app")
        _ = try makeExecutable(
            at: unrelated.appendingPathComponent("Contents/MacOS/Other")
        )
        let info: [String: Any] = [
            "CFBundleExecutable": "Other",
            "CFBundleIdentifier": "com.example.other",
            "CFBundlePackageType": "APPL"
        ]
        let data = try PropertyListSerialization.data(
            fromPropertyList: info,
            format: .xml,
            options: 0
        )
        try data.write(
            to: unrelated.appendingPathComponent("Contents/Info.plist")
        )

        XCTAssertThrowsError(
            try RuntimeLocator.persistCodexApp(
                unrelated,
                userRoot: root.appendingPathComponent("User Data")
            )
        ) { error in
            guard case RuntimeLocationError.invalidCodexApp = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
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
        XCTAssertEqual(
            RuntimeLocationError.invalidCodexApp(
                "/tmp/Other.app"
            ).errorDescription,
            "The selected application is not Codex: /tmp/Other.app"
        )
    }
}
