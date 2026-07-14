import Foundation

public struct MountedVolumeSidebarRefreshPass: Equatable, Sendable {
    public let delay: TimeInterval

    public init(delay: TimeInterval) {
        self.delay = delay
    }
}

public struct MountedVolumeSidebarRefreshPolicy {
    private let refreshNotificationNames: Set<String>
    private let refreshPasses: [MountedVolumeSidebarRefreshPass]

    public init(
        refreshNotificationNames: Set<String> = Self.defaultRefreshNotificationNames,
        refreshPasses: [MountedVolumeSidebarRefreshPass] = Self.defaultRefreshPasses
    ) {
        self.refreshNotificationNames = refreshNotificationNames
        self.refreshPasses = refreshPasses
    }

    public func shouldRefreshSidebar(forNotificationNamed notificationName: String) -> Bool {
        refreshNotificationNames.contains(notificationName)
    }

    public func sidebarRefreshPasses(forNotificationNamed notificationName: String) -> [MountedVolumeSidebarRefreshPass] {
        guard shouldRefreshSidebar(forNotificationNamed: notificationName) else {
            return []
        }
        return refreshPasses
    }

    public static let defaultRefreshNotificationNames: Set<String> = [
        "NSWorkspaceDidMountNotification",
        "NSWorkspaceDidUnmountNotification",
        "NSWorkspaceWillUnmountNotification",
        "NSWorkspaceDidRenameVolumeNotification"
    ]

    public static let defaultRefreshPasses: [MountedVolumeSidebarRefreshPass] = [
        MountedVolumeSidebarRefreshPass(delay: 0),
        MountedVolumeSidebarRefreshPass(delay: 0.4),
        MountedVolumeSidebarRefreshPass(delay: 1.2)
    ]
}
