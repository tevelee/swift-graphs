import Foundation

extension Prim.Visitor: Composable {
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
            addEdge: { edge, weight in
                self.addEdge?(edge, weight)
                other.addEdge?(edge, weight)
            },
            skipEdge: { edge, reason in
                self.skipEdge?(edge, reason)
                other.skipEdge?(edge, reason)
            }
        )
    }
}
