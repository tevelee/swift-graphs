extension RandomGraphGeneration {
    /// Generates a random graph using the Erdős-Rényi model.
    /// - Parameters:
    ///   - n: The number of nodes in the graph.
    ///   - p: The probability of an edge between two nodes.
    ///   - node: A closure that creates a node given an index.
    ///   - edge: A closure that creates an edge given two nodes.
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
    ///   - n: The number of nodes in the graph.
    ///   - p: The probability of an edge between two nodes.
    ///   - node: A closure that creates a node given an index.
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
    ///   - n: The number of nodes in the graph.
    ///   - p: The probability of an edge between two nodes.
    /// - Returns: A random graph generated using the Erdős-Rényi model.
    @inlinable public static func erdosRenyi(
        numberOfNodes n: Int,
        probabilityOfEdge p: Double = 0.5
    ) -> Self where Self == ErdosRenyiRandomGraphGenerator<Int, Empty> {
        .init(numberOfNodes: n, probabilityOfEdge: p, node: { $0 }, edge: { _, _ in Empty() })
    }
}

extension RandomBinaryGraphGeneration {
    /// Generates a random binary graph using the Erdős-Rényi model.
    /// - Parameters:
    ///   - n: The number of nodes in the graph.
    ///   - p: The probability of an edge between two nodes.
    ///   - node: A closure that creates a node given an index.
    ///   - edge: A closure that creates an edge given two nodes.
    /// - Returns: A random graph generated using the Erdős-Rényi model.
    @inlinable public static func erdosRenyi<Node, Edge>(
        numberOfNodes n: Int,
        probabilityOfEdge p: Double = 0.5,
        node: @escaping (Int) -> Node,
        edge: @escaping (Node, Node) -> Edge
    ) -> Self where Self == ErdosRenyiRandomGraphGenerator<Node, Edge> {
        .init(numberOfNodes: n, probabilityOfEdge: p, node: node, edge: edge)
    }

    /// Generates a random binary graph using the Erdős-Rényi model.
    /// - Parameters:
    ///   - n: The number of nodes in the graph.
    ///   - p: The probability of an edge between two nodes.
    ///   - node: A closure that creates a node given an index.
    /// - Returns: A random graph generated using the Erdős-Rényi model.
    @inlinable public static func erdosRenyi<Node>(
        numberOfNodes n: Int,
        probabilityOfEdge p: Double = 0.5,
        node: @escaping (Int) -> Node
    ) -> Self where Self == ErdosRenyiRandomGraphGenerator<Node, Empty> {
        .init(numberOfNodes: n, probabilityOfEdge: p, node: node) { _, _ in Empty() }
    }

    /// Generates a random binary graph using the Erdős-Rényi model.
    /// - Parameters:
    ///   - n: The number of nodes in the graph.
    ///   - p: The probability of an edge between two nodes.
    /// - Returns: A random graph generated using the Erdős-Rényi model.
    @inlinable public static func erdosRenyi(
        numberOfNodes n: Int,
        probabilityOfEdge p: Double = 0.5
    ) -> Self where Self == ErdosRenyiRandomGraphGenerator<Int, Empty> {
        .init(numberOfNodes: n, probabilityOfEdge: p, node: { $0 }, edge: { _, _ in Empty() })
    }
}

/// A random graph generator that uses the Erdős-Rényi model.
public struct ErdosRenyiRandomGraphGenerator<Node, Edge> {
    /// The number of nodes in the graph.
    public let n: Int
    /// The probability of an edge between two nodes.
    public let p: Double
    /// A closure that creates a node given an index.
    public let node: (Int) -> Node
    /// A closure that creates an edge given two nodes.
    public let edge: (Node, Node) -> Edge

    /// Creates a new Erdős-Rényi random graph generator.
    /// - Parameters:
    ///   - n: The number of nodes in the graph.
    ///   - p: The probability of an edge between two nodes.
    ///   - node: A closure that creates a node given an index.
    ///   - edge: A closure that creates an edge given two nodes.
    @inlinable public init(
        numberOfNodes n: Int,
        probabilityOfEdge p: Double,
        node: @escaping (Int) -> Node,
        edge: @escaping (Node, Node) -> Edge
    ) {
        self.n = n
        self.p = p
        self.node = node
        self.edge = edge
    }
}

extension ErdosRenyiRandomGraphGenerator: RandomGraphGeneration {
    /// Generates a random graph using the Erdős-Rényi model.
    @inlinable public func generateRandomGraph() -> (nodes: [Node], edges: [GraphEdge<Node, Edge>]) {
        let nodes = (0 ..< n).map(node)
        var edges: [GraphEdge<Node, Edge>] = []

        for i in 0 ..< n {
            for j in (i + 1) ..< n {
                let source = nodes[i]
                let destination = nodes[j]
                if Double.random(in: 0 ... 1) < p {
                    edges.append(GraphEdge(source: source, destination: destination, value: edge(source, destination)))
                }
                if Double.random(in: 0 ... 1) < p {
                    edges.append(GraphEdge(source: destination, destination: source, value: edge(destination, source)))
                }
            }
        }

        return (nodes: nodes, edges: edges)
    }
}

extension ErdosRenyiRandomGraphGenerator: RandomBinaryGraphGeneration where Node: Hashable {
    /// Generates a random binary graph using the Erdős-Rényi model.
    @inlinable public func generateRandomBinaryGraph() -> (nodes: [Node], edges: [BinaryGraphEdges<Node, Edge>]) {
        let nodes = (0 ..< n).map(node)
        var adjacency: [Node: BinaryGraphEdges<Node, Edge>] = [:]

        // Initialize adjacency list
        for node in nodes {
            adjacency[node] = BinaryGraphEdges(source: node, lhs: nil, rhs: nil)
        }

        // Generate edges with probability p, ensuring degree <= 2
        for i in 0 ..< n {
            for j in (i + 1) ..< n {
                let nodeA = nodes[i]
                let nodeB = nodes[j]

                // Check if both nodes can accept more edges
                let edgesFromA = adjacency[nodeA]!
                let edgesFromB = adjacency[nodeB]!

                if edgesFromA.elements.count >= 2 || edgesFromB.elements.count >= 2 {
                    continue
                }

                if Double.random(in: 0 ... 1) < p {
                    let edgeAB = GraphEdge(source: nodeA, destination: nodeB, value: edge(nodeA, nodeB))
                    let edgeBA = GraphEdge(source: nodeB, destination: nodeA, value: edge(nodeB, nodeA))

                    // Add edge to nodeA
                    var updatedEdgesFromA = edgesFromA
                    if updatedEdgesFromA.lhs == nil {
                        updatedEdgesFromA.lhs = edgeAB
                    } else {
                        updatedEdgesFromA.rhs = edgeAB
                    }
                    adjacency[nodeA] = updatedEdgesFromA

                    // Add edge to nodeB
                    var updatedEdgesFromB = edgesFromB
                    if updatedEdgesFromB.lhs == nil {
                        updatedEdgesFromB.lhs = edgeBA
                    } else {
                        updatedEdgesFromB.rhs = edgeBA
                    }
                    adjacency[nodeB] = updatedEdgesFromB
                }
            }
        }

        let edges = Array(adjacency.values)
        return (nodes: nodes, edges: edges)
    }
}
