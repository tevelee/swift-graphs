import Collections

struct UnionFindConnectedComponents<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    struct Visitor {
        var discoverVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var finishComponent: (([Vertex]) -> Void)?
    }

    private let graph: Graph

    init(on graph: Graph) {
        self.graph = graph
    }

    func connectedComponents(visitor: Visitor?) -> ConnectedComponentsResult<Vertex> {
        var parent: [Vertex: Vertex] = [:]
        var rank: [Vertex: Int] = [:]
        
        // Initialize Union-Find data structure
        for vertex in graph.vertices() {
            parent[vertex] = vertex
            rank[vertex] = 0
        }
        
        // Find function with path compression
        func find(_ vertex: Vertex) -> Vertex {
            if parent[vertex] != vertex {
                parent[vertex] = find(parent[vertex]!)
            }
            return parent[vertex]!
        }
        
        // Union function with union by rank
        func union(_ x: Vertex, _ y: Vertex) {
            let rootX = find(x)
            let rootY = find(y)
            
            if rootX == rootY { return }
            
            if rank[rootX]! < rank[rootY]! {
                parent[rootX] = rootY
            } else if rank[rootX]! > rank[rootY]! {
                parent[rootY] = rootX
            } else {
                parent[rootY] = rootX
                rank[rootX]! += 1
            }
        }
        
        // Process all edges to build connected components
        for vertex in graph.vertices() {
            visitor?.discoverVertex?(vertex)
            
            for edge in graph.outgoingEdges(of: vertex) {
                visitor?.examineEdge?(edge)
                
                guard let destination = graph.destination(of: edge) else { continue }
                union(vertex, destination)
            }
        }
        
        // Group vertices by their root parent
        var components: [Vertex: [Vertex]] = [:]
        for vertex in graph.vertices() {
            let root = find(vertex)
            if components[root] == nil {
                components[root] = []
            }
            components[root]!.append(vertex)
        }
        
        // Convert to array of arrays and notify visitor
        let result = Array(components.values)
        for component in result {
            visitor?.finishComponent?(component)
        }
        
        return ConnectedComponentsResult(components: result)
    }
}

extension UnionFindConnectedComponents: ConnectedComponentsAlgorithm {
    func connectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> ConnectedComponentsResult<Graph.VertexDescriptor> {
        connectedComponents(visitor: visitor)
    }
}
