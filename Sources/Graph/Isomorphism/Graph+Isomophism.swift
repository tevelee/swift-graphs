extension WholeGraphProtocol where Node: Hashable {
    /// Determines if the graph is isomorphic to another graph using the specified algorithm.
    /// - Parameters:
    ///   - other: The other graph.
    ///   - algorithm: The isomorphism algorithm to use.
    /// - Returns: `true` if the graphs are isomorphic, `false` otherwise.
    @inlinable public func isIsomorphic(
        to other: some WholeGraphProtocol<Node, Edge>,
        using algorithm: some GraphIsomorphismAlgorithm<Node, Edge>
    ) -> Bool {
        algorithm.areIsomorphic(self, other)
    }
}

/// An algorithm for determining if two graphs are isomorphic.
public protocol GraphIsomorphismAlgorithm<Node, Edge> {
    /// The type of the nodes in the graph.
    associatedtype Node: Hashable
    /// The type of the edges in the graph.
    associatedtype Edge

    /// Determines if two graphs are isomorphic.
    /// - Parameters:
    ///   - graph1: The first graph.
    ///   - graph2: The second graph.
    /// - Returns: `true` if the graphs are isomorphic, `false` otherwise.
    @inlinable func areIsomorphic(
        _ graph1: some WholeGraphProtocol<Node, Edge>,
        _ graph2: some WholeGraphProtocol<Node, Edge>
    ) -> Bool
}
