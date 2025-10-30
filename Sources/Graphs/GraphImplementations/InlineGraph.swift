import Collections

/// A graph where vertices and edges directly contain their data.
///
/// Unlike `AdjacencyList` which uses storage descriptors and property maps,
/// `InlineGraph` uses vertex and edge types directly as both descriptors and data.
///
/// For simple graphs with `SimpleEdge`, use the convenience initializer:
///
/// ```swift
/// let graph: InlineGraph<String, SimpleEdge<String>> = InlineGraph()
/// graph.addEdge(from: "A", to: "B")
/// ```
///
/// For custom edge types with additional properties:
///
/// ```swift
/// struct WeightedEdge: EdgeProtocol {
///     let source: String
///     let destination: String
///     let weight: Double
/// }
/// let graph: InlineGraph<String, WeightedEdge> = InlineGraph()
/// ```
public struct InlineGraph<Vertex: Hashable, Edge: EdgeProtocol<Vertex>> where Edge.Vertex == Vertex {
    /// Internal storage: maps each vertex to its outgoing edges
    @usableFromInline
    var adjacency: OrderedDictionary<Vertex, [Edge]>
    
    /// Creates an empty inline graph.
    @inlinable
    public init() {
        self.adjacency = OrderedDictionary()
    }
    
    /// Creates an inline graph from a collection of edges.
    ///
    /// All vertices referenced by the edges are automatically added to the graph.
    ///
    /// - Parameter edges: A collection of edges to initialize the graph
    @inlinable
    public init<Edges: Collection<Edge>>(edges: Edges) {
        self.adjacency = OrderedDictionary()
        for edge in edges {
            adjacency[edge.source, default: []].append(edge)
            // Ensure destination vertex exists even if it has no outgoing edges
            if adjacency[edge.destination] == nil {
                adjacency[edge.destination] = []
            }
        }
    }
}

extension InlineGraph: EdgeMutableGraph where Edge == SimpleEdge<Vertex> {
    /// Adds an edge from source to destination (convenience for SimpleEdge).
    ///
    /// This method automatically creates a SimpleEdge and adds it to the graph.
    /// Both vertices are automatically added if they don't exist.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - destination: The destination vertex
    /// - Returns: The created edge
    @_disfavoredOverload
    @discardableResult
    @inlinable
    public mutating func addEdge(from source: Vertex, to destination: Vertex) -> SimpleEdge<Vertex>? {
        let edge = SimpleEdge(source: source, destination: destination)
        return addEdge(edge)
    }
}

//public struct Empty: Hashable {
//    public init() {}
//}
//
//extension InlineGraph: VertexMutableGraph where Vertex == Empty {
//    mutating public func addVertex() -> Empty {
//        Empty()
//    }
//}

extension InlineGraph where Edge: Equatable {
    /// Adds an edge to the graph.
    ///
    /// The edge must be constructed by the caller. Both source and destination vertices
    /// are automatically added to the graph if they don't exist.
    ///
    /// - Parameter edge: The edge to add
    /// - Returns: The edge descriptor (the edge itself)
    @discardableResult
    @inlinable
    public mutating func addEdge(_ edge: Edge) -> Edge {
        adjacency[edge.source, default: []].append(edge)
        // Ensure destination vertex exists even if it has no outgoing edges
        if adjacency[edge.destination] == nil {
            adjacency[edge.destination] = []
        }
        return edge
    }
    
#if swift(>=6.2)
    /// Removes an edge from the graph.
    ///
    /// - Parameter edge: The edge to remove
    @inlinable
    public mutating func remove(edge: consuming Edge) {
        if let edges = adjacency[edge.source] {
            adjacency[edge.source] = edges.filter { $0 != edge }
        }
    }
#else
    /// Removes an edge from the graph.
    ///
    /// - Parameter edge: The edge to remove
    @inlinable
    public mutating func remove(edge: Edge) {
        if let edges = adjacency[edge.source] {
            adjacency[edge.source] = edges.filter { $0 != edge }
        }
    }
#endif
}

extension InlineGraph where Edge == SimpleEdge<Vertex> {
    /// Creates an empty inline graph with SimpleEdge as the edge type.
    ///
    /// This convenience initializer allows you to create a graph by specifying only the vertex type:
    ///
    /// ```swift
    /// var graph: InlineGraph<String> = InlineGraph()
    /// // or with type inference:
    /// let graph: InlineGraph<String> = .init()
    /// ```
    @inlinable
    public init() {
        self.adjacency = OrderedDictionary()
    }
    
