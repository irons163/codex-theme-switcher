import Foundation
import XCTest
@testable import CodexThemeSwitcher

final class L10nTests: XCTestCase {
    func testResolveRecognizesSupportedLanguageIdentifiers() {
        let identifiersByLanguage: [AppLanguage: [String]] = [
            .english: ["en", "en-US"],
            .traditionalChinese: [
                "zh-Hant",
                "zh-TW",
                "zh-HK",
                "zh-MO"
            ],
            .simplifiedChinese: [
                "zh-Hans",
                "zh-CN",
                "zh-SG",
                "zh-MY"
            ],
            .french: ["fr", "fr-FR"],
            .spanish: ["es", "es-MX"],
            .japanese: ["ja", "ja-JP"],
            .korean: ["ko", "ko-KR"]
        ]

        for (expectedLanguage, identifiers) in identifiersByLanguage {
            for identifier in identifiers {
                XCTAssertEqual(
                    AppLanguage.resolve(preferredLanguages: [identifier]),
                    expectedLanguage,
                    "Expected \(identifier) to resolve to \(expectedLanguage)"
                )
            }
        }
    }

    func testResolveNormalizesUnderscoresCaseAndWhitespace() {
        XCTAssertEqual(
            AppLanguage.resolve(preferredLanguages: [" ZH_hAnT_TW "]),
            .traditionalChinese
        )
        XCTAssertEqual(
            AppLanguage.resolve(preferredLanguages: ["zH_hAnS_cN"]),
            .simplifiedChinese
        )
        XCTAssertEqual(
            AppLanguage.resolve(preferredLanguages: ["FR_ca"]),
            .french
        )
    }

    func testResolveUsesFirstSupportedPreferredLanguage() {
        XCTAssertEqual(
            AppLanguage.resolve(
                preferredLanguages: [
                    "de-DE",
                    "it-IT",
                    "ja-JP",
                    "fr-FR"
                ]
            ),
            .japanese
        )
    }

    func testResolveFallsBackToEnglishForEmptyOrUnsupportedPreferences() {
        XCTAssertEqual(
            AppLanguage.resolve(preferredLanguages: []),
            .english
        )
        XCTAssertEqual(
            AppLanguage.resolve(
                preferredLanguages: ["de-DE", "it_IT", "   "]
            ),
            .english
        )
    }

    func testLanguageSettingsPersistManualSelectionAndRestoreAutomatic() {
        let suiteName = "L10nTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Unable to create isolated defaults")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let settings = AppLanguageSettings(defaults: defaults)
        XCTAssertEqual(settings.selection, .automatic)
        XCTAssertEqual(
            settings.resolvedLanguage(preferredLanguages: ["fr-FR"]),
            .french
        )

        settings.selection = .japanese
        XCTAssertEqual(
            defaults.string(forKey: AppLanguageSettings.storageKey),
            AppLanguagePreference.japanese.rawValue
        )
        XCTAssertEqual(
            settings.resolvedLanguage(preferredLanguages: ["fr-FR"]),
            .japanese
        )
        XCTAssertEqual(
            AppLanguageSettings(defaults: defaults).selection,
            .japanese
        )

