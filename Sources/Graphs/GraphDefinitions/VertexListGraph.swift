/// A protocol for graphs that provide access to all vertices.
///
/// A vertex list graph allows enumeration of all vertices in the graph and provides
/// the total vertex count. This is a fundamental capability for many graph algorithms
/// that need to process all vertices.
public protocol VertexListGraph: Graph {
    /// The type of sequence returned when querying all vertices.
    associatedtype Vertices: Sequence<VertexDescriptor>

    /// Returns all vertices in the graph.
    ///
    /// - Returns: A sequence of all vertex descriptors in the graph
    func vertices() -> Vertices
    
    /// The total number of vertices in the graph.
    var vertexCount: Int { get }
}
