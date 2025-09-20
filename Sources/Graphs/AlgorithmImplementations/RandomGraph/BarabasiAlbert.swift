import Foundation

struct BarabasiAlbert<
    Graph: MutableGraph & BidirectionalGraph
> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    
    struct Visitor {
        var addVertex: ((Vertex) -> Void)?
        var addEdge: ((Vertex, Vertex) -> Void)?
        var selectTarget: ((Vertex, [Vertex]) -> Void)?
        var updateDegree: ((Vertex, Int) -> Void)?
    }
    
    struct Result {
        let graph: Graph
        let vertices: [Vertex]
        let edges: [(Vertex, Vertex)]
        let degreeDistribution: [Vertex: Int]
    }
    
    let averageDegree: Double
    
    init(averageDegree: Double) {
        self.averageDegree = averageDegree
    }
    
    func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Graph,
        vertexCount: Int,
        using generator: inout RNG,
        visitor: Visitor? = nil
    ) {
        guard vertexCount > 0 else { return }
        
        // If the graph is empty, start by adding one vertex to seed preferential attachment
        var vertices: [Vertex] = []
        for _ in 0..<vertexCount {
            let newVertex = graph.addVertex()
            visitor?.addVertex?(newVertex)
            vertices.append(newVertex)
            
            // Calculate number of edges to add for this vertex
            let targetEdges = max(1, min(vertices.count - 1, Int(averageDegree)))
            
            // Preferential attachment among existing vertices (excluding the new one)
            if vertices.count > 1 {
                for _ in 0..<targetEdges {
                    if let target = selectVertexByPreferentialAttachment(
                        from: vertices.dropLast(),
                        using: &generator,
                        visitor: visitor,
                        graph: graph
                    ) {
                        graph.addEdge(from: newVertex, to: target)
                        visitor?.addEdge?(newVertex, target)
                    }
                }
            }
        }
    }
    
    private func selectVertexByPreferentialAttachment<RNG: RandomNumberGenerator>(
        from vertices: ArraySlice<Vertex>,
        using generator: inout RNG,
        visitor: Visitor?,
        graph: Graph
    ) -> Vertex? {
        guard !vertices.isEmpty else { return nil }
        
        // Compute degrees on the fly
        let degrees = vertices.map { graph.degree(of: $0) }
        let totalDegree = degrees.reduce(0, +)
        
        if totalDegree == 0 {
            return vertices.randomElement(using: &generator)
        }
        
        let threshold = Int.random(in: 0..<max(1, totalDegree), using: &generator)
        var cumulative = 0
        for (index, v) in vertices.enumerated() {
            cumulative += degrees[index]
            if threshold < cumulative { return v }
        }
        return vertices.last
    }
}

extension BarabasiAlbert: VisitorSupporting {}
