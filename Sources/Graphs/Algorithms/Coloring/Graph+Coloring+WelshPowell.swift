extension GraphColoringAlgorithm {
    /// Creates a Welsh-Powell algorithm instance.
    @inlinable public static func welshPowell<Node, Edge>() -> Self where Self == WelshPowellAlgorithm<Node, Edge> {
        WelshPowellAlgorithm()
    }
}

/// Implements Welsh-Powell algorithm coloring algorithm.
public struct WelshPowellAlgorithm<Node: Hashable, Edge>: GraphColoringAlgorithm {
    /// Initializes a new Welsh-Powell algorithm instance.
    @inlinable public init() {}

    /// Colors the nodes of the graph using the Welsh-Powell algorithm.
    /// - Parameter graph: The graph to color.
    /// - Returns: A dictionary mapping each node to its assigned color.
    @inlinable public func coloring(of graph: some Graph<Node, Edge>) -> [Node: Int] {
        let nodesByDegree = graph.allNodes.sorted { graph.edges(connectedTo: $0).count > graph.edges(connectedTo: $1).count }

        var colorAssignment: [Node: Int] = [:]
        var currentColor = 0

        for node in nodesByDegree {
            if colorAssignment[node] == nil {
                colorAssignment[node] = currentColor

                for otherNode in nodesByDegree {
                    if colorAssignment[otherNode] == nil && !graph.isAdjacent(node, otherNode) {
                        let isAdjacentToColored = graph.adjacentNodes(to: otherNode).contains { neighbor in
                            colorAssignment[neighbor] == currentColor
                        }
                        if !isAdjacentToColored {
                            colorAssignment[otherNode] = currentColor
                        }
                    }
                }

                currentColor += 1
            }
        }

        return colorAssignment
    }
}
