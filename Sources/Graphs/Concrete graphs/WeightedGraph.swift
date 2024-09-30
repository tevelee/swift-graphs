/// A graph structure that adds weights to the edges of an existing graph.
@dynamicMemberLookup
public struct WeightedGraph<Base: ConnectedGraph, Edge: Weighted> {
    public typealias Node = Base.Node

    /// The underlying graph.
    @usableFromInline let graph: Base
    /// A closure to compute the weight of an edge between two nodes.
    @usableFromInline let weight: (Node, Node) -> Edge

    /// Initializes a new weighted graph with the given underlying graph and weight function.
    /// - Parameters:
    ///   - graph: The underlying graph.
    ///   - weight: A closure that takes two nodes and returns the weight of the edge between them.
    @inlinable public init(
        graph: Base,
        weight: @escaping (Node, Node) -> Edge
    ) where Base.Edge == Void {
        self.graph = graph
        self.weight = weight
    }

    /// Subscript that accesses members on the underlying graph instance
    @inlinable public subscript<Member>(dynamicMember keyPath: KeyPath<Base, Member>) -> Member {
        graph[keyPath: keyPath]
    }
}

extension WeightedGraph: ConnectedGraph {
    /// Returns the edges originating from the specified node, with weights added.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges from the specified node, with weights added.
    public func edges(from node: Base.Node) -> [GraphEdge<Base.Node, Edge>] {
        graph.edges(from: node).map {
            GraphEdge(
                source: $0.source,
                destination: $0.destination,
                value: weight($0.source, $0.destination)
            )
        }
    }
}

extension WeightedGraph: Graph where Base: Graph {
    /// All nodes in the weighted graph.
    public var allNodes: [Node] {
        graph.allNodes
    }

    /// All edges in the weighted graph, with weights added.
    public var allEdges: [GraphEdge<Node, Edge>] {
        graph.allEdges.map { edge in
            GraphEdge(
                source: edge.source,
                destination: edge.destination,
                value: weight(edge.source, edge.destination)
            )
        }
    }
}

extension WeightedGraph {
    /// Initializes a new `WeightedGraph` with a given graph and a weight function.
    /// - Parameters:
    ///   - graph: The base graph.
    ///   - weight: A closure that calculates the weight of an edge given the source node, destination node, and the previous edge.
    @inlinable public init<Value, PreviousEdge>(
        graph: Base,
        weight: @escaping (Base.Node, Base.Node, PreviousEdge) -> Edge
    ) where Base == GridGraph<Value, PreviousEdge> {
        self.graph = graph
        self.weight = { source, destination in
            weight(source, destination, graph.edge(source, destination))
        }
    }
}

extension ConnectedGraph where Edge == Void {
    /// Returns a `WeightedGraph` with the given weight function.
    /// - Parameter weight: A closure that calculates the weight of an edge given the source and destination nodes.
    /// - Returns: A `WeightedGraph` with the specified weight function.
    @inlinable public func weighted<NewEdge: Weighted>(weight: @escaping (Node, Node) -> NewEdge) -> WeightedGraph<Self, NewEdge> {
        WeightedGraph(graph: self, weight: weight)
    }

    /// Returns a `WeightedGraph` with a constant weight for all edges.
    /// - Parameter value: A closure that returns the constant weight for all edges.
    /// - Returns: A `WeightedGraph` with the specified constant weight.
    @inlinable public func weighted<NewEdge: Weighted>(constant value: @autoclosure @escaping () -> NewEdge) -> WeightedGraph<Self, NewEdge> {
        WeightedGraph(graph: self) { _, _ in value() }
    }
}

extension GridGraph where Edge == Void {
    /// Returns a `WeightedGraph` with weights calculated by the specified distance algorithm.
    /// - Parameter distanceAlgorithm: The algorithm to use for calculating distances. Defaults to Euclidean distance.
    /// - Returns: A `WeightedGraph` with weights calculated by the specified distance algorithm.
    @inlinable public func weightedByDistance(_ distanceAlgorithm: DistanceAlgorithm<Node, Double> = .euclideanDistance(of: \Self.Node.coordinates)) -> WeightedGraph<Self, Double> {
        WeightedGraph(graph: self, weight: distanceAlgorithm.distance)
    }
}