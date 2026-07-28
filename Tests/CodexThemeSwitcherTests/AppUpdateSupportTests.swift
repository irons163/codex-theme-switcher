import Foundation
import XCTest
@testable import CodexThemeSwitcher

final class AppUpdateSupportTests: XCTestCase {
    func testFeedNamesCoverStableBetaAndArchitectures() {
        XCTAssertEqual(
            AppUpdateChannel.stable.feedAssetName(for: .appleSilicon),
            "appcast-arm64.xml"
        )
        XCTAssertEqual(
            AppUpdateChannel.stable.feedAssetName(for: .intel),
            "appcast-x86_64.xml"
        )
        XCTAssertEqual(
            AppUpdateChannel.beta.feedAssetName(for: .appleSilicon),
            "appcast-beta-arm64.xml"
        )
        XCTAssertEqual(
            AppUpdateChannel.beta.feedAssetName(for: .intel),
            "appcast-beta-x86_64.xml"
        )
    }

    func testSemanticVersionComparisonHandlesPrereleases() {
        XCTAssertTrue(
            AppUpdateVersioning.isRemoteNewer(
                current: "1.4.0-beta.2",
                remote: "1.4.0-beta.10"
            )
        )
        XCTAssertTrue(
            AppUpdateVersioning.isRemoteNewer(
                current: "1.4.0-rc.1",
                remote: "1.4.0"
            )
        )
        XCTAssertFalse(
            AppUpdateVersioning.isRemoteNewer(
                current: "1.4.0",
                remote: "1.4.0-beta.10"
            )
        )
        XCTAssertEqual(
            AppUpdateVersioning.compare("v2.0", "2.0.0"),
            .orderedSame
        )
    }

    func testInstallerSelectionFollowsCurrentArchitecture() {
        let appleURL = URL(string: "https://example.test/apple.dmg")!
        let intelURL = URL(string: "https://example.test/intel.dmg")!
        let release = makeRelease(
            assets: [
                AppUpdateAsset(
                    name: "CodexThemeSwitcher-apple-silicon.dmg",
                    downloadURL: appleURL
                ),
                AppUpdateAsset(
                    name: "CodexThemeSwitcher-intel.dmg",
                    downloadURL: intelURL
                )
            ]
        )

        XCTAssertEqual(
            release.preferredInstallerURL(for: .appleSilicon),
            appleURL
        )
        XCTAssertEqual(
            release.preferredInstallerURL(for: .intel),
            intelURL
        )
    }

    func testLocalizedNotesMatchExactLanguageBeforeEnglish() {
        let traditionalURL = URL(
            string: "https://example.test/release-notes.zh-Hant.md"
        )!
        let englishURL = URL(
            string: "https://example.test/release-notes.en.md"
        )!
        let release = makeRelease(
            assets: [
                AppUpdateAsset(
                    name: "release-notes.en.md",
                    downloadURL: englishURL
                ),
                AppUpdateAsset(
                    name: "release-notes.zh-Hant.md",
                    downloadURL: traditionalURL
                )
            ]
        )

        let match = release.localizedReleaseNotesAsset(
            candidates: ["zh-hant", "zh", "en"]
        )
        XCTAssertEqual(match?.asset.downloadURL, traditionalURL)
        XCTAssertEqual(match?.languageCode, "zh-hant")
    }

    func testAutomaticCheckPolicyUsesThirtyMinutes() {
        let now = Date(timeIntervalSince1970: 10_000)
        XCTAssertEqual(AppUpdateAutoCheckPolicy.interval, 30 * 60)
        XCTAssertTrue(
            AppUpdateAutoCheckPolicy.shouldRun(
                lastCheckedAt: 0,
                now: now
            )
        )
        XCTAssertFalse(
            AppUpdateAutoCheckPolicy.shouldRun(
                lastCheckedAt: now.timeIntervalSince1970 - 1_799,
                now: now
            )
        )
        XCTAssertTrue(
            AppUpdateAutoCheckPolicy.shouldRun(
                lastCheckedAt: now.timeIntervalSince1970 - 1_800,
                now: now
            )
        )
    }

    func testVersionIDIncludesBuildNumber() {
        XCTAssertEqual(
            AppVersionInfo(version: "v0.3.0-beta.1", build: "11")
                .versionID,
            "0.3.0-beta.1+11"
        )
    }

