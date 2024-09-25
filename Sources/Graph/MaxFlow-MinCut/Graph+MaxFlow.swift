extension WholeGraphProtocol where Edge: Weighted & Comparable, Node: Hashable {
    /// Computes the maximum flow from the source node to the sink node using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - sink: The target node.
    ///   - algorithm: The algorithm to use for computing the maximum flow.
    /// - Returns: The maximum flow value from the source node to the sink node.
    @inlinable public func maximumFlow<Algorithm: MaxFlowAlgorithm>(
        from source: Node,
        to sink: Node,
        using algorithm: Algorithm
    ) -> Edge.Weight where Algorithm.Node == Node, Algorithm.Edge == Edge {
        algorithm.maximumFlow(from: source, to: sink, in: self)
    }

    /// Computes the minimum cut from the source node to the sink node using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - sink: The target node.
    ///   - algorithm: The algorithm to use for computing the minimum cut.
    /// - Returns: A tuple containing the cut value and the set of edges in the minimum cut.
    @inlinable public func minimumCut<Algorithm: MaxFlowAlgorithm>(
        from source: Node,
        to sink: Node,
        using algorithm: Algorithm
    ) -> (cutValue: Edge.Weight, cutEdges: Set<GraphEdge<Node, Edge>>) where Algorithm.Node == Node, Algorithm.Edge == Edge {
        algorithm.minimumCut(from: source, to: sink, in: self)
    }
}

/// A protocol that defines the requirements for a maximum flow algorithm.
public protocol MaxFlowAlgorithm<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node: Hashable
    /// The type of edges in the graph, which must conform to the `Weighted` protocol.
    associatedtype Edge: Hashable & Weighted

    /// Computes the maximum flow in the graph from the source node to the sink node.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - sink: The target node.
    ///   - graph: The graph in which to compute the maximum flow.
    /// - Returns: The maximum flow value from the source node to the sink node.
    func maximumFlow(
        from source: Node,
        to sink: Node,
        in graph: some WholeGraphProtocol<Node, Edge>
    ) -> Edge.Weight

    /// Computes the minimum cut in the graph from the source node to the sink node.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - sink: The target node.
    ///   - graph: The graph in which to compute the minimum cut.
    /// - Returns: A tuple containing the cut value and the set of edges in the minimum cut.
    func minimumCut(
        from source: Node,
        to sink: Node,
        in graph: some WholeGraphProtocol<Node, Edge>
    ) -> (cutValue: Edge.Weight, cutEdges: Set<GraphEdge<Node, Edge>>)
}

extension MaxFlowAlgorithm {
    /// Computes the maximum flow in the graph from the source node to the sink node.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - sink: The target node.
    ///   - graph: The graph in which to compute the maximum flow.
    /// - Returns: The maximum flow value from the source node to the sink node.
    @inlinable public func maximumFlow(
        from source: Node,
        to sink: Node,
        in graph: some WholeGraphProtocol<Node, Edge>
    ) -> Edge.Weight {
        minimumCut(from: source, to: sink, in: graph).cutValue // ha!
    }
}
