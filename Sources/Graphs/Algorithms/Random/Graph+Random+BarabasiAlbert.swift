extension RandomGraphGeneration {
    /// Generates a random graph using the Barabási-Albert model.
    /// - Parameters:
    ///   - n: The number of nodes in the graph.
    ///   - m: The number of edges to attach from a new node to existing nodes.
    ///   - node: A closure that creates a node given an index.
    ///   - edge: A closure that creates an edge given two nodes.
    /// - Returns: A random graph generated using the Barabási-Albert model.
    @inlinable public static func barabasiAlbert<Node, Edge>(
        numberOfNodes n: Int,
        numberOfEdgesToAttach m: Int,
        node: @escaping (Int) -> Node,
        edge: @escaping (Node, Node) -> Edge
    ) -> Self where Self == BarabasiAlbertRandomGraphGenerator<Node, Edge> {
        .init(numberOfNodes: n, numberOfEdgesToAttach: m, node: node, edge: edge)
    }
}

/// A random graph generator that uses the Barabási-Albert model.
public struct BarabasiAlbertRandomGraphGenerator<Node, Edge>: RandomGraphGeneration {
    /// The number of nodes in the graph.
    public let n: Int
    /// The number of edges to attach from a new node to existing nodes.
    public let m: Int
    /// A closure that creates a node given an index.
    public let node: (Int) -> Node
    /// A closure that creates an edge given two nodes.
    public let edge: (Node, Node) -> Edge

    /// Creates a new Barabási-Albert random graph generator.
    @inlinable public init(
        numberOfNodes n: Int,
        numberOfEdgesToAttach m: Int,
        node: @escaping (Int) -> Node,
        edge: @escaping (Node, Node) -> Edge
    ) {
        precondition(m > 0 && n >= m, "Barabási-Albert model requires m > 0 and n >= m")
        self.n = n
        self.m = m
        self.node = node
        self.edge = edge
    }

    /// Generates a random graph using the Barabási-Albert model.
    @inlinable public func generateRandomGraph() -> (nodes: [Node], edges: [GraphEdge<Node, Edge>]) {
        var edges: [GraphEdge<Node, Edge>] = []
        var nodes: [Node] = []
        var degrees: [Int] = []  // Degrees of nodes, indexed by node index

        // Initialize a fully connected network of m nodes
        for i in 0 ..< m {
            let newNode = self.node(i)
            nodes.append(newNode)
            degrees.append(m - 1)
            for j in 0 ..< i {
                let existingNode = nodes[j]
                edges.append(GraphEdge(source: newNode, destination: existingNode, value: edge(newNode, existingNode)))
                edges.append(GraphEdge(source: existingNode, destination: newNode, value: edge(existingNode, newNode)))
            }
        }

        // Preferential attachment for the remaining nodes
        for i in m ..< n {
            let newNode = self.node(i)
            nodes.append(newNode)
            degrees.append(0)
            var targets = [Int]()

            // Calculate the cumulative degrees
            let totalDegree = degrees.reduce(0, +)

            // Attach m edges preferentially
            while targets.count < m {
                let randomValue = Int.random(in: 0 ..< totalDegree)
                var cumulativeDegree = 0
                for (index, degree) in degrees.enumerated() {
                    cumulativeDegree += degree
                    if cumulativeDegree > randomValue {
                        if index != i && !targets.contains(index) {
                            targets.append(index)
                        }
                        break
                    }
                }
            }

            for targetIndex in targets {
                let targetNode = nodes[targetIndex]
                edges.append(GraphEdge(source: newNode, destination: targetNode, value: edge(newNode, targetNode)))
                edges.append(GraphEdge(source: targetNode, destination: newNode, value: edge(targetNode, newNode)))
                degrees[i] += 1
                degrees[targetIndex] += 1
            }
        }

        return (nodes: nodes, edges: edges)
    }
}
