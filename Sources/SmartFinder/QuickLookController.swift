import Foundation
import Quartz

@MainActor
final class QuickLookController: NSObject,
    @preconcurrency QLPreviewPanelDataSource,
    QLPreviewPanelDelegate {
    private var urls: [URL] = []

    func preview(urls: [URL]) {
        self.urls = urls
        guard let panel = QLPreviewPanel.shared() else {
            return
        }
        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.makeKeyAndOrderFront(nil)
    }

    func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        urls.count
    }

    func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        urls[index] as NSURL
    }
}
