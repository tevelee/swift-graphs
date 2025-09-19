import Foundation

extension Kosaraju.Visitor: Composable {
    func combined(with other: Self) -> Self {
        .init(
            discoverVertex: { vertex in
                self.discoverVertex?(vertex)
                other.discoverVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            finishVertex: { vertex in
                self.finishVertex?(vertex)
                other.finishVertex?(vertex)
            },
            startComponent: { vertex in
                self.startComponent?(vertex)
                other.startComponent?(vertex)
            },
            finishComponent: { component in
                self.finishComponent?(component)
                other.finishComponent?(component)
            }
        )
    }
}
