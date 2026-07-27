import Foundation

/// Canonical JSON coding configuration for theme documents and archives.
///
/// New JSON uses ISO-8601 date strings. The decoder also accepts the numeric
/// seconds-since-2001 representation emitted by older versions of Foundation's
/// default `JSONEncoder`, so existing repositories and `.codextheme` files keep
/// working.
public enum ThemeJSONCoding {
    public static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [
            .prettyPrinted,
            .sortedKeys,
            .withoutEscapingSlashes
        ]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(iso8601String(from: date))
        }
        return encoder
    }

    public static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()

            if let value = try? container.decode(String.self) {
                if let date = dateFromNanosecondUTCString(value) {
                    return date
                }

                let fractionalFormatter = ISO8601DateFormatter()
                fractionalFormatter.formatOptions = [
                    .withInternetDateTime,
                    .withFractionalSeconds
                ]
                if let date = fractionalFormatter.date(from: value) {
                    return date
                }

                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: value) {
                    return date
                }

                throw DecodingError.dataCorruptedError(
                    in: container,
                    debugDescription: "Expected an ISO-8601 date string."
                )
            }

            if let legacySeconds = try? container.decode(Double.self) {
                return Date(timeIntervalSinceReferenceDate: legacySeconds)
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription:
                    "Expected an ISO-8601 date string or legacy Foundation numeric date."
            )
        }
        return decoder
    }

    /// Foundation's ISO8601 formatter emits only millisecond precision. A
    /// repository save immediately followed by a load would therefore change a
    /// freshly-created `Date`, breaking exact ThemeDocument round trips. Nine
    /// fractional digits retain more precision than `Date` can represent at
    /// current epochs while remaining ordinary ISO-8601.
    private static func iso8601String(from date: Date) -> String {
        // Work in Foundation's 2001 reference interval. At current dates this
        // value is less than half the Unix interval, retaining one additional
        // binary precision bit. Converting to Unix seconds before separating
        // the fraction can otherwise lose roughly 100 ns and break an exact
        // Date round trip even though the rendered timestamps look identical.
        let seconds = date.timeIntervalSinceReferenceDate
        var wholeSeconds = floor(seconds)
        var nanoseconds = Int(
            ((seconds - wholeSeconds) * 1_000_000_000).rounded()
        )
        if nanoseconds == 1_000_000_000 {
            wholeSeconds += 1
            nanoseconds = 0
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let base = formatter.string(
            from: Date(timeIntervalSinceReferenceDate: wholeSeconds)
        )
        let digits = String(nanoseconds)
        let fraction = String(
            repeating: "0",
            count: max(0, 9 - digits.count)
        ) + digits
        return "\(base.dropLast()).\(fraction)Z"
    }

    private static func dateFromNanosecondUTCString(
        _ value: String
    ) -> Date? {
        guard value.hasSuffix("Z"),
              let dot = value.lastIndex(of: "."),
              value[..<dot].contains("T")
        else {
            return nil
        }
        let fractionStart = value.index(after: dot)
        let fractionEnd = value.index(before: value.endIndex)
        let fractionDigits = value[fractionStart..<fractionEnd]
        guard !fractionDigits.isEmpty,
              fractionDigits.allSatisfy(\.isNumber),
              let fractionalSeconds = Double("0.\(fractionDigits)")
        else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        let baseString = "\(value[..<dot])Z"
        guard let base = formatter.date(from: baseString) else {
            return nil
        }
        return Date(
            timeIntervalSinceReferenceDate:
                base.timeIntervalSinceReferenceDate + fractionalSeconds
        )
    }
}
