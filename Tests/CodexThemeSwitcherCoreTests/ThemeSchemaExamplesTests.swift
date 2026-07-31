import Foundation
import XCTest
@testable import CodexThemeSwitcherCore

final class ThemeSchemaExamplesTests: XCTestCase {
    func testTrackedExamplesDecodeValidateCompileAndRoundTrip() throws {
        for name in ["minimal", "full"] {
            let url = repositoryRoot
                .appendingPathComponent("Examples")
                .appendingPathComponent(name)
                .appendingPathExtension("codextheme")
            let data = try Data(contentsOf: url)
            let envelope = try ThemeJSONCoding.decoder().decode(
                ThemeArchiveEnvelope.self,
                from: data
            )

            XCTAssertEqual(
                envelope.format,
                ThemeArchiveService.formatIdentifier,
                name
            )
            XCTAssertEqual(
                envelope.archiveVersion,
                ThemeArchiveService.currentArchiveVersion,
                name
            )

            let validation = ThemeValidator().validate(envelope.theme)
            XCTAssertTrue(validation.isValid, "\(name): \(validation.issues)")

            let compiled = try ThemeCompiler().compile(envelope.theme)
            XCTAssertFalse(compiled.css.isEmpty, name)

            let encoded = try ThemeJSONCoding.encoder().encode(envelope)
            let encodedObject = try XCTUnwrap(
                JSONSerialization.jsonObject(with: encoded)
                    as? [String: Any]
            )
            XCTAssertTrue(encodedObject["exportedAt"] is String, name)
            let theme = try XCTUnwrap(
                encodedObject["theme"] as? [String: Any]
            )
            let metadata = try XCTUnwrap(
                theme["metadata"] as? [String: Any]
            )
            XCTAssertTrue(metadata["createdAt"] is String, name)
            XCTAssertTrue(metadata["updatedAt"] is String, name)

            let roundTripped = try ThemeJSONCoding.decoder().decode(
                ThemeArchiveEnvelope.self,
                from: encoded
            )
            XCTAssertEqual(roundTripped, envelope, name)
        }
    }

    func testPublicCodecDecodesLegacyFoundationNumericDates() throws {
        let data = Data(
            """
            {
              "format": "com.codex-theme-switcher.theme",
              "archiveVersion": 1,
              "exportedAt": 0,
              "theme": {
                "schemaVersion": 1,
                "id": "00000000-0000-4000-8000-000000009000",
                "metadata": {
                  "name": "Legacy Numeric Dates",
                  "author": "",
                  "description": "",
                  "version": "1.0.0",
                  "tags": [],
                  "createdAt": 60,
                  "updatedAt": 120
                },
                "layers": [],
                "assets": []
              }
            }
            """.utf8
        )

        let decoded = try ThemeJSONCoding.decoder().decode(
            ThemeArchiveEnvelope.self,
            from: data
        )

        XCTAssertEqual(
            decoded.exportedAt,
            Date(timeIntervalSinceReferenceDate: 0)
        )
        XCTAssertEqual(
            decoded.theme.metadata.createdAt,
            Date(timeIntervalSinceReferenceDate: 60)
        )
        XCTAssertEqual(
            decoded.theme.metadata.updatedAt,
            Date(timeIntervalSinceReferenceDate: 120)
        )
    }

    func testPublicCodecPreservesFreshDatePrecision() throws {
        var interval = Date().timeIntervalSinceReferenceDate
        for _ in 0..<64 {
            let original = Date(timeIntervalSinceReferenceDate: interval)
            let encoded = try ThemeJSONCoding.encoder().encode(original)
            let text = try XCTUnwrap(
                String(data: encoded, encoding: .utf8)
            )
            let decoded = try ThemeJSONCoding.decoder().decode(
                Date.self,
                from: encoded
            )

            XCTAssertEqual(decoded, original)
            XCTAssertTrue(
                text.range(
                    of: #"T\d{2}:\d{2}:\d{2}\.\d{9}Z"#,
                    options: .regularExpression
                ) != nil
            )
            interval = interval.nextUp
        }
    }

