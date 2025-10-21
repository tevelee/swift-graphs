/// Barabasi-Albert random graph generation algorithm.
///
/// This algorithm generates scale-free networks using preferential attachment.
/// New vertices are more likely to connect to vertices with higher degrees.
///
/// - Complexity: O(V * k) where V is the number of vertices and k is the average degree
public struct BarabasiAlbert<
    Graph: MutableGraph & BidirectionalGraph
> where Graph.VertexDescriptor: Hashable {
    /// The vertex type of the graph.
    public typealias Vertex = Graph.VertexDescriptor
    
    /// A visitor that can be used to observe the Barabasi-Albert algorithm progress.
    public struct Visitor {
        /// Called when adding a vertex.
        public var addVertex: ((Vertex) -> Void)?
        /// Called when adding an edge.
        public var addEdge: ((Vertex, Vertex) -> Void)?
        /// Called when selecting a target vertex.
        public var selectTarget: ((Vertex, [Vertex]) -> Void)?
        /// Called when updating a vertex degree.
        public var updateDegree: ((Vertex, Int) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            addVertex: ((Vertex) -> Void)? = nil,
            addEdge: ((Vertex, Vertex) -> Void)? = nil,
            selectTarget: ((Vertex, [Vertex]) -> Void)? = nil,
            updateDegree: ((Vertex, Int) -> Void)? = nil
        ) {
            self.addVertex = addVertex
            self.addEdge = addEdge
            self.selectTarget = selectTarget
            self.updateDegree = updateDegree
        }
    }
    
    /// The result of the Barabasi-Albert algorithm.
    @usableFromInline
    struct Result {
        @usableFromInline
        let graph: Graph
        @usableFromInline
        let vertices: [Vertex]
        @usableFromInline
        let edges: [(Vertex, Vertex)]
        @usableFromInline
        let degreeDistribution: [Vertex: Int]
    }
    
    /// The target average degree for the generated graph.
    @usableFromInline
    let averageDegree: Double
    
    /// Creates a new Barabasi-Albert algorithm.
    ///
    /// - Parameter averageDegree: The target average degree for the generated graph
    @inlinable
    public init(averageDegree: Double) {
        self.averageDegree = averageDegree
    }
    
    /// Appends a random Barabasi-Albert graph to an existing graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to append to (modified in place)
    ///   - vertexCount: The number of vertices to add
    ///   - generator: The random number generator to use
    ///   - visitor: An optional visitor to observe the algorithm progress
    @inlinable
    public func appendRandomGraph<RNG: RandomNumberGenerator>(
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
    
    @usableFromInline
    func selectVertexByPreferentialAttachment<RNG: RandomNumberGenerator>(
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
