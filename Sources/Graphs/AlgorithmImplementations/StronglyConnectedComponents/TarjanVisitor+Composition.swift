import Foundation

extension Tarjan.Visitor: Composable {
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
            backEdge: { edge in
                self.backEdge?(edge)
                other.backEdge?(edge)
            },
            crossEdge: { edge in
                self.crossEdge?(edge)
                other.crossEdge?(edge)
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
