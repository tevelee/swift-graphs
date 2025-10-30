@testable import Graphs
import Testing

struct BestFirstTests {
    @Test func greedyBestFirst_OrdersByHeuristic() {
        var graph = AdjacencyList()
        graph.addEdges(providing: \.label) {
            ("s", "a")
            ("s", "b")
            ("a", "c")
            ("b", "d")
        }

        // Heuristic that favors 'b' branch first
        let order: [String: UInt] = ["s": 0, "b": 1, "d": 2, "a": 3, "c": 4]
        let result = graph.traverse(from: "s", using: .bestFirst(heuristic: .init { v, g in
            order[g[v].label] ?? 999
        }))

        let labels = result.vertexLabels(in: graph)
        #expect(labels == ["s", "b", "d", "a", "c"])
    }
}


