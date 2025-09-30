extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds connected components using Union-Find algorithm.
    ///
    /// - Parameter algorithm: The Union-Find connected components algorithm to use
    /// - Returns: The connected components result
    @inlinable
    public func connectedComponents(
        using algorithm: UnionFindConnectedComponentsAlgorithm<Self>
    ) -> ConnectedComponentsResult<VertexDescriptor> {
        algorithm.connectedComponents(in: self, visitor: nil)
    }
}
