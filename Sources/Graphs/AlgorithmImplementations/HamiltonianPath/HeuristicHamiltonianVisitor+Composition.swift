import Foundation

extension HeuristicHamiltonian.Visitor: Composable {
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
            addToPath: { vertex in
                self.addToPath?(vertex)
                other.addToPath?(vertex)
            },
            removeFromPath: { vertex in
                self.removeFromPath?(vertex)
                other.removeFromPath?(vertex)
            },
            backtrack: { vertex in
                self.backtrack?(vertex)
                other.backtrack?(vertex)
            }
        )
    }
}
