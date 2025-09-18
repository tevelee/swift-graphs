import Foundation

extension ErdosRenyi.Visitor: Composable {
    func combined(with other: Self) -> Self {
        .init(
            addVertex: { vertex in
                self.addVertex?(vertex)
                other.addVertex?(vertex)
            },
            addEdge: { from, to in
                self.addEdge?(from, to)
                other.addEdge?(from, to)
            },
            skipEdge: { from, to, reason in
                self.skipEdge?(from, to, reason)
                other.skipEdge?(from, to, reason)
            },
            examineVertexPair: { from, to in
                self.examineVertexPair?(from, to)
                other.examineVertexPair?(from, to)
            }
        )
    }
}
