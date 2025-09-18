import Foundation

extension WelshPowellColoringAlgorithm.Visitor: Composable {
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
            assignColor: { vertex, color in
                self.assignColor?(vertex, color)
                other.assignColor?(vertex, color)
            },
            skipVertex: { vertex, reason in
                self.skipVertex?(vertex, reason)
                other.skipVertex?(vertex, reason)
            }
        )
    }
}
