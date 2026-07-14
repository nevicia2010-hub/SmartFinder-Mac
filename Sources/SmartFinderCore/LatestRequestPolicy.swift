import Foundation

public enum LatestRequestPolicy {
    public static func shouldApply(
        requestID: UUID,
        currentRequestID: UUID,
        requestedURL: URL,
        currentURL: URL?
    ) -> Bool {
        requestID == currentRequestID &&
            requestedURL.standardizedFileURL == currentURL?.standardizedFileURL
    }
}
