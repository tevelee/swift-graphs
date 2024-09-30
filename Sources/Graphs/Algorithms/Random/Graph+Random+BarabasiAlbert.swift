extension RandomGraphGeneration {
    /// Generates a random graph using the Barabási-Albert model.
    /// - Parameters:
    ///  - numberOfNodes: The number of nodes in the graph.
    ///  - numberOfEdgesToAttach: The number of edges to attach from a new node to existing nodes.
    ///  - node: A closure that creates a node given an index.
    ///  - edge: A closure that creates an edge given two nodes.
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
public struct BarabasiAlbertRandomGraphGenerator<Node: Hashable, Edge>: RandomGraphGeneration {
    /// The number of nodes in the graph.
    @usableFromInline let n: Int
    /// The number of edges to attach from a new node to existing nodes.
    @usableFromInline let m: Int
    /// A closure that creates a node given an index.
    @usableFromInline let node: (Int) -> Node
    /// A closure that creates an edge given two nodes.
    @usableFromInline let edge: (Node, Node) -> Edge

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
    @inlinable public func generateRandomGraph() -> AdjacencyListGraph<Node, Edge> {
        var edges: [GraphEdge<Node, Edge>] = []
        var nodes: [Node] = []
        var degrees: [Node: Int] = [:]

        for i in 0 ..< m {
            let node = self.node(i)
            nodes.append(node)
            degrees[node] = m - 1
        }

        for i in m ..< n {
            let newNode = self.node(i)
            let totalDegree = degrees.values.reduce(0, +)
            var targets = Set<Node>()
            while targets.count < m {
                let randomValue = Int.random(in: 0..<totalDegree)
                var cumulativeDegree = 0
                for node in nodes {
                    cumulativeDegree += degrees[node]!
                    if cumulativeDegree > randomValue {
                        targets.insert(node)
                        break
                    }
                }
            }
            for target in targets {
                edges.append(GraphEdge(source: newNode, destination: target, value: edge(newNode, target)))
                edges.append(GraphEdge(source: target, destination: newNode, value: edge(target, newNode)))
                degrees[newNode, default: 0] += 1
                degrees[target]! += 1
            }
            nodes.append(newNode)
        }

        return AdjacencyListGraph(edges: edges)
    }
}
