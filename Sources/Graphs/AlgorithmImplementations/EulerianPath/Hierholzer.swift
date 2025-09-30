import Foundation

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
        var path: [Graph.VertexDescriptor] = []
        var edges: [Graph.EdgeDescriptor] = []
        
        // Create adjacency list with available edges
        var adjacency: [Graph.VertexDescriptor: [Graph.EdgeDescriptor]] = [:]
        let vertices = Array(graph.vertices())
        
        for vertex in vertices {
            visitor?.examineVertex?(vertex)
            adjacency[vertex] = Array(graph.outgoingEdges(of: vertex))
        }
        
        // Hierholzer's algorithm
        var current = start
        var stack: [Graph.VertexDescriptor] = [current]
        visitor?.examineVertex?(current)
        
        while !stack.isEmpty {
            if let nextEdge = adjacency[current]?.first {
                visitor?.examineEdge?(nextEdge)
                
                // Move to next vertex
                guard let nextVertex = graph.destination(of: nextEdge) else { 
                    adjacency[current]?.removeFirst()
                    continue 
                }
                
                // Remove the used edge
                adjacency[current]?.removeFirst()
                
                stack.append(nextVertex)
                current = nextVertex
                visitor?.examineVertex?(current)
            } else {
                // No more edges from current vertex, add to path
                let vertexToAdd = stack.removeLast()
                path.append(vertexToAdd)
                visitor?.addToPath?(vertexToAdd)
                visitor?.backtrack?(vertexToAdd)
                
                if !stack.isEmpty {
                    current = stack.last!
                }
            }
        }
        
        // Reverse to get correct order
        path.reverse()
        
        // Build edge list
        for i in 0..<(path.count - 1) {
            let from = path[i]
            let to = path[i + 1]
            
            // Find edge between from and to
            if let edge = graph.outgoingEdges(of: from).first(where: { 
                graph.destination(of: $0) == to 
            }) {
                edges.append(edge)
                visitor?.addEdgeToPath?(edge)
            }
        }
        
        guard path.count > 0 else { return nil }
        
        let result = Path(
            source: path.first!,
            destination: path.last!,
            vertices: path,
            edges: edges
        )
        return result
    }
}

extension Hierholzer: VisitorSupporting {}

