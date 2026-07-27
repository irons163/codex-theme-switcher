import Foundation

/// Stable theme identifiers and starter themes shipped with the app.
///
/// Built-in documents are regular `ThemeDocument` values, so they can be
/// duplicated, edited, compiled, and exported without a special code path.
public enum BuiltInThemes {
    public static let midnight: ThemeDocument = {
        ThemeDocument(
            id: UUID(uuidString: "7A85B946-44D6-46C4-9063-DC1CFE7E6501")!,
            metadata: metadata(
                name: "Midnight",
                description: "A deep blue-black theme with a cool cyan accent.",
                tags: ["dark", "blue"]
            ),
            layers: [
                ThemeLayer(
                    id: UUID(uuidString: "83755819-BD88-405E-AC4E-FF8F5003BD2E")!,
                    name: "Midnight",
                    variables: [
                        semantic(.backgroundPrimary, "#0b1020", id: "8DE6DA8E-BDF5-49D2-902C-601AC1A1A0B1"),
                        semantic(.backgroundSecondary, "#11182b", id: "9CF44E63-ED09-42BD-9E0E-FAD2A5CE1367"),
                        semantic(.surface, "rgba(30, 41, 65, 0.86)", id: "24CE6634-A482-47B5-985F-055B754EA44D"),
                        semantic(.textPrimary, "#eef5ff", id: "F014EB61-1E6B-4010-AACB-00021E528CDD"),
                        semantic(.textSecondary, "#a9b8d0", id: "B263B570-E870-4CB5-9532-8A9C9840C513"),
                        semantic(.accent, "#62d9ff", id: "D65A44F5-2885-42E4-B861-BED3717A754D"),
                        semantic(.border, "rgba(150, 185, 225, 0.20)", id: "6CA97BBF-B457-4C8A-989D-E5E1991D5ED7"),
                        semantic(.success, "#63e6a5", id: "51E4CFCA-A82B-4EBE-815D-6AA4D3435601"),
                        semantic(.warning, "#ffd166", id: "8D89BF1A-35C7-45D2-96A5-01F066390921"),
                        semantic(.error, "#ff7b91", id: "63913A7A-0939-445E-B59F-577390205E21")
                    ],
                    components: [
                        component(
                            "app",
                            id: "63489D31-B46D-4324-AEC8-2CE3C7C81D43",
                            [
                                ("background", "var(--codex-theme-background-primary)"),
                                ("color", "var(--codex-theme-text-primary)")
                            ]
                        ),
                        component(
                            "sidebar",
                            id: "078663D0-EB65-4736-A4A1-6E6E94E49E70",
                            [
                                ("background", "var(--codex-theme-background-secondary)"),
                                ("border-color", "var(--codex-theme-border)")
                            ]
                        ),
                        component(
                            "composer",
                            id: "424981C3-A82A-4C6C-B673-3042EF1D01BD",
                            [
                                ("background", "var(--codex-theme-surface)"),
                                ("border", "1px solid var(--codex-theme-border)"),
                                ("border-radius", "16px"),
                                ("box-shadow", "0 18px 50px rgba(0, 0, 0, 0.28)")
                            ]
                        ),
                        component(
                            "codeBlock",
                            id: "683A5C7F-806F-47E3-BC33-EF1E656CE940",
                            [
                                ("background", "#080d19"),
                                ("border", "1px solid var(--codex-theme-border)"),
                                ("border-radius", "10px")
                            ]
                        )
                    ],
                    rawCSS: """
                    :root { color-scheme: dark; }
                    ::selection {
                      background: color-mix(in srgb, var(--codex-theme-accent) 35%, transparent);
                    }
                    """
                )
            ]
        )
    }()

