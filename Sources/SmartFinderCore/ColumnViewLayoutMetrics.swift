public struct ColumnViewFrame: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct ColumnViewLayout: Equatable, Sendable {
    public let documentWidth: Double
    public let documentHeight: Double
    public let columnFrames: [ColumnViewFrame]

    public init(documentWidth: Double, documentHeight: Double, columnFrames: [ColumnViewFrame]) {
        self.documentWidth = documentWidth
        self.documentHeight = documentHeight
        self.columnFrames = columnFrames
    }
}

public enum ColumnViewLayoutMetrics {
    public static let minimumDocumentHeight: Double = 500

    public static func layout(
        columnCount: Int,
        columnWidth: Double,
        viewportHeight: Double,
        minimumDocumentHeight: Double = Self.minimumDocumentHeight
    ) -> ColumnViewLayout {
        let visibleColumnCount = max(columnCount, 1)
        let documentHeight = max(viewportHeight, minimumDocumentHeight)
        let frames = (0..<max(columnCount, 0)).map { index in
            ColumnViewFrame(
                x: Double(index) * columnWidth,
                y: 0,
                width: columnWidth,
                height: documentHeight
            )
        }

        return ColumnViewLayout(
            documentWidth: Double(visibleColumnCount) * columnWidth,
            documentHeight: documentHeight,
            columnFrames: frames
        )
    }
}
