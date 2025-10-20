extension VertexOrderingAlgorithm {
    /// Creates a Smallest Last Vertex Ordering algorithm.
    ///
    /// - Returns: A new Smallest Last Vertex Ordering algorithm
    @inlinable
    public static func smallestLastVertex<G: IncidenceGraph & VertexListGraph & BidirectionalGraph>() -> Self where Self == SmallestLastVertexOrderingAlgorithm<G>, G.VertexDescriptor: Hashable {
        .init()
    }
}

extension SmallestLastVertexOrderingAlgorithm: VertexOrderingAlgorithm {}
