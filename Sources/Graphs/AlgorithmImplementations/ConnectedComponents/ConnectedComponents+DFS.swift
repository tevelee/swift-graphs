#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds connected components using DFS algorithm.
    ///
    /// - Parameter algorithm: The DFS connected components algorithm to use
    /// - Returns: The connected components result
    @inlinable
    public func connectedComponents(
        using algorithm: DFSConnectedComponentsAlgorithm<Self>
    ) -> ConnectedComponentsResult<VertexDescriptor> {
        algorithm.connectedComponents(in: self, visitor: nil)
    }
}
#endif
