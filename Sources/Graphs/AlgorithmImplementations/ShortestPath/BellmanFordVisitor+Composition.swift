import Foundation

extension BellmanFord.Visitor: Composable {
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
            detectNegativeCycle: { edge in
                self.detectNegativeCycle?(edge)
                other.detectNegativeCycle?(edge)
            },
            completeRelaxationIteration: { iteration in
                self.completeRelaxationIteration?(iteration)
                other.completeRelaxationIteration?(iteration)
            }
        )
    }
}
