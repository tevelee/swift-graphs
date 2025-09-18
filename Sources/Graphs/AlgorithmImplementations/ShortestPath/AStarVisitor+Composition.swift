import Foundation

extension AStar.Visitor: Composable {
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
            edgeRelaxed: { edge in
                self.edgeRelaxed?(edge)
                other.edgeRelaxed?(edge)
            },
            edgeNotRelaxed: { edge in
                self.edgeNotRelaxed?(edge)
                other.edgeNotRelaxed?(edge)
            },
            finishVertex: { vertex in
                self.finishVertex?(vertex)
                other.finishVertex?(vertex)
            }
        )
    }
}
