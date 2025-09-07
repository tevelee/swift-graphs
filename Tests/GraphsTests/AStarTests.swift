@testable import Graphs
import Testing

struct AStarTests {
    @Test func findsShortestPathWithHeuristic() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()

        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 2 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        graph.addEdge(from: b, to: d) { $0.weight = 5 }

        let path = graph.shortestPath(
            from: a,
            to: d,
            using: .aStar(
                weight: .property(\.weight),
                heuristic: .euclideanDistance(of: \.coordinates)
            )
        )
        #expect(path?.vertices == [a, c, d])

        let res = AStarAlgorithm(
            on: graph,
            from: a,
            edgeWeight: .property(\.weight),
            heuristic: .uniform(0),
            calculateTotalCost: +
        ).first { $0.currentVertex == d }
        #expect(res?.vertices(to: d, in: graph) == [a, c, d])
    }
}


