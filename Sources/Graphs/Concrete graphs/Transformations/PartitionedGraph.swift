/// A bipartite graph.
public struct PartitionedGraph<Base: ConnectedGraph>: BipartiteGraph where Base.Node: Hashable {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge

    /// The base graph.
    public let base: Base
    /// The left partition of the bipartite graph.
    public let leftPartition: Set<Node>
    /// The right partition of the bipartite graph.
    public let rightPartition: Set<Node>

    /// Initializes a new `BipartiteGraph` with a base graph and the left and right partitions.
    /// - Parameters:
    ///  - base: The base graph.
    ///  - leftPartition: The left partition of the bipartite graph.
    ///  - rightPartition: The right partition of the bipartite graph.
    /// - Returns: A `BipartiteGraph` instance.
    @inlinable public init(
        base: Base,
        leftPartition: Set<Node>,
        rightPartition: Set<Node>
    ) {
        self.base = base
        self.leftPartition = leftPartition
        self.rightPartition = rightPartition
    }

    /// Returns the edges from a given node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        guard leftPartition.contains(node) else {
            return []
        }
        return base.edges(from: node).filter { edge in
            rightPartition.contains(edge.destination)
        }
    }
}

extension ConnectedGraph where Node: Hashable {
    /// Returns a bipartite graph with the given left and right partitions.
    /// - Parameters:
    ///  - leftPartition: The left partition of the bipartite graph.
    ///  - rightPartition: The right partition of the bipartite graph.
    /// - Returns: A `BipartiteGraph` instance.
    @inlinable public func bipartite(leftPartition: Set<Node>, rightPartition: Set<Node>) -> PartitionedGraph<Self> {
        .init(base: self, leftPartition: leftPartition, rightPartition: rightPartition)
    }
}
