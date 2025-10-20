import Collections

/// Union-Find based connected components algorithm.
///
/// This algorithm finds connected components using the Union-Find data structure.
/// It processes edges to union vertices and then groups them by their root.
///
/// - Complexity: O(V + E α(V)) where V is the number of vertices, E is the number of edges, and α is the inverse Ackermann function
public struct UnionFindConnectedComponents<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    /// The edge type of the graph.
    public typealias Edge = Graph.EdgeDescriptor

    /// A visitor that can be used to observe the Union-Find connected components algorithm progress.
    public struct Visitor {
        /// Called when discovering a vertex.
        public var discoverVertex: ((Vertex) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Edge) -> Void)?
        /// Called when finishing a component.
        public var finishComponent: (([Vertex]) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            discoverVertex: ((Vertex) -> Void)? = nil,
            examineEdge: ((Edge) -> Void)? = nil,
            finishComponent: (([Vertex]) -> Void)? = nil
        ) {
            self.discoverVertex = discoverVertex
            self.examineEdge = examineEdge
            self.finishComponent = finishComponent
        }
    }

    /// The graph to find connected components in.
    @usableFromInline
    let graph: Graph

    /// Creates a new Union-Find connected components algorithm.
    ///
    /// - Parameter graph: The graph to find connected components in
    @inlinable
    public init(on graph: Graph) {
        self.graph = graph
    }

    /// Finds connected components using Union-Find.
    ///
    /// - Parameter visitor: An optional visitor to observe the algorithm progress
    /// - Returns: The connected components result
    @inlinable
    public func connectedComponents(visitor: Visitor?) -> ConnectedComponentsResult<Vertex> {
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
    @inlinable
    public func connectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> ConnectedComponentsResult<Graph.VertexDescriptor> {
        connectedComponents(visitor: visitor)
    }
}
