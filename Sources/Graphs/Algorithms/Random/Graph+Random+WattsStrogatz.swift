extension RandomGraphGeneration {
    /// Generates a random graph using the Watts-Strogatz model.
    /// - Parameters:
    ///   - n: The number of nodes in the graph.
    ///   - k: Each node is connected to k nearest neighbors in ring topology.
    ///   - p: The probability of rewiring each edge.
    ///   - node: A closure that creates a node given an index.
    ///   - edge: A closure that creates an edge given two nodes.
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
public struct WattsStrogatzRandomGraphGenerator<Node: Hashable, Edge: Hashable>: RandomGraphGeneration {
    /// The number of nodes in the graph.
    public let n: Int
    /// Each node is connected to k nearest neighbors in ring topology.
    public let k: Int
    /// The probability of rewiring each edge.
    public let p: Double
    /// A closure that creates a node given an index.
    public let node: (Int) -> Node
    /// A closure that creates an edge given two nodes.
    public let edge: (Node, Node) -> Edge

    /// Creates a new Watts-Strogatz random graph generator.
    /// - Parameters:
    ///   - n: The number of nodes in the graph.
    ///   - k: Each node is connected to k nearest neighbors in ring topology.
    ///   - p: The probability of rewiring each edge.
    ///   - node: A closure that creates a node given an index.
    ///   - edge: A closure that creates an edge given two nodes.
    @inlinable public init(
        numberOfNodes n: Int,
        k: Int,
        p: Double,
        node: @escaping (Int) -> Node,
        edge: @escaping (Node, Node) -> Edge
    ) {
        precondition(k >= 2 && k % 2 == 0, "Watts-Strogatz model requires k >= 2 and even")
        self.n = n
        self.k = k
        self.p = p
        self.node = node
        self.edge = edge
    }

    /// Generates a random graph using the Watts-Strogatz model.
    @inlinable public func generateRandomGraph() -> (nodes: [Node], edges: [GraphEdge<Node, Edge>]) {
        let nodes = (0 ..< n).map(node)
        var edgesSet = Set<GraphEdge<Node, Edge>>()

        // Ring lattice: each node is connected to k nearest neighbors
        for i in 0 ..< n {
            for j in 1 ... k / 2 {
                let source = nodes[i]
                let destination = nodes[(i + j) % n]
                let edgeForward = GraphEdge(source: source, destination: destination, value: edge(source, destination))
                let edgeBackward = GraphEdge(source: destination, destination: source, value: edge(destination, source))
                edgesSet.insert(edgeForward)
                edgesSet.insert(edgeBackward)
            }
        }

        // Rewire edges with probability p
        let edgesList = Array(edgesSet)
        for i in 0 ..< edgesList.count where Double.random(in: 0 ... 1) < p {
            let oldEdge = edgesList[i]
            let source = oldEdge.source
            // Find a new destination node
            var newDestination: Node
            repeat {
                newDestination = nodes[Int.random(in: 0 ..< n)]
            } while newDestination == source || edgesSet.contains(GraphEdge(source: source, destination: newDestination, value: edge(source, newDestination)))

            // Remove old edge and add new edge
            edgesSet.remove(oldEdge)
            edgesSet.remove(GraphEdge(source: oldEdge.destination, destination: source, value: edge(oldEdge.destination, source)))

            let newEdgeForward = GraphEdge(source: source, destination: newDestination, value: edge(source, newDestination))
            let newEdgeBackward = GraphEdge(source: newDestination, destination: source, value: edge(newDestination, source))
            edgesSet.insert(newEdgeForward)
            edgesSet.insert(newEdgeBackward)
        }

        return (nodes: nodes, edges: Array(edgesSet))
    }
}
