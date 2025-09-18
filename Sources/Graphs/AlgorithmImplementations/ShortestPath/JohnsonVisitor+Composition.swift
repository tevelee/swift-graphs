import Foundation

extension Johnson.Visitor: Composable {
    func combined(with other: Self) -> Self {
        .init(
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            reweightEdge: { edge, weight in
                self.reweightEdge?(edge, weight)
                other.reweightEdge?(edge, weight)
            },
            startDijkstraFromSource: { vertex in
                self.startDijkstraFromSource?(vertex)
                other.startDijkstraFromSource?(vertex)
            },
            completeDijkstraFromSource: { vertex in
                self.completeDijkstraFromSource?(vertex)
                other.completeDijkstraFromSource?(vertex)
            },
            detectNegativeCycle: {
                self.detectNegativeCycle?()
                other.detectNegativeCycle?()
            }
        )
    }
}
