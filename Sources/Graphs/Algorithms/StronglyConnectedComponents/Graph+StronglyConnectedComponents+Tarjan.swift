extension StronglyConnectedComponentsAlgorithm {
    /// Creates a Tarjan algorithm instance.
    /// - Returns: An instance of `TarjanSCCAlgorithm`.
    @inlinable public static func tarjan<Node, Edge>() -> Self where Self == TarjanSCCAlgorithm<Node, Edge> {
        .init()
    }
}

/// An implementation of the Tarjan algorithm for finding strongly connected components in a graph.
public struct TarjanSCCAlgorithm<Node: Hashable, Edge>: StronglyConnectedComponentsAlgorithm {
    @inlinable public init() {}

    /// Finds the strongly connected components in the graph using the Tarjan algorithm.
    /// - Parameter graph: The graph in which to find the strongly connected components.
    /// - Returns: An array of arrays, where each inner array contains the nodes of a strongly connected component.
    @inlinable public func findStronglyConnectedComponents(in graph: some Graph<Node, Edge>) -> [[Node]] {
        var index = 0
        var stack: [Node] = []
        var indices: [Node: Int] = [:]
        var lowLinks: [Node: Int] = [:]
        var onStack: Set<Node> = []
        var sccs: [[Node]] = []

        for node in graph.allNodes where indices[node] == nil {
            dfs(graph: graph, node: node, index: &index, stack: &stack, indices: &indices, lowLinks: &lowLinks, onStack: &onStack, sccs: &sccs)
        }

        return sccs
    }

    /// Performs a depth-first search to find strongly connected components.
    /// - Parameters:
    ///   - graph: The graph being traversed.
    ///   - node: The starting node for the DFS.
    ///   - index: The current index in the DFS.
    ///   - stack: The stack of nodes being visited.
    ///   - indices: A dictionary mapping nodes to their indices.
    ///   - lowLinks: A dictionary mapping nodes to their low-link values.
    ///   - onStack: A set of nodes currently on the stack.
    ///   - sccs: An array to collect the strongly connected components.
    @usableFromInline func dfs(
        graph: some Graph<Node, Edge>,
        node: Node,
        index: inout Int,
        stack: inout [Node],
        indices: inout [Node: Int],
        lowLinks: inout [Node: Int],
        onStack: inout Set<Node>,
        sccs: inout [[Node]]
    ) {
        indices[node] = index
        lowLinks[node] = index
        index += 1
        stack.append(node)
        onStack.insert(node)

        for edge in graph.edges(from: node) {
            let neighbor = edge.destination
            if indices[neighbor] == nil {
                dfs(graph: graph, node: neighbor, index: &index, stack: &stack, indices: &indices, lowLinks: &lowLinks, onStack: &onStack, sccs: &sccs)
                lowLinks[node] = min(lowLinks[node]!, lowLinks[neighbor]!)
            } else if onStack.contains(neighbor) {
                lowLinks[node] = min(lowLinks[node]!, indices[neighbor]!)
            }
        }

        if lowLinks[node] == indices[node] {
            var scc: [Node] = []
            var poppedNode: Node
            repeat {
                poppedNode = stack.removeLast()
                onStack.remove(poppedNode)
                scc.append(poppedNode)
            } while poppedNode != node
            sccs.append(scc)
        }
    }
}
