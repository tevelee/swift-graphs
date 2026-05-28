#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
/// Hierholzer's algorithm for finding Eulerian paths and cycles.
///
/// Hierholzer's algorithm finds an Eulerian path or cycle in a graph by building
/// the path incrementally and backtracking when necessary. It works by starting
/// from a vertex and following edges until no more edges are available, then
/// backtracking to find unused edges.
///
/// - Complexity: O(E) where E is the number of edges
public struct Hierholzer<Graph: BidirectionalGraph & VertexListGraph>
where Graph.VertexDescriptor: Hashable {
    
    /// Creates a new Hierholzer algorithm instance.
    @inlinable
    public init() {}
    
    /// A visitor that can be used to observe Hierholzer's algorithm progress.
    public struct Visitor {
        /// Called when examining a vertex.
        public var examineVertex: ((Graph.VertexDescriptor) -> Void)?
        /// Called when examining an edge.
        public var examineEdge: ((Graph.EdgeDescriptor) -> Void)?
        /// Called when adding a vertex to the path.
        public var addToPath: ((Graph.VertexDescriptor) -> Void)?
        /// Called when adding an edge to the path.
        public var addEdgeToPath: ((Graph.EdgeDescriptor) -> Void)?
        /// Called when backtracking.
        public var backtrack: ((Graph.VertexDescriptor) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            examineVertex: ((Graph.VertexDescriptor) -> Void)? = nil,
            examineEdge: ((Graph.EdgeDescriptor) -> Void)? = nil,
            addToPath: ((Graph.VertexDescriptor) -> Void)? = nil,
            addEdgeToPath: ((Graph.EdgeDescriptor) -> Void)? = nil,
            backtrack: ((Graph.VertexDescriptor) -> Void)? = nil
        ) {
            self.examineVertex = examineVertex
            self.examineEdge = examineEdge
            self.addToPath = addToPath
            self.addEdgeToPath = addEdgeToPath
            self.backtrack = backtrack
        }
    }
    
    /// Finds an Eulerian path in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to find the Eulerian path in.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: An Eulerian path, if one exists.
    @inlinable
    public func eulerianPath(in graph: Graph, visitor: Visitor? = nil) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        guard graph.hasEulerianPath() else { return nil }
        
        let vertices = Array(graph.vertices())
        
        // Handle empty graph
        if vertices.isEmpty {
            return nil
        }
        
        // Handle single vertex with no edges
        if vertices.count == 1 {
            let vertex = vertices[0]
            if graph.degree(of: vertex) == 0 {
                return Path(source: vertex, destination: vertex, vertices: [vertex], edges: [])
            }
        }
        
        // Find starting vertex (odd degree vertex if exists, otherwise any vertex)
        var startVertex: Graph.VertexDescriptor?
        
        for vertex in vertices {
            if graph.degree(of: vertex) % 2 == 1 {
                startVertex = vertex
                break
            }
        }
        
        // If no odd degree vertex, start from any vertex
        startVertex = startVertex ?? vertices.first
        
        guard let start = startVertex else { return nil }
        
        return findEulerianPath(from: start, in: graph, visitor: visitor)
    }
    
    /// Finds an Eulerian cycle in the graph.
    ///
    /// - Parameters:
    ///   - graph: The graph to find the Eulerian cycle in.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: An Eulerian cycle, if one exists.
    @inlinable
    public func eulerianCycle(in graph: Graph, visitor: Visitor? = nil) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        guard graph.hasEulerianCycle() else { return nil }
        
        let vertices = Array(graph.vertices())
        
        // Handle empty graph
        if vertices.isEmpty {
            return nil
        }
        
        // Handle single vertex with no edges
        if vertices.count == 1 {
            let vertex = vertices[0]
            if graph.degree(of: vertex) == 0 {
                let result = Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>(source: vertex, destination: vertex, vertices: [vertex], edges: [])
                return result
            }
        }
        
        guard let startVertex = vertices.first else { return nil }
        
        return findEulerianPath(from: startVertex, in: graph, visitor: visitor)
    }
    
    /// Finds an Eulerian path starting from a specific vertex.
    ///
    /// - Parameters:
    ///   - start: The starting vertex.
    ///   - graph: The graph to find the path in.
    ///   - visitor: An optional visitor to observe the algorithm's progress.
    /// - Returns: An Eulerian path, if one exists.
    @usableFromInline
    func findEulerianPath(
        from start: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>? {
        // Each stack entry records the vertex and the edge used to arrive there.
        // Tracking the incoming edge avoids the post-hoc graph search that breaks
        // for multigraphs (multiple edges between the same pair of vertices).
        var pathPairs: [(vertex: Graph.VertexDescriptor, incomingEdge: Graph.EdgeDescriptor?)] = []

        var adjacency: [Graph.VertexDescriptor: [Graph.EdgeDescriptor]] = [:]
        for vertex in graph.vertices() {
            visitor?.examineVertex?(vertex)
            adjacency[vertex] = Array(graph.outgoingEdges(of: vertex))
        }

        var stack: [(vertex: Graph.VertexDescriptor, incomingEdge: Graph.EdgeDescriptor?)] = [(start, nil)]
        visitor?.examineVertex?(start)

        while !stack.isEmpty {
            let current = stack.last!.vertex

            if let nextEdge = adjacency[current]?.first {
                visitor?.examineEdge?(nextEdge)
                adjacency[current]?.removeFirst()

                guard let nextVertex = graph.destination(of: nextEdge) else { continue }

                stack.append((nextVertex, nextEdge))
                visitor?.examineVertex?(nextVertex)
            } else {
                let popped = stack.removeLast()
                pathPairs.append(popped)
                visitor?.addToPath?(popped.vertex)
                visitor?.backtrack?(popped.vertex)
            }
        }

        pathPairs.reverse()

        let path = pathPairs.map(\.vertex)
        // The start vertex has no incoming edge; all subsequent entries do.
        let edges: [Graph.EdgeDescriptor] = pathPairs.dropFirst().compactMap(\.incomingEdge)
        for edge in edges {
            visitor?.addEdgeToPath?(edge)
        }

        guard let first = path.first, let last = path.last else { return nil }
        return Path(source: first, destination: last, vertices: path, edges: edges)
    }
}

extension Hierholzer: VisitorSupporting {}
#endif
