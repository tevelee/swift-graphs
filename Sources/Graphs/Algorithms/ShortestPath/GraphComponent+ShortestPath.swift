extension GraphComponent where Edge: Weighted {
    /// Finds the shortest path from the source node to the destination node using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - algorithm: The algorithm to use for finding the shortest path.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable public func shortestPath(
        from source: Node,
        to destination: Node,
        using algorithm: some ShortestPathAlgorithm<Node, Edge>
    ) -> Path<Node, Edge>? where Node: Equatable {
        algorithm.shortestPath(from: source, to: destination, in: self)
    }

    /// Finds the shortest path from the source node to the destination node using the specified algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - condition: The completion criteria.
    ///   - algorithm: The algorithm to use for finding the shortest path.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable public func shortestPath(
        from source: Node,
        to destination: Node,
        satisfying condition: (Node) -> Bool,
        using algorithm: some ShortestPathAlgorithm<Node, Edge>
    ) -> Path<Node, Edge>? {
        algorithm.shortestPath(from: source, to: destination, satisfying: condition, in: self)
    }
}

/// A protocol that defines the requirements for a shortest path algorithm.
public protocol ShortestPathAlgorithm<Node, Edge> {
    /// The type of nodes in the graph.
    associatedtype Node
    /// The type of edges in the graph.
    associatedtype Edge

    /// Finds the shortest path in the graph from the start node to the goal node.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - condition: The completion criteria.
    ///   - graph: The graph in which to find the shortest path.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable func shortestPath(
        from source: Node,
        to destination: Node,
        satisfying condition: (Node) -> Bool,
        in graph: some GraphComponent<Node, Edge>
    ) -> Path<Node, Edge>?
}

extension ShortestPathAlgorithm where Node: Equatable {
    /// Finds the shortest path in the graph from the start node to the goal node.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - graph: The graph in which to find the shortest path.
    /// - Returns: A `Path` instance representing the shortest path, or `nil` if no path is found.
    @inlinable func shortestPath(
        from source: Node,
        to destination: Node,
        in graph: some GraphComponent<Node, Edge>
    ) -> Path<Node, Edge>? {
        shortestPath(from: source, to: destination, satisfying: { $0 == destination }, in: graph)
    }
}

/// A structure representing a path in a graph.
public struct Path<Node, Edge> {
    /// The source node of the path.
    public let source: Node
    /// The destination node of the path.
    public let destination: Node
    /// The edges that make up the path.
    public let edges: [GraphEdge<Node, Edge>]

    /// Initializes a new `Path` instance with the given source, destination, and edges.
    /// - Parameters:
    ///   - source: The source node of the path.
    ///   - destination: The destination node of the path.
    ///   - edges: The edges that make up the path.
    @inlinable public init(source: Node, destination: Node, edges: [GraphEdge<Node, Edge>]) {
        self.source = source
        self.destination = destination
        self.edges = edges
    }

    /// The sequence of nodes in the path.
    @inlinable public var path: [Node] {
        [source] + edges.map(\.destination)
    }
}

extension Path: Equatable where Node: Equatable, Edge: Equatable {}
extension Path: Hashable where Node: Hashable, Edge: Hashable {}

extension Path where Edge: Weighted, Edge.Weight: Numeric {
    /// The total cost of the path, calculated as the sum of the weights of the edges.
    @inlinable public var cost: Edge.Weight {
        edges.lazy.map(\.value.weight).reduce(into: .zero, +=)
    }
}

extension Path: Comparable where Node: Equatable, Edge: Equatable & Weighted, Edge.Weight: Numeric {
    /// Comparable conformance by comparing costs
    @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.cost < rhs.cost
    }
}

extension Path where Node: Hashable {
    /// Initializes a path from a dictionary of connecting edges, a source node, and a destination node.
    /// - Parameters:
    ///   - connectingEdges: A dictionary mapping nodes to their connecting edges.
    ///   - source: The source node of the path.
    ///   - destination: The destination node of the path.
    @inlinable init?(
        connectingEdges: [Node: GraphEdge<Node, Edge>],
        source: Node,
        destination: Node
    ) {
        var path: [GraphEdge<Node, Edge>] = []
        var currentNode = destination

        while currentNode != source {
            guard let edge = connectingEdges[currentNode] else {
                return nil
            }
            path.append(edge)
            currentNode = edge.source
        }

        self.init(source: source, destination: destination, edges: path.reversed())
    }
}
