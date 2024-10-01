extension MaxFlowAlgorithm {
    /// Creates a new instance of the Dinic's algorithm.
    @inlinable public static func dinic<Node, Edge>() -> Self where Self == DinicAlgorithm<Node, Edge> {
        DinicAlgorithm()
    }
}

/// An implementation of Dinic's algorithm for computing the maximum flow in a graph.
public struct DinicAlgorithm<Node: Hashable, Edge: Hashable & Weighted>: MaxFlowAlgorithm where Edge.Weight: Numeric & Comparable & FixedWidthInteger {
    @inlinable public init() {}

    /// Computes the maximum flow in the graph from the source node to the sink node using Dinic's algorithm.
    @inlinable public func maximumFlow(
        from source: Node,
        to sink: Node,
        in graph: some Graph<Node, Edge>
    ) -> Edge.Weight {
        var residual = ResidualGraph(base: graph)
        var maxFlow: Edge.Weight = .zero

        while true {
            guard let level = buildLevelGraph(residualGraph: &residual, source: source, sink: sink) else {
                break
            }
            var nextEdgeIndex: [Node: Int] = [:]
            var flow: Edge.Weight
            repeat {
                flow = sendFlowDFS(
                    residualGraph: &residual,
                    current: source,
                    sink: sink,
                    flow: Edge.Weight.max,
                    level: level,
                    nextEdgeIndex: &nextEdgeIndex
                )
                maxFlow += flow
            } while flow > .zero
        }
        return maxFlow
    }

    /// Computes the minimum cut in the graph from the source node to the sink node using Dinic's algorithm.
    @inlinable public func minimumCut(
        from source: Node,
        to sink: Node,
        in graph: some Graph<Node, Edge>
    ) -> (cutValue: Edge.Weight, cutEdges: Set<GraphEdge<Node, Edge>>) {
        var residual = ResidualGraph(base: graph)
        var maxFlow: Edge.Weight = .zero

        while true {
            guard let level = buildLevelGraph(residualGraph: &residual, source: source, sink: sink) else {
                break
            }
            var nextEdgeIndex: [Node: Int] = [:]
            var flow: Edge.Weight
            repeat {
                flow = sendFlowDFS(
                    residualGraph: &residual,
                    current: source,
                    sink: sink,
                    flow: Edge.Weight.max,
                    level: level,
                    nextEdgeIndex: &nextEdgeIndex
                )
                maxFlow += flow
            } while flow > .zero
        }

        let reachable = residual.reachableNodes(from: source)
        let cutEdges = graph.allEdges.filter { edge in
            reachable.contains(edge.source) && !reachable.contains(edge.destination)
        }
        return (cutValue: maxFlow, cutEdges: Set(cutEdges))
    }

    /// Builds a level graph for the given residual graph.
    @usableFromInline
    func buildLevelGraph(
        residualGraph: inout ResidualGraph<some GraphComponent<Node, Edge>>,
        source: Node,
        sink: Node
    ) -> [Node: Int]? {
        var level: [Node: Int] = [:]
        level[source] = 0
        var queue: [Node] = [source]

        while !queue.isEmpty {
            let current = queue.removeFirst()
            let currentLevel = level[current]!
            for edge in residualGraph.edges(from: current) {
                if edge.value > .zero && level[edge.destination] == nil {
                    level[edge.destination] = currentLevel + 1
                    queue.append(edge.destination)
                }
            }
        }
        return level[sink] != nil ? level : nil
    }

    /// Sends flow through the graph using a depth-first search.
    @usableFromInline
    func sendFlowDFS(
        residualGraph: inout ResidualGraph<some GraphComponent<Node, Edge>>,
        current: Node,
        sink: Node,
        flow currentFlow: Edge.Weight,
        level: [Node: Int],
        nextEdgeIndex: inout [Node: Int]
    ) -> Edge.Weight {
        if current == sink {
            return currentFlow
        }

        let edges = residualGraph.edges(from: current)
        var edgeIndex = nextEdgeIndex[current] ?? 0

        while edgeIndex < edges.count {
            let edge = edges[edgeIndex]
            if let levelU = level[current], let levelV = level[edge.destination], levelV == levelU + 1 {
                if edge.value > .zero {
                    let minFlow = min(currentFlow, edge.value)
                    let flow = sendFlowDFS(
                        residualGraph: &residualGraph,
                        current: edge.destination,
                        sink: sink,
                        flow: minFlow,
                        level: level,
                        nextEdgeIndex: &nextEdgeIndex
                    )
                    if flow > .zero {
                        residualGraph.addFlow(from: current, to: edge.destination, flow: flow)
                        return flow
                    }
                }
            }
            edgeIndex += 1
            nextEdgeIndex[current] = edgeIndex
        }
        return .zero
    }
}
