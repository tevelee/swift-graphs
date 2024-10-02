extension EulerianPathAlgorithm {
    /// Creates a Hierholzer algorithm instance for graphs with numeric edge values.
    /// - Returns: An instance of `HierholzerEulerianPathAlgorithm`.
    @inlinable public static func hierholzer<Node, Edge: Numeric>() -> Self where Self == HierholzerEulerianPathAlgorithm<Node, Edge> {
        .init(defaultEdgeValue: .zero)
    }

    /// Creates a Hierholzer algorithm instance for graphs with empty edge values.
    /// - Returns: An instance of `HierholzerEulerianPathAlgorithm`.
    @inlinable public static func hierholzer<Node>() -> Self where Self == HierholzerEulerianPathAlgorithm<Node, Empty> {
        .init(defaultEdgeValue: Empty())
    }
}

/// An implementation of the Hierholzer algorithm for finding Eulerian paths and cycles in a graph.
public struct HierholzerEulerianPathAlgorithm<Node: Hashable, Edge>: EulerianPathAlgorithm {
    /// The default edge value used for temporary edges.
    public let defaultEdgeValue: Edge

    /// Initializes a new `HierholzerEulerianPathAlgorithm` instance with the given default edge value.
    /// - Parameter defaultEdgeValue: The default edge value used for temporary edges.
    @inlinable public init(defaultEdgeValue: Edge) {
        self.defaultEdgeValue = defaultEdgeValue
    }

    /// Finds an Eulerian path from the source node to the destination node in the graph using the Hierholzer algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - destination: The target node.
    ///   - graph: The graph in which to find the Eulerian path.
    /// - Returns: A `Path` instance representing the Eulerian path, or `nil` if no path is found.
    @inlinable public func findEulerianPath(
        from source: Node,
        to destination: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>? {
        guard graph.hasEulerianPath() else { return nil }

        var adjacency = [Node: [GraphEdge<Node, Edge>]]()
        for edge in graph.allEdges {
            adjacency[edge.source, default: []].append(edge)
        }

        let tempEdge = GraphEdge(source: destination, destination: source, value: defaultEdgeValue)
        adjacency[destination, default: []].append(tempEdge)

        var stack = [source]
        var circuit: [GraphEdge<Node, Edge>] = []

        while !stack.isEmpty {
            let current = stack.last!

            if var edges = adjacency[current], !edges.isEmpty {
                let edge = edges.removeLast()
                adjacency[current]! = edges
                stack.append(edge.destination)
            } else {
                stack.removeLast()
                if let last = stack.last, let edge = graph.allEdges.first(where: { $0.source == last && $0.destination == current }) {
                    circuit.append(edge)
                }
            }
        }

        let orderedCircuit = Array(circuit.reversed())

        guard let tempIndex = orderedCircuit.firstIndex(where: { $0.source == destination && $0.destination == source }) else {
            return nil
        }

        let pathEdges = orderedCircuit[tempIndex + 1 ..< orderedCircuit.endIndex] + orderedCircuit[0 ..< tempIndex]

        let finalPathEdges = pathEdges.filter { !($0.source == destination && $0.destination == source) }

        guard finalPathEdges.count == graph.allEdges.count else {
            return nil
        }
        return Path(source: source, destination: destination, edges: Array(finalPathEdges))
    }

    /// Finds an Eulerian cycle from the source node in the graph using the Hierholzer algorithm.
    /// - Parameters:
    ///   - source: The starting node.
    ///   - graph: The graph in which to find the Eulerian cycle.
    /// - Returns: A `Path` instance representing the Eulerian cycle, or `nil` if no cycle is found.
    @inlinable public func findEulerianCycle(
        from source: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>? {
        guard graph.hasEulerianCycle() else { return nil }

        var adjacency = [Node: [GraphEdge<Node, Edge>]]()
        for edge in graph.allEdges {
            adjacency[edge.source, default: []].append(edge)
        }

        var stack = [source]
        var circuit: [GraphEdge<Node, Edge>] = []

        while !stack.isEmpty {
            let current = stack.last!

            if var edges = adjacency[current], !edges.isEmpty {
                let edge = edges.removeLast()
                adjacency[current]! = edges
                stack.append(edge.destination)
            } else {
                stack.removeLast()
                if let last = stack.last, let edge = graph.allEdges.first(where: { $0.source == last && $0.destination == current }) {
                    circuit.append(edge)
                }
            }
        }

        let orderedCircuit = circuit.reversed()

        guard orderedCircuit.count == graph.allEdges.count else {
            return nil
        }
        return Path(source: source, destination: source, edges: Array(orderedCircuit))
    }
}