    public static let paper: ThemeDocument = {
        ThemeDocument(
            id: UUID(uuidString: "AA6D2C4F-1492-43D5-99D9-8CA9F8D91802")!,
            metadata: metadata(
                name: "Paper",
                description: "A warm, low-glare light theme inspired by natural paper.",
                tags: ["light", "warm"]
            ),
            layers: [
                ThemeLayer(
                    id: UUID(uuidString: "81218053-E99B-41D9-A23B-48CAED372380")!,
                    name: "Paper",
                    variables: [
                        semantic(.backgroundPrimary, "#f6f1e7", id: "7D2EDB24-EA97-4FE6-8A01-696E6999E7CC"),
                        semantic(.backgroundSecondary, "#eee6d7", id: "DDE7EB0F-40BD-400A-98D4-5143454F9ED7"),
                        semantic(.surface, "rgba(255, 252, 245, 0.92)", id: "3DF211C3-F253-4C90-ADAF-8E220178F450"),
                        semantic(.textPrimary, "#29251f", id: "2EF5DB2C-5D5B-47FE-91E2-A4B4DAACB41A"),
                        semantic(.textSecondary, "#696055", id: "0E3FEB1A-1C6E-45E5-B124-A59EBEA2181E"),
                        semantic(.accent, "#b34b2d", id: "B460FC32-7F51-4112-A03C-C994AF838EEE"),
                        semantic(.border, "rgba(82, 65, 45, 0.18)", id: "54E98698-E62A-474E-BF5E-DB1B7EC44FC1"),
                        semantic(.success, "#247a4d", id: "BEFA7484-470B-4781-B161-5DC837DF463E"),
                        semantic(.warning, "#9a6500", id: "E7F554F9-EEC1-4B9E-AE62-52537EA5F005"),
                        semantic(.error, "#b42336", id: "E04B2974-5BFF-4A9C-9F3A-A25951A0E684")
                    ],
                    components: [
                        component(
                            "app",
                            id: "B503EFC2-FE55-4F22-815E-38B59344429B",
                            [
                                ("background", "var(--codex-theme-background-primary)"),
                                ("color", "var(--codex-theme-text-primary)")
                            ]
                        ),
                        component(
                            "sidebar",
                            id: "B64718D0-325E-4A26-9876-79CC3652A42C",
                            [
                                ("background", "var(--codex-theme-background-secondary)"),
                                ("border-color", "var(--codex-theme-border)")
                            ]
                        ),
                        component(
                            "composer",
                            id: "C2C89A41-44EA-47C7-892E-5D7425D8F204",
                            [
                                ("background", "var(--codex-theme-surface)"),
                                ("border", "1px solid var(--codex-theme-border)"),
                                ("border-radius", "12px"),
                                ("box-shadow", "0 10px 30px rgba(78, 57, 34, 0.10)")
                            ]
                        ),
                        component(
                            "codeBlock",
                            id: "681C45BE-4E1B-4D25-9D45-F2A265A22F9B",
                            [
                                ("background", "#ebe3d5"),
                                ("border", "1px solid var(--codex-theme-border)"),
                                ("border-radius", "8px")
                            ]
                        )
                    ],
                    rawCSS: ":root { color-scheme: light; }"
                )
            ]
        )
    }()

