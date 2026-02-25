#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
extension VertexOrderingAlgorithm {
    /// Creates a Reverse Cuthill-McKee Ordering algorithm.
    ///
    /// - Returns: A new Reverse Cuthill-McKee Ordering algorithm
    @inlinable
    public static func reverseCuthillMcKee<G: IncidenceGraph & VertexListGraph & BidirectionalGraph>() -> Self where Self == ReverseCuthillMcKeeOrderingAlgorithm<G>, G.VertexDescriptor: Hashable {
        .init()
    }
}

extension ReverseCuthillMcKeeOrderingAlgorithm: VertexOrderingAlgorithm {}
#endif
