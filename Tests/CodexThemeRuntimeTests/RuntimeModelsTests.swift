import Foundation
import XCTest
@testable import CodexThemeRuntime

final class RuntimeModelsTests: XCTestCase {
    func testStatusRoundTripsEveryField() throws {
        let status = ThemeRuntimeStatus(
            codexPath: "/Applications/ChatGPT.app",
            codexVersion: "26.721.41059",
            mode: "cdp-css",
            isInjected: true,
            bridgeRunning: true,
            debugPort: 57_340,
            bridgePort: 57_342,
            isRunning: true,
            isDebugPortReady: true,
            hasCodexTarget: true,
            activeThemeID: "midnight",
            activeThemeName: "Midnight",
            injectedRendererCount: 2,
            lastError: nil
        )

        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(
            ThemeRuntimeStatus.self,
            from: data
        )

        XCTAssertEqual(decoded, status)
    }

    func testStatusDecodesWhenHelperOmitsAllOptionalFields() throws {
        let decoded = try JSONDecoder().decode(
            ThemeRuntimeStatus.self,
            from: Data("{}".utf8)
        )

        XCTAssertEqual(decoded, ThemeRuntimeStatus())
    }

    func testResultDecodesHelperJSONAndIgnoresFutureFields() throws {
        let json = """
        {
          "ok": true,
          "status": {
            "mode": "cdp-css",
            "isInjected": true,
            "debugPort": 57340,
            "futureStatusField": "ignored"
          },
          "error": null,
          "rawOutput": null,
          "futureResultField": 1
        }
        """

        let result = try JSONDecoder().decode(
            ThemeRuntimeResult.self,
            from: Data(json.utf8)
        )

        XCTAssertTrue(result.ok)
        XCTAssertEqual(result.status?.mode, "cdp-css")
        XCTAssertEqual(result.status?.isInjected, true)
        XCTAssertEqual(result.status?.debugPort, 57_340)
        XCTAssertNil(result.error)
    }

    func testSuccessfulResultCanBeRequired() throws {
        let result = ThemeRuntimeResult(
            ok: true,
            status: ThemeRuntimeStatus(isInjected: true),
            error: nil,
            rawOutput: nil
        )

        XCTAssertEqual(try result.requiringSuccess(), result)
    }

    func testRequiringSuccessUsesStructuredErrorMessage() {
        let result = ThemeRuntimeResult(
            ok: false,
            status: nil,
            error: ThemeRuntimeErrorPayload(
                message: "Bridge unavailable",
                code: "bridge-error"
            ),
            rawOutput: "less useful output"
        )

        XCTAssertThrowsError(try result.requiringSuccess()) { error in
            XCTAssertEqual(
                error as? ThemeRuntimeFailure,
                ThemeRuntimeFailure(
                    message: "Bridge unavailable",
                    code: "bridge-error"
                )
            )
            XCTAssertEqual(
                (error as? LocalizedError)?.errorDescription,
                "Bridge unavailable"
            )
        }
    }

    func testRequiringSuccessFallsBackToRawOutputAndDefaultMessage() {
        let rawResult = ThemeRuntimeResult(
            ok: false,
            status: nil,
            error: nil,
            rawOutput: "not-json"
        )
        XCTAssertThrowsError(try rawResult.requiringSuccess()) { error in
            XCTAssertEqual(
                error as? ThemeRuntimeFailure,
                ThemeRuntimeFailure(message: "not-json")
            )
        }

        let emptyResult = ThemeRuntimeResult(
            ok: false,
            status: nil,
            error: nil,
            rawOutput: nil
        )
        XCTAssertThrowsError(try emptyResult.requiringSuccess()) { error in
            XCTAssertEqual(
                error as? ThemeRuntimeFailure,
                ThemeRuntimeFailure(
                    message: "Codex Theme runtime command failed."
                )
            )
        }
    }

    func testRuntimeThemePayloadEncodesExpectedWireKeys() throws {
        let payload = RuntimeThemePayload(
            themeID: "theme-id",
            themeName: "Theme Name",
            css: ":root { color: #fff; }"
        )
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(payload)
            ) as? [String: String]
        )

        XCTAssertEqual(
            object,
            [
                "themeID": "theme-id",
                "themeName": "Theme Name",
                "css": ":root { color: #fff; }"
            ]
        )
    }

    func testRuntimeThemePayloadEncodesAssetsWithoutNames() throws {
        let payload = RuntimeThemePayload(
            themeID: "theme-id",
            themeName: "Theme Name",
            css: #".hero{background:url("codex-theme-asset://asset")}"#,
            assets: [
                ThemeRuntimeAsset(
                    id: "a8d603e1-f01d-48d0-bd8f-cbfe4d179a66",
                    mediaType: "image/png",
                    dataBase64: "AAECAw=="
                )
            ]
        )
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(
                with: JSONEncoder().encode(payload)
            ) as? [String: Any]
        )
        let assets = try XCTUnwrap(
            object["assets"] as? [[String: String]]
        )

        XCTAssertEqual(
            assets,
            [[
                "id": "a8d603e1-f01d-48d0-bd8f-cbfe4d179a66",
                "mediaType": "image/png",
                "dataBase64": "AAECAw=="
            ]]
        )
        XCTAssertNil(assets.first?["name"])
    }
}
