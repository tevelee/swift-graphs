@testable import Graphs
import Testing

struct BestFirstTests {
    @Test func greedyBestFirst_OrdersByHeuristic() {
        typealias G = AdjacencyList<OVS, CacheInOutEdges<OES>, DictionaryPropertyMap<OVS.Vertex, VertexPropertyValues>, DictionaryPropertyMap<OES.Edge, EdgePropertyValues>>
        var graph = G(edgeStorage: OES().cacheInOutEdges())
        graph.add(edges: [
            ("s", "a"),
            ("s", "b"),
            ("a", "c"),
            ("b", "d"),
        ])

        // Heuristic that favors 'b' branch first
        let order: [String: UInt] = ["s": 0, "b": 1, "d": 2, "a": 3, "c": 4]
        let result = graph.traverse(from: "s", using: .bestFirst(heuristic: .init { v, g in
            order[g[v].label] ?? 999
        }))

        let labels = result.verticeLabels(in: graph)
        #expect(labels == ["s", "b", "d", "a", "c"])
    }
}


