import Darwin
import Foundation

@_silgen_name("flock")
private func systemFlock(
    _ descriptor: Int32,
    _ operation: Int32
) -> Int32

/// A process-wide advisory lock shared by the menu bar app and agent CLI.
///
/// Swift actors serialize one repository instance, but the app and CLI are
/// separate processes. Without an OS lock, two `collisionPolicy: .fail` saves
/// can both pass the existence check and silently overwrite one another.
struct RepositoryFileLock: Sendable {
    let rootDirectory: URL

    func withExclusiveLock<T>(
        _ operation: () throws -> T
    ) throws -> T {
        try FileManager.default.createDirectory(
            at: rootDirectory,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try? FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: rootDirectory.path
        )

        let lockURL = rootDirectory.appendingPathComponent(
            ".repository.lock"
        )
        let descriptor = lockURL.path.withCString {
            Darwin.open(
                $0,
                O_CREAT | O_RDWR | O_CLOEXEC,
                mode_t(S_IRUSR | S_IWUSR)
            )
        }
        guard descriptor >= 0 else {
            throw RepositoryFileLockError(
                operation: "open",
                errorNumber: errno
            )
        }
        defer { Darwin.close(descriptor) }
        _ = Darwin.fchmod(descriptor, mode_t(S_IRUSR | S_IWUSR))

        while systemFlock(descriptor, LOCK_EX) != 0 {
            if errno == EINTR {
                continue
            }
            throw RepositoryFileLockError(
                operation: "lock",
                errorNumber: errno
            )
        }
        defer { _ = systemFlock(descriptor, LOCK_UN) }
        return try operation()
    }
}

private struct RepositoryFileLockError: LocalizedError {
    var operation: String
    var errorNumber: Int32

    var errorDescription: String? {
        let reason = String(cString: strerror(errorNumber))
        return "Unable to \(operation) the theme repository lock: \(reason)."
    }
}
