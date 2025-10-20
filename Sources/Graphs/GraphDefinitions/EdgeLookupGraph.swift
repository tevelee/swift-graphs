/// A protocol for graphs that support efficient edge lookup by source and destination vertices.
///
/// This protocol is useful for algorithms that need to check if an edge exists between
/// two specific vertices without iterating through all edges.
public protocol EdgeLookupGraph: Graph {
    /// Returns the edge from source to destination, if it exists.
    ///
    /// - Parameters:
    ///   - source: The source vertex
    ///   - destination: The destination vertex
    /// - Returns: The edge descriptor if the edge exists, nil otherwise
    @inlinable
    func edge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor?
}

extension EdgeLookupGraph where Self: IncidenceGraph, VertexDescriptor: Equatable {
    func edge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        for e in outgoingEdges(of: source) {
            if let v = self.destination(of: e), v == destination { return e }
        }
        return nil
    }
}


