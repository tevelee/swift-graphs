extension StronglyConnectedComponentsAlgorithm {
    /// Creates a Kosaraju algorithm instance.
    /// - Returns: An instance of `KosarajuSCCAlgorithm`.
    @inlinable public static func kosaraju<Node, Edge>() -> Self where Self == KosarajuSCCAlgorithm<Node, Edge> {
        .init()
    }
}

/// An implementation of the Kosaraju algorithm for finding strongly connected components in a graph.
public struct KosarajuSCCAlgorithm<Node: Hashable, Edge>: StronglyConnectedComponentsAlgorithm {
    /// Initializes a new `KosarajuSCCAlgorithm` instance.
    @inlinable public init() {}

    /// Finds the strongly connected components in the graph using the Kosaraju algorithm.
    /// - Parameter graph: The graph in which to find the strongly connected components.
    /// - Returns: An array of arrays, where each inner array contains the nodes of a strongly connected component.
    @inlinable public func findStronglyConnectedComponents(in graph: some Graph<Node, Edge>) -> [[Node]] {
        guard let sorted = graph.topologicalSort() else { return [] }

        let reversedGraph = TransposedGraph(base: graph)

        var result: [[Node]] = []

        var visited: Set<Node> = []
        for node in sorted.reversed() where !visited.contains(node) {
            var scc: [Node] = []
            dfsCollect(graph: reversedGraph, node: node, visited: &visited, scc: &scc)
            result.append(scc)
        }

        return result
    }

    /// Performs a depth-first search to collect nodes in a strongly connected component.
    /// - Parameters:
    ///   - graph: The graph being traversed.
    ///   - node: The starting node for the DFS.
    ///   - visited: A set of visited nodes.
    ///   - scc: An array to collect the nodes in the strongly connected component.
    @usableFromInline func dfsCollect(graph: some Graph<Node, Edge>, node: Node, visited: inout Set<Node>, scc: inout [Node]) {
        visited.insert(node)
        scc.append(node)
        for edge in graph.edges(from: node) {
            let neighbor = edge.destination
            if !visited.contains(neighbor) {
                dfsCollect(graph: graph, node: neighbor, visited: &visited, scc: &scc)
            }
        }
    }

    /// Reverses the edges of the graph.
    /// - Parameter graph: The graph to reverse.
    /// - Returns: A new graph with all edges reversed.
    @usableFromInline func reverseGraph(_ graph: some Graph<Node, Edge>) -> ConnectedGraph<Node, Edge> {
        let reversedEdges = graph.allEdges.map { GraphEdge(source: $0.destination, destination: $0.source, value: $0.value) }
        return ConnectedGraph(edges: reversedEdges)
    }
}
