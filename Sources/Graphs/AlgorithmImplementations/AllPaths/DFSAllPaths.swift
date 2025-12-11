import Collections

extension AllPathsAlgorithm {
    /// Returns a Depth-First Search (DFS) based all-paths algorithm.
    @inlinable
    public static func dfs<G>() -> Self where Self == DFSAllPathsAlgorithm<G>, Graph == G {
        .init()
    }
}

/// An algorithm factory that produces a DFS-based sequence of all paths.
public struct DFSAllPathsAlgorithm<Graph: IncidenceGraph>: AllPathsAlgorithm where Graph.VertexDescriptor: Hashable {
    @inlinable
    public init() {}

    @inlinable
    public func allPaths(
        from source: Graph.VertexDescriptor,
        to destination: Graph.VertexDescriptor,
        in graph: Graph
    ) -> DFSAllPaths<Graph> {
        DFSAllPaths(graph: graph, source: source, destination: destination)
    }
}

/// A sequence that lazily finds all simple paths between two vertices using Depth-First Search.
public struct DFSAllPaths<Graph: IncidenceGraph>: Sequence where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor
    
    @usableFromInline
    let graph: Graph
    @usableFromInline
    let source: Vertex
    @usableFromInline
    let destination: Vertex
    
    @inlinable
    public init(graph: Graph, source: Vertex, destination: Vertex) {
        self.graph = graph
        self.source = source
        self.destination = destination
    }
    
    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(graph: graph, source: source, destination: destination)
    }
    
    public struct Iterator: IteratorProtocol {
        @usableFromInline
        let graph: Graph
        @usableFromInline
        let destination: Vertex
        
        // Stack holds the vertex and the iterator for its outgoing edges
        @usableFromInline
        struct StackFrame {
            @usableFromInline
            let vertex: Vertex
            @usableFromInline
            var edges: Graph.OutgoingEdges.Iterator
            
            @inlinable
            init(vertex: Vertex, edges: Graph.OutgoingEdges.Iterator) {
                self.vertex = vertex
                self.edges = edges
            }
        }
        
        @usableFromInline
        var stack: [StackFrame] = []
        
        @usableFromInline
        var visited: Set<Vertex> = []
        
        @usableFromInline
        var pathVertices: [Vertex] = []
        
        @usableFromInline
        var pathEdges: [Edge] = []
        
        @inlinable
        public init(graph: Graph, source: Vertex, destination: Vertex) {
            self.graph = graph
            self.destination = destination
            
            // Initialize with source
            let edges = graph.outgoingEdges(of: source).makeIterator()
            self.stack.append(StackFrame(vertex: source, edges: edges))
            self.visited.insert(source)
            self.pathVertices.append(source)
        }
        
        @inlinable
        public mutating func next() -> Path<Vertex, Edge>? {
            while !stack.isEmpty {
                // Get reference to current frame to mutate iterator
                let index = stack.count - 1
                
                guard let edge = stack[index].edges.next() else {
                    // No more edges for this vertex, backtrack
                    let popped = stack.removeLast()
                    visited.remove(popped.vertex)
                    pathVertices.removeLast()
                    if !pathEdges.isEmpty {
                        pathEdges.removeLast()
                    }
                    continue
                }
                
                guard let neighbor = graph.destination(of: edge) else { continue }
                
                if neighbor == destination {
                    // Found a path
                    // We don't recurse into destination for "simple paths from a to b"
                    // (if we did, we'd need to handle cycles involving destination carefully, 
                    // but typically we stop at destination)
                    
                    let path = Path(
                        source: pathVertices.first!,
                        destination: destination,
                        vertices: pathVertices + [destination],
                        edges: pathEdges + [edge]
                    )
                    
                    return path
                }
                
                if !visited.contains(neighbor) {
                    // Recurse
                    visited.insert(neighbor)
                    pathVertices.append(neighbor)
                    pathEdges.append(edge)
                    let neighborEdges = graph.outgoingEdges(of: neighbor).makeIterator()
                    stack.append(StackFrame(vertex: neighbor, edges: neighborEdges))
                }
            }
            
            return nil
        }
    }
}
