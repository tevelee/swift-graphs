import Foundation

extension VF2Isomorphism.Visitor: Composable {
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
            tryMapping: { vertex1, vertex2 in
                self.tryMapping?(vertex1, vertex2)
                other.tryMapping?(vertex1, vertex2)
            },
            mappingFound: { mapping in
                self.mappingFound?(mapping)
                other.mappingFound?(mapping)
            },
            backtrack: { vertex1, vertex2 in
                self.backtrack?(vertex1, vertex2)
                other.backtrack?(vertex1, vertex2)
            }
        )
    }
}
