extension GraphColoringAlgorithm {
    /// Creates a new instance of the greedy algorithm.
    @inlinable public static func greedy<Node, Edge>() -> Self where Self == GreedyColoringAlgorithm<Node, Edge> {
        GreedyColoringAlgorithm()
    }
}

extension WholeGraphProtocol where Node: Hashable {
    /// Colors the nodes of the graph using the greedy algorithm.
    @inlinable public func colorNodes() -> [Node: Int] {
        colorNodes(using: .greedy())
    }
}

/// An implementation of the greedy graph coloring algorithm.
public struct GreedyColoringAlgorithm<Node: Hashable, Edge>: GraphColoringAlgorithm {
    /// Creates a new instance of the greedy algorithm.
    @inlinable public init() {}

    /// Colors the nodes of the graph using the greedy algorithm.
    @inlinable public func coloring(
        of graph: some WholeGraphProtocol<Node, Edge>
    ) -> [Node: Int] {
        var result: [Node: Int] = [:]
        let nodes = graph.allNodes.sorted { graph.edges(connectedTo: $0).count > graph.edges(connectedTo: $1).count }
        for node in nodes {
            var usedColors: Set<Int> = []
            for neighbor in graph.adjacentNodes(to: node) {
                if let color = result[neighbor] {
                    usedColors.insert(color)
                }
            }
            var color = 0
            while usedColors.contains(color) {
                color += 1
            }
            result[node] = color
        }
        return result
    }
}
