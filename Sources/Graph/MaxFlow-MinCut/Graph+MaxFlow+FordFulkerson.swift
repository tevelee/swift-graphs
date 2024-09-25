import Collections

extension MaxFlowAlgorithm {
    /// Creates a Ford-Fulkerson algorithm instance.
    /// - Returns: An instance of `FordFulkersonAlgorithm`.
    @inlinable public static func fordFulkerson<Node, Edge>() -> Self where Self == FordFulkersonAlgorithm<Node, Edge> {
        FordFulkersonAlgorithm()
    }
}

/// An implementation of the Ford-Fulkerson algorithm for finding the maximum flow in a graph.
public struct FordFulkersonAlgorithm<Node: Hashable, Edge: Hashable & Weighted>: MaxFlowAlgorithm where Edge.Weight: Numeric {
    /// Initializes a new `FordFulkersonAlgorithm` instance.
    @inlinable public init() {}

    /// Computes the maximum flow in the graph from the source node to the sink node using the Ford-Fulkerson algorithm.
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
        var residual = ResidualGraph(base: graph)
        var maxFlow: Edge.Weight = .zero

        while let path = residual.searchFirst(from: source, strategy: .dfs(.trackPath()), goal: { $0.node == sink }) {
            let flow = path.edges.map { residual.residualCapacity(from: $0.source, to: $0.destination) }.min() ?? .zero
            maxFlow += flow
            residual.addFlow(path: path.path, flow: flow)
        }

        return maxFlow
    }

    /// Computes the minimum cut in the graph from the source node to the sink node using the Ford-Fulkerson algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - sink: The target node.
    ///   - graph: The graph in which to compute the minimum cut.
    /// - Returns: A tuple containing the cut value and the set of edges in the minimum cut.
    @inlinable public func minimumCut(
        from source: Node,
        to sink: Node,
        in graph: some WholeGraphProtocol<Node, Edge>
    ) -> (cutValue: Edge.Weight, cutEdges: Set<GraphEdge<Node, Edge>>) {
        var residual = ResidualGraph(base: graph)
        var maxFlow: Edge.Weight = .zero

        while let path = residual.searchFirst(from: source, strategy: .dfs(.trackPath()), goal: { $0.node == sink }) {
            let flow = path.edges.map { residual.residualCapacity(from: $0.source, to: $0.destination) }.min() ?? .zero
            maxFlow += flow
            residual.addFlow(path: path.path, flow: flow)
        }

        let reachable = residual.reachableNodes(from: source)
        let cutEdges = graph.allEdges.filter { edge in
            reachable.contains(edge.source) && !reachable.contains(edge.destination)
        }

        return (cutValue: maxFlow, cutEdges: Set(cutEdges))
    }
}
