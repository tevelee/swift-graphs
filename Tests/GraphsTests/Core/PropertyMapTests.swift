@testable import Graphs
import Testing

struct PropertyMapTests {
    @Test func defaultsAndMutationOnVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        #expect(graph[a].weight == 1.0)
        #expect(graph[b].weight == 1.0)
        graph[a].weight = 2
        #expect(graph[a].weight == 2)
        #expect(graph[b].weight == 1.0)
    }

    @Test func edgePropertiesIndependentFromVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let e = graph.addEdge(from: a, to: b)!
        #expect(graph[e].weight == 1.0)
        graph[e].weight = 5
        #expect(graph[e].weight == 5)
    }

    @Test func customLabelPropertyViaMap() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        enum CustomLabel: VertexProperty { static let defaultValue = "" }
        var map = graph.makeVertexPropertyMap()
        #expect(map[a][CustomLabel.self] == "")
        map[a][CustomLabel.self] = "a"
        #expect(map[a][CustomLabel.self] == "a")
    }
}


