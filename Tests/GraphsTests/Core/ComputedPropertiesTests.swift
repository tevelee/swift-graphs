@testable import Graphs
import Testing

struct ComputedPropertiesTests {
    @Test func computeEdgeWeightByVertexWeightDifference() {
        var graph = AdjacencyList().withEdgeProperty(for: Weight.self) { edge, graph in
            if let u = graph.source(of: edge), let v = graph.destination(of: edge) {
                graph[v].weight - graph[u].weight
            } else  {
                0
            }
        }
        
        let a = graph.addVertex { $0.weight = 123 }
        let b = graph.addVertex { $0.weight = 456 }
        let e = graph.addEdge(from: a, to: b)!
        
        #expect(graph[e].weight == 333)
    }
    
    @Test func vertexWeights() {
        var graph = AdjacencyList().withVertexProperty(for: Weight.self) { vertex, graph in
            123
        }
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)
        
        #expect(graph[a].weight == 123)
    }
}
