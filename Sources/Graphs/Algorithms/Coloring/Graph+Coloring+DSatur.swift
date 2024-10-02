extension GraphColoringAlgorithm {
    /// Creates a DSatur algorithm instance.
    @inlinable public static func dsatur<Node, Edge>() -> Self where Self == DSaturAlgorithm<Node, Edge> {
        DSaturAlgorithm()
    }
}

/// Implements DSatur algorithm coloring algorithm.
public struct DSaturAlgorithm<Node: Hashable, Edge>: GraphColoringAlgorithm {
    /// Initializes a new DSatur algorithm instance.
    @inlinable public init() {}

    /// Colors the nodes of the graph using the DSatur algorithm.
    /// - Parameter graph: The graph to color.
    /// - Returns: A dictionary mapping each node to its assigned color.
    @inlinable public func coloring(of graph: some Graph<Node, Edge>) -> [Node: Int] {
        var colorAssignment: [Node: Int] = [:]
        var saturation: [Node: Int] = [:]
        var uncoloredNodes = Set(graph.allNodes)
        var adjacentColors: [Node: Set<Int>] = [:]

        for node in graph.allNodes {
            saturation[node] = 0
            adjacentColors[node] = []
        }

        while !uncoloredNodes.isEmpty {
            let node = uncoloredNodes.max { lhs, rhs in
                guard saturation[lhs]! != saturation[rhs]! else {
                    return graph.edges(connectedTo: lhs).count < graph.edges(connectedTo: rhs).count
                }
                return saturation[lhs]! < saturation[rhs]!
            }!

            let usedColors = adjacentColors[node]!
            var color = 0
            while usedColors.contains(color) {
                color += 1
            }

            colorAssignment[node] = color
            uncoloredNodes.remove(node)

            for neighbor in graph.adjacentNodes(to: node) where uncoloredNodes.contains(neighbor) {
                if !adjacentColors[neighbor]!.contains(color) {
                    adjacentColors[neighbor]!.insert(color)
                    saturation[neighbor]! += 1
                }
            }
        }

        return colorAssignment
    }
}