    public static let highContrast: ThemeDocument = {
        ThemeDocument(
            id: UUID(uuidString: "C39E6F2C-157B-4444-B1BF-C07D5E64A103")!,
            metadata: metadata(
                name: "High Contrast",
                description: "Maximum contrast with strong focus and selection indicators.",
                tags: ["dark", "accessibility", "contrast"]
            ),
            layers: [
                ThemeLayer(
                    id: UUID(uuidString: "9D88757F-F27E-4AF4-8256-E70293AF8916")!,
                    name: "High Contrast",
                    variables: [
                        semantic(.backgroundPrimary, "#000000", id: "84A2F32C-CB3C-4286-9BD1-D7D961EC27D3"),
                        semantic(.backgroundSecondary, "#080808", id: "5FED74B5-A7E8-482D-BD65-E6BB98E9E40E"),
                        semantic(.surface, "#111111", id: "93CC5018-1874-4CC6-AF06-1E6C1F489D2E"),
                        semantic(.textPrimary, "#ffffff", id: "903EDCD2-8B57-4084-BE01-C5347BBF5A89"),
                        semantic(.textSecondary, "#dedede", id: "8DBA478B-8428-479A-8441-A9BF7C8DCCAC"),
                        semantic(.accent, "#00e5ff", id: "0D7DD516-C7C2-4DDD-B048-CE305DC346C2"),
                        semantic(.border, "#ffffff", id: "8505DFCE-44AC-4025-B2F7-C3CB25FBA226"),
                        semantic(.success, "#65ff8f", id: "6D3A6746-0F26-41A0-8E32-78D5422C0572"),
                        semantic(.warning, "#ffe600", id: "C5067E3C-7156-4646-B3AE-EC449E40C0F2"),
                        semantic(.error, "#ff506b", id: "F53E628E-B7D0-4DB5-A0AF-C487C0AF5BB0")
                    ],
                    components: [
                        component(
                            "app",
                            id: "9578A914-CBB8-4DF3-9B89-B4BB0F0B340E",
                            [
                                ("background", "var(--codex-theme-background-primary)"),
                                ("color", "var(--codex-theme-text-primary)")
                            ]
                        ),
                        component(
                            "composer",
                            id: "A8391F05-D560-4AD4-8E3E-7591C0501966",
                            [
                                ("background", "var(--codex-theme-surface)"),
                                ("border", "2px solid var(--codex-theme-border)")
                            ]
                        )
                    ],
                    rawCSS: """
                    :root { color-scheme: dark; }
                    :focus-visible {
                      outline: 3px solid var(--codex-theme-accent) !important;
                      outline-offset: 2px !important;
                    }
                    ::selection {
                      background: #ffe600;
                      color: #000000;
                    }
                    """
                )
            ]
        )
    }()

    public static let all: [ThemeDocument] = [
        midnight,
        paper,
        highContrast
    ]

    public static func theme(id: UUID) -> ThemeDocument? {
        all.first { $0.id == id }
    }

    private static func metadata(
        name: String,
        description: String,
        tags: [String]
    ) -> ThemeMetadata {
        let date = Date(timeIntervalSince1970: 1_735_689_600)
        return ThemeMetadata(
            name: name,
            author: "Codex Theme Switcher",
            description: description,
            version: "1.0.0",
            tags: tags,
            homepage: nil,
            license: "MIT",
            createdAt: date,
            updatedAt: date
        )
    }

    private static func semantic(
        _ role: ThemeSemanticRole,
        _ value: String,
        id: String
    ) -> ThemeVariable {
        ThemeVariable(
            id: UUID(uuidString: id)!,
            value: value,
            semanticRole: role
        )
    }

    private static func component(
        _ componentID: String,
        id: String,
        _ declarations: [(String, String)]
    ) -> ThemeComponentOverride {
        ThemeComponentOverride(
            id: UUID(uuidString: id)!,
            componentID: componentID,
            declarations: declarations.enumerated().map { index, declaration in
                let seed = "\(id)-\(index)"
                return ThemeCSSDeclaration(
                    id: deterministicUUID(seed: seed),
                    property: declaration.0,
                    value: declaration.1
                )
            }
        )
    }

    /// Produces stable declaration IDs without importing a hashing framework.
    private static func deterministicUUID(seed: String) -> UUID {
        var bytes = Array(repeating: UInt8(0), count: 16)
        for (index, byte) in seed.utf8.enumerated() {
            let position = index % bytes.count
            bytes[position] = bytes[position] &* 31 &+ byte
        }
        bytes[6] = (bytes[6] & 0x0F) | 0x40
        bytes[8] = (bytes[8] & 0x3F) | 0x80
        return UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            bytes[8], bytes[9], bytes[10], bytes[11],
            bytes[12], bytes[13], bytes[14], bytes[15]
        ))
    }
}
