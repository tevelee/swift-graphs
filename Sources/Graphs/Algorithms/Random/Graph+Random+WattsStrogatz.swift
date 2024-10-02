extension RandomGraphGeneration {
    /// Generates a random graph using the Watts-Strogatz model.
    /// - Parameters:
    ///  - numberOfNodes: The number of nodes in the graph.
    ///  - k: The number of edges to attach from a new node to existing nodes.
    ///  - p: The probability of rewiring an edge.
    ///  - node: A closure that creates a node given an index.
    ///  - edge: A closure that creates an edge given two nodes.
    /// - Returns: A random graph generated using the Watts-Strogatz model.
    @inlinable public static func wattsStrogatz<Node, Edge>(
        numberOfNodes n: Int,
        k: Int,
        p: Double,
        node: @escaping (Int) -> Node,
        edge: @escaping (Node, Node) -> Edge
    ) -> Self where Self == WattsStrogatzRandomGraphGenerator<Node, Edge> {
        .init(numberOfNodes: n, k: k, p: p, node: node, edge: edge)
    }
}

/// A random graph generator that uses the Watts-Strogatz model.
public struct WattsStrogatzRandomGraphGenerator<Node: Equatable, Edge>: RandomGraphGeneration {
    /// The number of nodes in the graph.
    public let n: Int
    /// The number of edges to attach from a new node to existing nodes.
    public let k: Int
    /// The probability of rewiring an edge.
    public let p: Double
    /// A closure that creates a node given an index.
    public let node: (Int) -> Node
    /// A closure that creates an edge given two nodes.
    public let edge: (Node, Node) -> Edge

    /// Creates a new Watts-Strogatz random graph generator.
    /// - Parameters:
    /// - numberOfNodes: The number of nodes in the graph.
    /// - k: The number of edges to attach from a new node to existing nodes.
    /// - p: The probability of rewiring an edge.
    /// - node: A closure that creates a node given an index.
    /// - edge: A closure that creates an edge given two nodes.
    /// - Returns: A random graph generated using the Watts-Strogatz model.
    @inlinable public init(numberOfNodes n: Int, k: Int, p: Double, node: @escaping (Int) -> Node, edge: @escaping (Node, Node) -> Edge) {
        precondition(k >= 2 && k % 2 == 0, "Watts-Strogatz model requires k >= 2 and even")
        self.n = n
        self.k = k
        self.p = p
        self.node = node
        self.edge = edge
    }

    // Internal edge type to avoid dealing with edges
    @usableFromInline struct _Edge: Equatable {
        @usableFromInline let source: Node
        @usableFromInline let destination: Node

        @usableFromInline init(source: Node, destination: Node) {
            self.source = source
            self.destination = destination
        }
    }

    /// Generates a random graph using the Watts-Strogatz model.
    @inlinable public func generateRandomGraph() -> ConnectedGraph<Node, Edge> {
        let nodes = (0 ..< n).map(node)
        var edges: [_Edge] = []

        for i in 0 ..< n {
            for j in 1 ... k / 2 {
                let source = nodes[i]
                let destination = nodes[(i + j) % n]
                edges.append(_Edge(source: source, destination: destination))
                edges.append(_Edge(source: destination, destination: source))
            }
        }

        // Rewire edges with probability p
        for i in 0 ..< n {
            for j in 1 ... k / 2 {
                if Double.random(in: 0 ... 1) < p {
                    let source = nodes[i]
                    let oldDestination = nodes[(i + j) % n]
                    edges.removeAll { $0.source == source && $0.destination == oldDestination }
                    edges.removeAll { $0.source == oldDestination && $0.destination == source }

                    // Add new edge to a random node not equal to source and not already connected
                    var newDestination: Node
                    repeat {
                        newDestination = nodes[Int.random(in: 0 ..< n)]
                    } while newDestination == source || edges.contains(where: { $0.source == source && $0.destination == newDestination })

                    edges.append(_Edge(source: source, destination: newDestination))
                    edges.append(_Edge(source: newDestination, destination: source))
                }
            }
        }

        return ConnectedGraph(
            edges: edges.map {
                GraphEdge(source: $0.source, destination: $0.destination, value: edge($0.source, $0.destination))
            }
        )
    }
}
