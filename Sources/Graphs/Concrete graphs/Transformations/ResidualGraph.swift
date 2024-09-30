/// A graph that represents the residual capacities of a flow network.
@dynamicMemberLookup
public struct ResidualGraph<Base: Graph>: ConnectedGraph where Base.Node: Hashable, Base.Edge: Weighted, Base.Edge.Weight: Numeric {
    public typealias Node = Base.Node
    public typealias Edge = Base.Edge.Weight

    /// The base graph representing the original flow network.
    public let base: Base
    /// A dictionary representing the flow values between nodes.
    @usableFromInline var flows: [Node: [Node: Edge]]

    /// Initializes a residual graph with a given graph.
    /// - Parameter graph: The original graph.
    @inlinable public init(base: Base) {
        self.base = base
        self.flows = [:]
    }

    /// Returns the residual edges from a given node.
    /// - Parameter node: The source node.
    /// - Returns: An array of residual edges from the given node.
    @inlinable public func edges(from node: Node) -> [GraphEdge<Node, Edge>] {
        var residualEdges: [GraphEdge<Node, Edge>] = []
        for edge in base.edges(from: node) {
            let capacity = edge.value.weight
            let flow = flows[node]?[edge.destination] ?? 0
            let residualCapacity = capacity - flow
            if residualCapacity > 0 {
                residualEdges.append(GraphEdge(source: node, destination: edge.destination, value: residualCapacity))
            }

            // Add reverse edge for possible flow cancellation
            let reverseFlow = flows[edge.destination]?[node] ?? 0
            if reverseFlow > 0 {
                residualEdges.append(GraphEdge(source: edge.destination, destination: node, value: reverseFlow))
            }
        }
        return residualEdges
    }

    /// Adds flow along a given path.
    /// - Parameters:
    ///   - path: An array of nodes representing the path.
    ///   - flow: The flow to be added along the path.
    @inlinable public mutating func addFlow(path: [Node], flow: Edge) {
        for i in 0..<path.count-1 {
            let u = path[i]
            let v = path[i+1]
            flows[u, default: [:]][v, default: 0] += flow
            flows[v, default: [:]][u, default: 0] -= flow
        }
    }

    /// Adds flow from node `u` to node `v`.
    /// Parameters:
    ///  - u: The source node.
    /// - v: The destination node.
    /// - flow: The flow to be added.
    @inlinable public mutating func addFlow(from u: Node, to v: Node, flow: Edge) {
        flows[u, default: [:]][v, default: .zero] += flow
        flows[v, default: [:]][u, default: .zero] -= flow
    }

    /// Returns the flow from node `u` to node `v`.
    /// - Parameters:
    ///   - u: The source node.
    ///   - v: The destination node.
    /// - Returns: The flow from `u` to `v`.
    @inlinable public func flow(from u: Node, to v: Node) -> Edge {
        flows[u]?[v] ?? 0
    }

    /// Returns the capacity of the edge from node `u` to node `v`.
    /// - Parameters:
    ///   - u: The source node.
    ///   - v: The destination node.
    /// - Returns: The capacity of the edge from `u` to `v`.
    @inlinable public func capacity(from u: Node, to v: Node) -> Edge {
        base.edges(from: u).first(where: { $0.destination == v })?.value.weight ?? 0
    }

    /// Returns the residual capacity of the edge from node `u` to node `v`.
    /// - Parameters:
    ///   - u: The source node.
    ///   - v: The destination node.
    /// - Returns: The residual capacity of the edge from `u` to `v`.
    @inlinable public func residualCapacity(from u: Node, to v: Node) -> Edge {
        capacity(from: u, to: v) - flow(from: u, to: v)
    }

    /// Subscript that accesses members on the underlying graph instance
    @inlinable public subscript<Member>(dynamicMember keyPath: KeyPath<Base, Member>) -> Member {
        base[keyPath: keyPath]
    }
}

extension ResidualGraph {
    /// Returns the set of nodes reachable from the source node in the residual graph.
    /// - Parameter source: The source node.
    /// - Returns: A set of nodes reachable from the source node.
    @inlinable public func reachableNodes(from source: Node) -> Set<Node> {
        var reachable = Set<Node>()
        var queue: [Node] = [source]
        reachable.insert(source)

        while !queue.isEmpty {
            let current = queue.removeFirst()
            for edge in edges(from: current) {
                let neighbor = edge.destination
                if !reachable.contains(neighbor) && edge.value > .zero {
                    reachable.insert(neighbor)
                    queue.append(neighbor)
                }
            }
        }

        return reachable
    }
}
