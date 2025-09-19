import Foundation

extension UnionFindConnectedComponents.Visitor: Composable {
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
            finishComponent: { component in
                self.finishComponent?(component)
                other.finishComponent?(component)
            }
        )
    }
}
