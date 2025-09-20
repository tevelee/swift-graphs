import Foundation

extension Kahn.Visitor: Composable {
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
            detectCycle: { vertices in
                self.detectCycle?(vertices)
                other.detectCycle?(vertices)
            }
        )
    }
}
