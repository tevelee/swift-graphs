extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds strongly connected components using Tarjan's algorithm.
    ///
    /// - Parameter algorithm: The Tarjan SCC algorithm to use
    /// - Returns: The strongly connected components result
    @inlinable
    public func stronglyConnectedComponents(
        using algorithm: TarjanStronglyConnectedComponentsAlgorithm<Self>
    ) -> StronglyConnectedComponentsResult<VertexDescriptor> {
        algorithm.stronglyConnectedComponents(in: self, visitor: nil as Tarjan<Self>.Visitor?)
    }
}
