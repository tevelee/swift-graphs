import Foundation

extension FloydWarshall.Visitor: Composable {
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
            updateDistance: { from, to, distance in
                self.updateDistance?(from, to, distance)
                other.updateDistance?(from, to, distance)
            },
            completeIntermediateVertex: { vertex in
                self.completeIntermediateVertex?(vertex)
                other.completeIntermediateVertex?(vertex)
            }
        )
    }
}
