/// A graph wrapper that makes the nodes hashable based on a custom hash value.
@dynamicMemberLookup
public struct HashableNodesGraph<Base: GraphComponent, HashValue: Hashable>: GraphComponent where Base.Node: Equatable {
    public typealias Edge = Base.Edge

    /// A node in the `HashableNodesGraph` that is hashable based on a custom hash value.
    public struct Node: Hashable {
        /// The base node.
        public let base: Base.Node
        /// The custom hash value for the node.
        public let hashValue: HashValue

        /// Initializes a new node with a base node and a custom hash value.
        /// - Parameters:
        ///   - base: The base node.
        ///   - hashValue: The custom hash value for the node.
        @inlinable public init(base: Base.Node, hashValue: HashValue) {
            self.base = base
            self.hashValue = hashValue
        }

        /// Hashes the essential components of the node by combining the custom hash value.
        /// - Parameter hasher: The hasher to use when combining the components of the node.
        @inlinable public func hash(into hasher: inout Hasher) {
            hasher.combine(hashValue)
        }
    }

    /// A graph wrapper that makes the nodes hashable based on a custom hash value.
    public let base: Base
    /// A closure that defines the hash value function for the nodes.
    public let hashValue: (Base.Node) -> HashValue

    /// Initializes a new `HashableNodesGraph` with a base graph and a custom hash value function for the nodes.
    /// - Parameters:
    ///   - base: The base graph.
    ///   - hashValue: A closure that defines the hash value function for the nodes.
    @inlinable public init(base: Base, hashValue: @escaping (Base.Node) -> HashValue) {
        self.base = base
        self.hashValue = hashValue
    }

    /// Returns the edges from a given node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of edges from the given node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        base.edges(from: node.base).map {
            $0.mapNode {
                Node(base: $0, hashValue: hashValue($0))
            }
        }
    }

    /// Subscript that accesses members on the underlying graph instance
    @inlinable public subscript<Member>(dynamicMember keyPath: KeyPath<Base, Member>) -> Member {
        base[keyPath: keyPath]
    }
}

extension GraphComponent where Node: Equatable {
    /// Creates a new `HashableNodesGraph` with a custom hash value function for the nodes.
    /// - Parameter hashValue: A closure that defines the hash value function for the nodes.
    /// - Returns: A `HashableNodesGraph` instance.
    @inlinable public func makeNodesHashable<HashValue: Hashable>(by hashValue: @escaping (Node) -> HashValue) -> HashableNodesGraph<Self, HashValue> {
        .init(base: self, hashValue: hashValue)
    }
}

/// A graph wrapper that makes the edges hashable based on a custom hash value.
@dynamicMemberLookup
public struct HashableEdgesGraph<Base: GraphComponent, HashValue: Hashable>: GraphComponent where Base.Edge: Equatable {
    public typealias Node = Base.Node

    /// An edge in the `HashableEdgesGraph` that is hashable based on a custom hash value.
    public struct Edge: Hashable {
        /// The base edge.
        public let base: Base.Edge
        /// The custom hash value for the edge.
        public let hashValue: HashValue

        /// Initializes a new edge with a base edge and a custom hash value.
        /// - Parameters:
        ///   - base: The base edge.
        ///   - hashValue: The custom hash value for the edge.
        @inlinable public init(base: Base.Edge, hashValue: HashValue) {
            self.base = base
            self.hashValue = hashValue
        }

        /// Hashes the essential components of the edge by combining the custom hash value.
        /// - Parameter hasher: The hasher to use when combining the components of the edge.
        @inlinable public func hash(into hasher: inout Hasher) {
            hasher.combine(hashValue)
        }
    }

    /// A graph wrapper that makes the edges hashable based on a custom hash value.
    public let base: Base
    /// A closure that defines the hash value function for the edges.
    public let hashValue: (Base.Edge) -> HashValue

    /// Initializes a new `HashableEdgesGraph` with a base graph and a custom hash value function for the edges.
    /// - Parameters:
    ///   - base: The base graph.
    ///   - hashValue: A closure that defines the hash value function for the edges.
    @inlinable public init(base: Base, hashValue: @escaping (Base.Edge) -> HashValue) {
        self.base = base
        self.hashValue = hashValue
    }

    /// Returns the edges from a given node.
    /// - Parameter node: The node from which to get the edges.
    /// - Returns: An array of edges from the given node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        base.edges(from: node).map {
            $0.mapEdge {
                Edge(base: $0, hashValue: hashValue($0))
            }
        }
    }

    /// Subscript that accesses members on the underlying graph instance
    @inlinable public subscript<Member>(dynamicMember keyPath: KeyPath<Base, Member>) -> Member {
        base[keyPath: keyPath]
    }
}

extension GraphComponent where Edge: Equatable {
    /// Creates a new `HashableEdgesGraph` with a custom hash value function for the edges.
    /// - Parameter hashValue: A closure that defines the hash value function for the edges.
    /// - Returns: A `HashableEdgesGraph` instance.
    @inlinable public func makeEdgesHashable<HashValue: Hashable>(by hashValue: @escaping (Edge) -> HashValue) -> HashableEdgesGraph<Self, HashValue> {
        .init(base: self, hashValue: hashValue)
    }
}
