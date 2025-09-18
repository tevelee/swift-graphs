import Foundation

extension Kruskal.Visitor: Composable {
    func combined(with other: Self) -> Self {
        .init(
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
            },
            unionVertices: { vertex1, vertex2 in
                self.unionVertices?(vertex1, vertex2)
                other.unionVertices?(vertex1, vertex2)
            }
        )
    }
}
