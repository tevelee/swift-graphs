@testable import Graphs
import Testing

struct DijkstraTests {
    @Test func findsShortestPathAndFinalCosts() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let e = graph.addEdge(from: a, to: b) { $0.weight = 2 }!

        #expect(graph.shortestPath(from: a, to: b, using: .dijkstra(weight: \.weight))?.vertices == [a, b])

        let res = DijkstraAlgorithm(on: graph, from: a, edgeWeight: \.weight).reduce(into: nil) { $0 = $1 }
        #expect(res?.distance(of: b) == 2.0)
        #expect(res?.vertices(to: b, in: graph) == [a, b])
        #expect(graph[e].weight == 2)
    }
}