    func testTrackedSchemaIsValidJSONAndDescribesArchiveSkinsAndVoice() throws {
        let url = repositoryRoot
            .appendingPathComponent("Sources/CodexThemeAgentCLI/Resources")
            .appendingPathComponent("codextheme.schema.json")
        let object = try XCTUnwrap(
            JSONSerialization.jsonObject(with: Data(contentsOf: url))
                as? [String: Any]
        )
        let definitions = try XCTUnwrap(object["$defs"] as? [String: Any])

        XCTAssertEqual(object["type"] as? String, "object")
        XCTAssertNotNil(definitions["themeDocument"])
        XCTAssertNotNil(definitions["imageSkin"])
        XCTAssertNotNil(definitions["voiceStyle"])
        XCTAssertNotNil(definitions["voiceVariant"])
        XCTAssertNotNil(definitions["live2DModel"])
        XCTAssertNotNil(definitions["live2DResource"])
        let voiceVariant = try XCTUnwrap(
            definitions["voiceVariant"] as? [String: Any]
        )
        let voiceProperties = try XCTUnwrap(
            voiceVariant["properties"] as? [String: Any]
        )
        XCTAssertNotNil(voiceProperties["avatarMode"])
        XCTAssertNotNil(voiceProperties["live2DModel"])
        XCTAssertNotNil(voiceProperties["backgroundAssetID"])
        XCTAssertNotNil(voiceProperties["overlayMascotWidth"])
        XCTAssertNotNil(voiceProperties["orbLocksToOverlayCenter"])
        XCTAssertNotNil(voiceProperties["orbBackgroundAssetID"])
        XCTAssertNotNil(voiceProperties["orbBackgroundImageFit"])
        XCTAssertNotNil(voiceProperties["orbBackgroundInset"])
        XCTAssertNotNil(voiceProperties["orbBackgroundFollowsVoicePulse"])
        XCTAssertNotNil(voiceProperties["orbBackgroundPulseStrength"])
        XCTAssertNotNil(voiceProperties["orbMouthFrameAssetIDs"])
        let mouthFrames = try XCTUnwrap(
            voiceProperties["orbMouthFrameAssetIDs"] as? [String: Any]
        )
        XCTAssertEqual(mouthFrames["maxItems"] as? Int, 8)
        XCTAssertNotNil(voiceProperties["orbMouthSensitivity"])
        XCTAssertNotNil(voiceProperties["orbMouthAttackMilliseconds"])
        let mouthRelease = try XCTUnwrap(
            voiceProperties["orbMouthReleaseMilliseconds"]
                as? [String: Any]
        )
        XCTAssertEqual(mouthRelease["minimum"] as? Int, 5)
        XCTAssertEqual(mouthRelease["maximum"] as? Int, 300)
        XCTAssertNotNil(voiceProperties["orbMouthNoiseGate"])
        XCTAssertNotNil(voiceProperties["orbMouthResponseCurve"])
        XCTAssertNotNil(voiceProperties["orbMouthSmoothing"])
        XCTAssertNotNil(voiceProperties["orbMouthFrameHoldMilliseconds"])
        XCTAssertNotNil(voiceProperties["orbIdleMotionEnabled"])
        XCTAssertNotNil(voiceProperties["orbIdleMotionStrength"])
        XCTAssertNotNil(voiceProperties["orbIdleMotionPeriodSeconds"])
        XCTAssertNotNil(voiceProperties["orbBlinkAssetID"])
        XCTAssertNotNil(voiceProperties["orbBlinkIntervalSeconds"])
        XCTAssertNotNil(voiceProperties["orbBlinkDurationMilliseconds"])
        XCTAssertNotNil(voiceProperties["backgroundImageFit"])
        XCTAssertNotNil(voiceProperties["backgroundPositionX"])
        XCTAssertNotNil(voiceProperties["backgroundPositionY"])
        XCTAssertNotNil(voiceProperties["backgroundZoom"])
        XCTAssertNotNil(voiceProperties["backgroundImageOpacity"])
        XCTAssertNotNil(voiceProperties["backgroundImageBlur"])
        XCTAssertNotNil(object["x-codex-limits"])
        XCTAssertNotNil(object["x-codex-security"])
    }

    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