    /// Creates an inline graph with simple edges from a list of vertex pairs.
    ///
    /// This convenience initializer allows you to create a graph from edge pairs:
    ///
    /// ```swift
    /// let graph: InlineGraph<String> = InlineGraph(edges: [
    ///     ("A", "B"),
    ///     ("B", "C")
    /// ])
    /// ```
    ///
    /// - Parameter edges: An array of (source, destination) tuples
    @inlinable
    public init(edges: [(source: Vertex, destination: Vertex)]) {
        self.init(edges: edges.map { SimpleEdge(source: $0.source, destination: $0.destination) })
    }
    
    /// Adds an edge from source to destination (convenience for SimpleEdge).
    ///
    /// This method automatically creates a SimpleEdge and adds it to the graph.
    /// Both vertices are automatically added if they don't exist.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - destination: The destination vertex
    /// - Returns: The created edge
    @discardableResult
    @inlinable
    public mutating func addEdge(from source: Vertex, to destination: Vertex) -> SimpleEdge<Vertex> {
        let edge = SimpleEdge(source: source, destination: destination)
        return addEdge(edge)
    }
}

extension InlineGraph: Graph {
    public typealias VertexDescriptor = Vertex
    public typealias EdgeDescriptor = Edge
}

extension InlineGraph: IncidenceGraph {
    public typealias OutgoingEdges = [Edge]
    
    @inlinable
    public func outgoingEdges(of vertex: Vertex) -> [Edge] {
        adjacency[vertex] ?? []
    }
    
    @inlinable
    public func source(of edge: Edge) -> Vertex? {
        edge.source
    }
    
    @inlinable
    public func destination(of edge: Edge) -> Vertex? {
        edge.destination
    }
    
    @inlinable
    public func outDegree(of vertex: Vertex) -> Int {
        adjacency[vertex]?.count ?? 0
    }
}

extension InlineGraph: VertexListGraph {
    @inlinable
    public func vertices() -> OrderedSet<Vertex> {
        OrderedSet(adjacency.keys)
    }
    
    @inlinable
    public var vertexCount: Int {
        adjacency.count
    }
}

extension InlineGraph: EdgeListGraph {
    public typealias Edges = [Edge]
    
    @inlinable
    public func edges() -> [Edge] {
        adjacency.values.flatMap { $0 }
    }
    
    @inlinable
    public var edgeCount: Int {
        adjacency.values.reduce(0) { $0 + $1.count }
    }
}

extension InlineGraph {
    /// Adds a specific vertex to the graph.
    ///
    /// If the vertex already exists, this operation has no effect.
    ///
    /// - Parameter vertex: The vertex to add
    /// - Returns: The vertex descriptor (the vertex itself)
    @discardableResult
    @inlinable
    public mutating func addVertex(_ vertex: Vertex) -> Vertex {
        if adjacency[vertex] == nil {
            adjacency[vertex] = []
        }
        return vertex
    }
    
#if swift(>=6.2)
    /// Removes a vertex from the graph.
    ///
    /// This also removes all edges to and from this vertex.
    ///
    /// - Parameter vertex: The vertex to remove
    @inlinable
    public mutating func remove(vertex: consuming Vertex) {
        adjacency.removeValue(forKey: vertex)
        // Remove all edges pointing to this vertex
        for key in adjacency.keys {
            adjacency[key]?.removeAll { edge in
                edge.destination == vertex
            }
        }
    }
#else
    /// Removes a vertex from the graph.
    ///
    /// This also removes all edges to and from this vertex.
    ///
    /// - Parameter vertex: The vertex to remove
    @inlinable
    public mutating func remove(vertex: Vertex) {
        adjacency.removeValue(forKey: vertex)
        // Remove all edges pointing to this vertex
        for key in adjacency.keys {
            adjacency[key]?.removeAll { edge in
                edge.destination == vertex
            }
        }
    }
#endif
}

extension InlineGraph: AdjacencyGraph {
    public typealias AdjacentVertices = LazyMapSequence<[Edge], Vertex>
    
    @inlinable
    public func adjacentVertices(of vertex: Vertex) -> LazyMapSequence<[Edge], Vertex> {
        outgoingEdges(of: vertex).lazy.map { $0.destination }
    }
}

