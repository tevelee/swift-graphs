/// A protocol that defines the basic structure of a graph.
///
/// This is the fundamental protocol that all graph types must conform to. It defines the basic
/// vertex and edge descriptor types that a graph uses, but doesn't specify any operations.
/// Specific graph capabilities are defined by additional protocols that extend this base.
///
/// - Note: This protocol is intentionally minimal to allow for maximum flexibility in graph
///   implementations. Concrete graph types should conform to additional protocols like
///   `IncidenceGraph`, `VertexListGraph`, etc. to provide specific functionality.
public protocol Graph<VertexDescriptor, EdgeDescriptor> {
    /// The type used to identify vertices in this graph.
    associatedtype VertexDescriptor
    
    /// The type used to identify edges in this graph.
    associatedtype EdgeDescriptor
}

extension Graph {
    /// Creates a vertex collection using the provided factory function.
    ///
    /// This is a utility method that allows graph implementations to create vertex collections
    /// in a type-safe manner. The factory function is called to create the collection, and
    /// the result is returned as-is.
    ///
    /// - Parameter factory: A closure that creates a collection of vertex descriptors
    /// - Returns: The collection created by the factory function
    @inlinable
    public func makeVertexCollection<T: Collection<VertexDescriptor>>(_ factory: () -> T) -> T {
        factory()
    }

    /// Creates an edge collection using the provided factory function.
    ///
    /// This is a utility method that allows graph implementations to create edge collections
    /// in a type-safe manner. The factory function is called to create the collection, and
    /// the result is returned as-is.
    ///
    /// - Parameter factory: A closure that creates a collection of edge descriptors
    /// - Returns: The collection created by the factory function
    @inlinable
    public func makeEdgeCollection<T: Collection<EdgeDescriptor>>(_ factory: () -> T) -> T {
        factory()
    }
}
