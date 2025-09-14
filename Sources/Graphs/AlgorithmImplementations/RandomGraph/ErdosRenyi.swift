import Foundation

struct ErdosRenyi<
    Graph: MutableGraph
> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    
    struct Visitor {
        var addVertex: ((Vertex) -> Void)?
        var addEdge: ((Vertex, Vertex) -> Void)?
        var skipEdge: ((Vertex, Vertex, String) -> Void)?
        var examineVertexPair: ((Vertex, Vertex) -> Void)?
    }
    
    struct Result {
        let graph: Graph
        let vertices: [Vertex]
        let edges: [(Vertex, Vertex)]
        let edgeProbability: Double
    }
    
    let edgeProbability: Double
    
    init(edgeProbability: Double) {
        self.edgeProbability = edgeProbability
    }
    
    func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Graph,
        vertexCount: Int,
        using generator: inout RNG,
        visitor: Visitor? = nil
    ) {
        guard vertexCount > 0 else { return }
        
        // Add vertices
        var newVertices: [Vertex] = []
        for _ in 0..<vertexCount {
            let v = graph.addVertex()
            visitor?.addVertex?(v)
            newVertices.append(v)
        }
        
        // Add edges with probability p among the newly added vertices
        for i in 0..<newVertices.count {
            for j in (i + 1)..<newVertices.count {
                visitor?.examineVertexPair?(newVertices[i], newVertices[j])
                if Double.random(in: 0...1, using: &generator) < edgeProbability {
                    _ = graph.addEdge(from: newVertices[i], to: newVertices[j])
                    visitor?.addEdge?(newVertices[i], newVertices[j])
                } else {
                    visitor?.skipEdge?(newVertices[i], newVertices[j], "Probability check failed")
                }
            }
        }
    }
}
