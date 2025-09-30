/// A path in a graph represented as a sequence of vertices and edges.
///
/// A path connects a source vertex to a destination vertex through a sequence
/// of intermediate vertices and the edges that connect them.
public struct Path<Vertex, Edge> {
    /// The starting vertex of the path.
    public let source: Vertex
    
    /// The ending vertex of the path.
    public let destination: Vertex
    
    /// The sequence of vertices in the path, including source and destination.
    public let vertices: [Vertex]
    
    /// The sequence of edges in the path.
    public let edges: [Edge]
    
    /// Creates a new path.
    ///
    /// - Parameters:
    ///   - source: The starting vertex
    ///   - destination: The ending vertex
    ///   - vertices: The sequence of vertices in the path
    ///   - edges: The sequence of edges in the path
    @inlinable
    public init(source: Vertex, destination: Vertex, vertices: [Vertex], edges: [Edge]) {
        self.source = source
        self.destination = destination
        self.vertices = vertices
        self.edges = edges
    }
}
