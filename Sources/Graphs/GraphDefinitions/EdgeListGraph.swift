/// A protocol for graphs that provide access to all edges.
///
/// An edge list graph allows enumeration of all edges in the graph and provides
/// the total edge count. This is useful for algorithms that need to process
/// all edges or when the graph structure is defined by its edge list.
public protocol EdgeListGraph: Graph {
    /// The type of sequence returned when querying all edges.
    associatedtype Edges: Sequence<EdgeDescriptor>

    /// Returns all edges in the graph.
    ///
    /// - Returns: A sequence of all edge descriptors in the graph
    func edges() -> Edges
    
    /// The total number of edges in the graph.
    var edgeCount: Int { get }
}
