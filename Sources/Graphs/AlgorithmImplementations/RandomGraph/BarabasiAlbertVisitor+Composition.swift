import Foundation

extension BarabasiAlbert.Visitor: Composable {
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
            selectTarget: { vertex, candidates in
                self.selectTarget?(vertex, candidates)
                other.selectTarget?(vertex, candidates)
            },
            updateDegree: { vertex, degree in
                self.updateDegree?(vertex, degree)
                other.updateDegree?(vertex, degree)
            }
        )
    }
}
