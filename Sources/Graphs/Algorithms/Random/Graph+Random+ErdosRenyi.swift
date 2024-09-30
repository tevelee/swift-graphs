extension RandomGraphGeneration {
    /// Generates a random graph using the Erdős-Rényi model.
    /// - Parameters:
    ///  - numberOfNodes: The number of nodes in the graph.
    ///  - probabilityOfEdge: The probability of an edge between two nodes.
    ///  - node: A closure that creates a node given an index.
    ///  - edge: A closure that creates an edge given two nodes.
    /// - Returns: A random graph generated using the Erdős-Rényi model.
    @inlinable public static func erdosRenyi<Node, Edge>(
        numberOfNodes n: Int,
        probabilityOfEdge p: Double = 0.5,
        node: @escaping (Int) -> Node,
        edge: @escaping (Node, Node) -> Edge
    ) -> Self where Self == ErdosRenyiRandomGraphGenerator<Node, Edge> {
        .init(numberOfNodes: n, probabilityOfEdge: p, node: node, edge: edge)
    }

    /// Generates a random graph using the Erdős-Rényi model.
    /// - Parameters:
    ///  - numberOfNodes: The number of nodes in the graph.
    ///  - probabilityOfEdge: The probability of an edge between two nodes.
    ///  - node: A closure that creates a node given an index.
    /// - Returns: A random graph generated using the Erdős-Rényi model.
    @inlinable public static func erdosRenyi<Node>(
        numberOfNodes n: Int,
        probabilityOfEdge p: Double = 0.5,
        node: @escaping (Int) -> Node
    ) -> Self where Self == ErdosRenyiRandomGraphGenerator<Node, Empty> {
        .init(numberOfNodes: n, probabilityOfEdge: p, node: node) { _, _ in Empty() }
    }

    /// Generates a random graph using the Erdős-Rényi model.
    /// - Parameters:
    ///  - numberOfNodes: The number of nodes in the graph.
    ///  - probabilityOfEdge: The probability of an edge between two nodes.
    /// - Returns: A random graph generated using the Erdős-Rényi model.
    @inlinable public static func erdosRenyi(
        numberOfNodes n: Int,
        probabilityOfEdge p: Double = 0.5
    ) -> Self where Self == ErdosRenyiRandomGraphGenerator<Int, Empty> {
        .init(numberOfNodes: n, probabilityOfEdge: p, node: \.self) { _, _ in Empty() }
    }
}

/// A random graph generator that uses the Erdős-Rényi model.
public struct ErdosRenyiRandomGraphGenerator<Node: Equatable, Edge>: RandomGraphGeneration {
    /// The number of nodes in the graph.
    @usableFromInline let n: Int
    /// The probability of an edge between two nodes.
    @usableFromInline let p: Double
    /// A closure that creates a node given an index.
    @usableFromInline let node: (Int) -> Node
    /// A closure that creates an edge given two nodes.
    @usableFromInline let edge: (Node, Node) -> Edge

    /// Creates a new Erdős-Rényi random graph generator.
    /// - Parameters:
    ///  - numberOfNodes: The number of nodes in the graph.
    ///  - probabilityOfEdge: The probability of an edge between two nodes.
    ///  - node: A closure that creates a node given an index.
    ///  - edge: A closure that creates an edge given two nodes.
    @inlinable public init(numberOfNodes n: Int, probabilityOfEdge p: Double, node: @escaping (Int) -> Node, edge: @escaping (Node, Node) -> Edge) {
        self.n = n
        self.p = p
        self.node = node
        self.edge = edge
    }

    /// Generates a random graph using the Erdős-Rényi model.
    @inlinable public func generateRandomGraph() -> AdjacencyListGraph<Node, Edge> {
        let nodes = (0 ..< n).map(node)
        var edges: [GraphEdge<Node, Edge>] = []
        for i in 0 ..< n {
            for j in (i + 1) ..< n {
                let source = nodes[i]
                let destination = nodes[j]
                if Double.random(in: 0...1) < p {
                    edges.append(GraphEdge(source: source, destination: destination, value: edge(source, destination)))
                }
                if Double.random(in: 0...1) < p {
                    edges.append(GraphEdge(source: destination, destination: source, value: edge(destination, source)))
                }
            }
        }

        return AdjacencyListGraph(edges: edges)
    }
}