    func testBetaServiceSelectsNewestVisibleReleaseAndLocalizedNotes()
        async throws {
        let latestEndpoint = URL(
            string: "https://example.test/repos/theme/releases/latest"
        )!
        let releasesEndpoint = URL(
            string: "https://example.test/repos/theme/releases?per_page=30"
        )!
        let notesURL = URL(
            string: "https://example.test/release-notes.zh-Hant.md"
        )!

        StubURLProtocol.responses = [
            releasesEndpoint: .init(
                statusCode: 200,
                data: Data(
                    """
                    [
                      {
                        "tag_name": "v1.2.0",
                        "name": "Stable",
                        "html_url": "https://example.test/v1.2.0",
                        "published_at": "2026-07-20T00:00:00Z",
                        "draft": false,
                        "assets": []
                      },
                      {
                        "tag_name": "v1.3.0-beta.10",
                        "name": "Beta 10",
                        "html_url": "https://example.test/v1.3.0-beta.10",
                        "published_at": "2026-07-27T00:00:00Z",
                        "draft": false,
                        "assets": [
                          {
                            "name": "release-notes.zh-Hant.md",
                            "browser_download_url": "\(notesURL.absoluteString)"
                          }
                        ]
                      },
                      {
                        "tag_name": "v9.0.0",
                        "name": "Draft",
                        "html_url": "https://example.test/v9.0.0",
                        "draft": true,
                        "assets": []
                      }
                    ]
                    """.utf8
                )
            ),
            notesURL: .init(
                statusCode: 200,
                data: Data("繁體中文版本說明".utf8)
            )
        ]
        defer { StubURLProtocol.responses = [:] }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let service = AppUpdateService(
            latestEndpoint: latestEndpoint,
            session: session
        )

        let release = try await service.fetchLatestRelease(
            channel: .beta,
            language: .traditionalChinese
        )

        XCTAssertEqual(release.normalizedVersion, "1.3.0-beta.10")
        XCTAssertEqual(release.releaseNotesText, "繁體中文版本說明")
        XCTAssertEqual(release.notesLanguageCode, "zh-hant")
    }

    @MainActor
    func testAvailableUpdateWaitsBehindWhatsNewSheet() async throws {
        let endpoint = URL(
            string: "https://example.test/repos/theme/releases/latest"
        )!
        StubURLProtocol.responses = [
            endpoint: .init(
                statusCode: 200,
                data: Data(
                    """
                    {
                      "tag_name": "v2.0.0",
                      "name": "Version 2",
                      "html_url": "https://example.test/v2.0.0",
                      "published_at": "2026-07-27T00:00:00Z",
                      "draft": false,
                      "assets": []
                    }
                    """.utf8
                )
            )
        ]
        defer { StubURLProtocol.responses = [:] }

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }

        let suiteName = "AppUpdateSupportTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(
            UserDefaults(suiteName: suiteName)
        )
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        let model = AppUpdateModel(
            defaults: defaults,
            service: AppUpdateService(
                latestEndpoint: endpoint,
                session: session
            ),
            installer: StubUpdateInstaller(),
            versionInfo: AppVersionInfo(version: "1.0.0", build: "1")
        )

        model.start()
        model.presentLaunchAnnouncements()
        guard case .whatsNew = model.sheet else {
            return XCTFail("Expected What's New to be presented first")
        }

        for _ in 0..<100 where model.availableRelease == nil {
            try await Task.sleep(nanoseconds: 10_000_000)
        }
        XCTAssertEqual(
            model.availableRelease?.normalizedVersion,
            "2.0.0"
        )
        guard case .whatsNew = model.sheet else {
            return XCTFail("Update should not replace What's New")
        }

        model.dismissWhatsNew(markSeen: true)
        guard case let .update(release) = model.sheet else {
            return XCTFail("Expected queued update after What's New")
        }
        XCTAssertEqual(release.normalizedVersion, "2.0.0")
    }

    @MainActor
    func testAboutSheetCanBePresentedAndDismissed() {
        let model = AppUpdateModel(
            installer: StubUpdateInstaller(),
            versionInfo: AppVersionInfo(
                version: "0.3.0-beta.2",
                build: "16"
            )
        )

        model.showAbout()
        XCTAssertEqual(model.sheet, .about)

        model.dismissSheet()
        XCTAssertNil(model.sheet)
    }

    private func makeRelease(
        assets: [AppUpdateAsset]
    ) -> AppUpdateRelease {
        AppUpdateRelease(
            tagName: "v1.0.0",
            name: "Release",
            htmlURL: URL(string: "https://example.test/release")!,
            publishedAt: nil,
            body: nil,
            assets: assets,
            notesLanguageCode: nil
        )
    }
}

@MainActor
private final class StubUpdateInstaller: AppUpdateInstalling {
    var isAvailable = true
    private(set) var channel: AppUpdateChannel = .stable

    func configure(channel: AppUpdateChannel) {
        self.channel = channel
    }

    func startUserInitiatedUpdate() -> Bool {
        true
    }
}

private final class StubURLProtocol: URLProtocol, @unchecked Sendable {
    struct Response {
        let statusCode: Int
        let data: Data
    }

    nonisolated(unsafe) static var responses: [URL: Response] = [:]

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(
        for request: URLRequest
    ) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let response = Self.responses[url],
              let httpResponse = HTTPURLResponse(
                  url: url,
                  statusCode: response.statusCode,
                  httpVersion: nil,
                  headerFields: nil
              ) else {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.badServerResponse)
            )
            return
        }
        client?.urlProtocol(
            self,
            didReceive: httpResponse,
            cacheStoragePolicy: .notAllowed
        )
        client?.urlProtocol(self, didLoad: response.data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
