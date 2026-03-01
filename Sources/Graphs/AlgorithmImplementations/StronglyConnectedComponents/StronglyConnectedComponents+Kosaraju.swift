#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
extension BidirectionalGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    /// Finds strongly connected components using Kosaraju's algorithm.
    ///
    /// - Parameter algorithm: The Kosaraju SCC algorithm to use
    /// - Returns: The strongly connected components result
    @inlinable
    public func stronglyConnectedComponents(
        using algorithm: KosarajuStronglyConnectedComponentsAlgorithm<Self>
    ) -> StronglyConnectedComponentsResult<VertexDescriptor> {
        algorithm.stronglyConnectedComponents(in: self, visitor: nil as Kosaraju<Self>.Visitor?)
    }
}
#endif
