import Foundation

extension BidirectionalDijkstra.Visitor: Composable {
    func combined(with other: Self) -> Self {
        .init(
            examineVertex: { vertex, direction in
                self.examineVertex?(vertex, direction)
                other.examineVertex?(vertex, direction)
            },
            examineEdge: { edge, direction in
                self.examineEdge?(edge, direction)
                other.examineEdge?(edge, direction)
            },
            edgeRelaxed: { edge, direction in
                self.edgeRelaxed?(edge, direction)
                other.edgeRelaxed?(edge, direction)
            },
            edgeNotRelaxed: { edge, direction in
                self.edgeNotRelaxed?(edge, direction)
                other.edgeNotRelaxed?(edge, direction)
            },
            meetingFound: { vertex, cost in
                self.meetingFound?(vertex, cost)
                other.meetingFound?(vertex, cost)
            }
        )
    }
}
