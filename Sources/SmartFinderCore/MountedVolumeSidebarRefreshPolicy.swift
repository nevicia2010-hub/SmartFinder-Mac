public struct MountedVolumeSidebarRefreshPolicy {
    private let refreshNotificationNames: Set<String>

    public init(refreshNotificationNames: Set<String> = Self.defaultRefreshNotificationNames) {
        self.refreshNotificationNames = refreshNotificationNames
    }

    public func shouldRefreshSidebar(forNotificationNamed notificationName: String) -> Bool {
        refreshNotificationNames.contains(notificationName)
    }

    public static let defaultRefreshNotificationNames: Set<String> = [
        "NSWorkspaceDidMountNotification",
        "NSWorkspaceDidUnmountNotification",
        "NSWorkspaceDidRenameVolumeNotification"
    ]
}
