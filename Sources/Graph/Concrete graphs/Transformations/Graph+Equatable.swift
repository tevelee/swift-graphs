/// A graph wrapper that makes the nodes equatable based on a custom equality function.
@dynamicMemberLookup
public struct EquatableNodesGraph<Base: GraphProtocol>: GraphProtocol {
    public typealias Edge = Base.Edge

    /// A node in the `EquatableNodesGraph` that is equatable based on a custom equality function.
    public struct Node: Equatable {
        /// The base node.
        @usableFromInline let base: Base.Node
        /// The custom equality function for the node.
        @usableFromInline let isEqual: (Base.Node, Base.Node) -> Bool

        /// Initializes a new node with a base node and a custom equality function.
        /// - Parameters:
        ///   - base: The base node.
        ///   - isEqual: A closure that defines the equality function for the nodes.
        @inlinable public init(base: Base.Node, isEqual: @escaping (Base.Node, Base.Node) -> Bool) {
            self.base = base
            self.isEqual = isEqual
        }

        /// Checks if two nodes are equal based on the custom equality function.
        /// - Parameters:
        ///   - lhs: The left-hand side node.
        ///   - rhs: The right-hand side node.
        /// - Returns: `true` if the nodes are equal, `false` otherwise.
        @inlinable public static func == (lhs: Node, rhs: Node) -> Bool {
            lhs.isEqual(lhs.base, rhs.base)
        }
    }

    /// The base graph.
    @usableFromInline let base: Base
    /// The custom equality function for the nodes.
    @usableFromInline let isEqual: (Base.Node, Base.Node) -> Bool

    /// Initializes a new `EquatableNodesGraph` with a base graph and a custom equality function for the nodes.
    /// - Parameters:
    ///   - base: The base graph.
    ///   - isEqual: A closure that defines the equality function for the nodes.
    @inlinable public init(base: Base, isEqual: @escaping (Base.Node, Base.Node) -> Bool) {
        self.base = base
        self.isEqual = isEqual
    }

    /// Returns the edges from a given node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of edges from the given node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        base.edges(from: node.base).map {
            $0.mapNode {
                Node(base: $0, isEqual: isEqual)
            }
        }
    }

    /// Subscript that accesses members on the underlying graph instance
    @inlinable public subscript<Member>(dynamicMember keyPath: KeyPath<Base, Member>) -> Member {
        base[keyPath: keyPath]
    }
}

extension GraphProtocol {
    /// Creates a new `EquatableNodesGraph` with a custom equality function for the nodes.
    /// - Parameter isEqual: A closure that defines the equality function for the nodes.
    /// - Returns: An `EquatableNodesGraph` instance.
    @inlinable public func makeNodesEquatable(by isEqual: @escaping (Node, Node) -> Bool) -> EquatableNodesGraph<Self> {
        .init(base: self, isEqual: isEqual)
    }
}

/// A graph wrapper that makes the edges equatable based on a custom equality function.
@dynamicMemberLookup
public struct EquatableEdgesGraph<Base: GraphProtocol>: GraphProtocol {
    public typealias Node = Base.Node

    /// An edge in the `EquatableEdgesGraph` that is equatable based on a custom equality function.
    public struct Edge: Equatable {
        /// The base edge.
        @usableFromInline let base: Base.Edge
        /// The custom equality function for the edge.
        @usableFromInline let isEqual: (Base.Edge, Base.Edge) -> Bool

        /// Initializes a new edge with a base edge and a custom equality function.
        /// - Parameters:
        ///   - base: The base edge.
        ///   - isEqual: A closure that defines the equality function for the edges.
        @inlinable public init(base: Base.Edge, isEqual: @escaping (Base.Edge, Base.Edge) -> Bool) {
            self.base = base
            self.isEqual = isEqual
        }

        /// Checks if two edges are equal based on the custom equality function.
        /// - Parameters:
        ///   - lhs: The left-hand side edge.
        ///   - rhs: The right-hand side edge.
        /// - Returns: `true` if the edges are equal, `false` otherwise.
        @inlinable public static func == (lhs: Edge, rhs: Edge) -> Bool {
            lhs.isEqual(lhs.base, rhs.base)
        }
    }

    /// The base graph.
    @usableFromInline let base: Base
    /// The custom equality function for the edges.
    @usableFromInline let isEqual: (Base.Edge, Base.Edge) -> Bool

    /// Initializes a new `EquatableEdgesGraph` with a base graph and a custom equality function for the edges.
    /// - Parameters:
    ///   - base: The base graph.
    ///   - isEqual: A closure that defines the equality function for the edges.
    @inlinable public init(base: Base, isEqual: @escaping (Base.Edge, Base.Edge) -> Bool) {
        self.base = base
        self.isEqual = isEqual
    }

    /// Returns the edges from a given node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of edges from the given node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        base.edges(from: node).map {
            $0.mapEdge {
                Edge(base: $0, isEqual: isEqual)
            }
        }
    }

    /// Subscript that accesses members on the underlying graph instance
    @inlinable public subscript<Member>(dynamicMember keyPath: KeyPath<Base, Member>) -> Member {
        base[keyPath: keyPath]
    }
}

extension GraphProtocol {
    /// Creates a new `EquatableEdgesGraph` with a custom equality function for the edges.
    /// - Parameter isEqual: A closure that defines the equality function for the edges.
    /// - Returns: An `EquatableEdgesGraph` instance.
    @inlinable public func makeEdgesEquatable(by isEqual: @escaping (Edge, Edge) -> Bool) -> EquatableEdgesGraph<Self> {
        .init(base: self, isEqual: isEqual)
    }
}
