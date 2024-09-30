/// A protocol for bipartite graphs.
public protocol BipartiteGraph<Node, Edge>: ConnectedGraph where Node: Hashable {
    /// The left partition of the bipartite graph.
    var leftPartition: Set<Node> { get }
    /// The right partition of the bipartite graph.
    var rightPartition: Set<Node> { get }
}