        settings.selection = .automatic
        XCTAssertNil(
            defaults.object(forKey: AppLanguageSettings.storageKey)
        )
        XCTAssertEqual(
            settings.resolvedLanguage(preferredLanguages: ["ko-KR"]),
            .korean
        )
    }

    func testLanguageSettingsIgnoreInvalidStoredPreference() {
        let suiteName = "L10nTests.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Unable to create isolated defaults")
        }
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        defaults.set(
            "de-DE",
            forKey: AppLanguageSettings.storageKey
        )

        let settings = AppLanguageSettings(defaults: defaults)
        XCTAssertEqual(settings.selection, .automatic)
        XCTAssertEqual(
            settings.resolvedLanguage(preferredLanguages: ["es-MX"]),
            .spanish
        )
    }

    func testTextReturnsExpectedTranslationForExplicitLanguage() {
        let cases: [
            (
                traditionalChinese: String,
                english: String,
                expected: [AppLanguage: String]
            )
        ] = [
            (
                "套用",
                "Apply",
                [
                    .english: "Apply",
                    .traditionalChinese: "套用",
                    .simplifiedChinese: "应用",
                    .french: "Appliquer",
                    .spanish: "Aplicar",
                    .japanese: "適用",
                    .korean: "적용"
                ]
            ),
            (
                "主題庫",
                "Themes",
                [
                    .english: "Themes",
                    .traditionalChinese: "主題庫",
                    .simplifiedChinese: "主题库",
                    .french: "Thèmes",
                    .spanish: "Temas",
                    .japanese: "テーマ",
                    .korean: "테마"
                ]
            ),
            (
                "新增素材",
                "Add asset",
                [
                    .english: "Add asset",
                    .traditionalChinese: "新增素材",
                    .simplifiedChinese: "添加素材",
                    .french: "Ajouter une ressource",
                    .spanish: "Añadir recurso",
                    .japanese: "アセットを追加",
                    .korean: "에셋 추가"
                ]
            )
        ]

        for testCase in cases {
            for language in AppLanguage.allCases {
                XCTAssertEqual(
                    L10n.text(
                        testCase.traditionalChinese,
                        testCase.english,
                        language: language
                    ),
                    testCase.expected[language],
                    "Unexpected \(language) translation for \(testCase.english)"
                )
            }
        }
    }

    func testFormatReplacesPlaceholdersAfterTranslation() {
        let expected: [AppLanguage: String] = [
            .english: "Copy Midnight to Paper",
            .traditionalChinese: "將 Midnight 複製到 Paper",
            .simplifiedChinese: "将Midnight复制到Paper",
            .french: "Copier Midnight vers Paper",
            .spanish: "Copiar Midnight a Paper",
            .japanese: "MidnightをPaperにコピー",
            .korean: "Midnight을(를) Paper(으)로 복사"
        ]

        for language in AppLanguage.allCases {
            XCTAssertEqual(
                L10n.format(
                    "將 {0} 複製到 {1}",
                    "Copy {0} to {1}",
                    values: ["Midnight", "Paper"],
                    language: language
                ),
                expected[language],
                "Unexpected placeholder formatting for \(language)"
            )
        }
    }

    func testEveryCatalogHasTheSameNonemptyKeysAndValues() {
        let catalogLanguages = AppLanguage.allCases.filter {
            $0 != .english && $0 != .traditionalChinese
        }
        guard let referenceLanguage = catalogLanguages.first,
              let referenceCatalog = L10nCatalog.translations[
                  referenceLanguage
              ] else {
            return XCTFail("Expected at least one translation catalog")
        }
        let referenceKeys = Set(referenceCatalog.keys)

        for language in catalogLanguages {
            guard let catalog = L10nCatalog.translations[language] else {
                XCTFail("Missing catalog for \(language)")
                continue
            }

            XCTAssertEqual(
                Set(catalog.keys),
                referenceKeys,
                "Catalog keys differ for \(language)"
            )

            for (key, value) in catalog {
                XCTAssertFalse(
                    value.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    ).isEmpty,
                    "Empty translation for \(language): \(key)"
                )
            }
        }
    }

    func testEveryTranslationPreservesFormatPlaceholders() throws {
        let expression = try NSRegularExpression(
            pattern: #"\{\d+\}"#
        )

        func placeholders(in value: String) -> Set<String> {
            let range = NSRange(
                value.startIndex..<value.endIndex,
                in: value
            )
            return Set(
                expression.matches(in: value, range: range).compactMap {
                    guard let matchRange = Range($0.range, in: value) else {
                        return nil
                    }
                    return String(value[matchRange])
                }
            )
        }

        for (language, catalog) in L10nCatalog.translations {
            for (key, value) in catalog {
                XCTAssertEqual(
                    placeholders(in: value),
                    placeholders(in: key),
                    "Placeholder mismatch for \(language): \(key)"
                )
            }
        }
    }
}
