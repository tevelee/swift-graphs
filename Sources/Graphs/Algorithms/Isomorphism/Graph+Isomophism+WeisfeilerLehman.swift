extension GraphIsomorphismAlgorithm {
    /// Creates a Weisfeiler-Lehman algorithm instance with the specified number of iterations.
    /// - Parameter iterations: The number of iterations to run the algorithm.
    /// - Returns: A new Weisfeiler-Lehman algorithm instance.
    @inlinable public static func weisfeilerLehman<Node, Edge>(iterations: Int = 3) -> Self where Self == WeisfeilerLehmanAlgorithm<Node, Edge> {
        WeisfeilerLehmanAlgorithm(iterations: iterations)
    }
}

/// An implementation of the Weisfeiler-Lehman algorithm for graph isomorphism.
public struct WeisfeilerLehmanAlgorithm<Node: Hashable, Edge>: GraphIsomorphismAlgorithm {
    /// The number of iterations to run the algorithm.
    public let iterations: Int

    /// Creates a new Weisfeiler-Lehman algorithm instance with the specified number of iterations.
    /// - Parameter iterations: The number of iterations to run the algorithm.
    @inlinable public init(iterations: Int) {
        self.iterations = iterations
    }

    /// Checks if two graphs are isomorphic using the Weisfeiler-Lehman algorithm.
    @inlinable public func areIsomorphic(
        _ graph1: some Graph<Node, Edge>,
        _ graph2: some Graph<Node, Edge>
    ) -> Bool {
        var labelsG1 = Dictionary(uniqueKeysWithValues: graph1.allNodes.map { ($0, "0") })
        var labelsG2 = Dictionary(uniqueKeysWithValues: graph2.allNodes.map { ($0, "0") })

        for _ in 0..<iterations {
            labelsG1 = refineLabels(graph: graph1, labels: labelsG1)
            labelsG2 = refineLabels(graph: graph2, labels: labelsG2)

            let multisetsG1 = labelsG1.values.sorted()
            let multisetsG2 = labelsG2.values.sorted()

            if multisetsG1 != multisetsG2 {
                return false
            }
        }

        return true
    }

    /// Refines the labels of the nodes in a graph.
    @usableFromInline func refineLabels(
        graph: some Graph<Node, Edge>,
        labels: [Node: String]
    ) -> [Node: String] {
        var newLabels: [Node: String] = [:]
        var labelCounter = 0
        var labelMap: [String: String] = [:]

        for node in graph.allNodes {
            // Collect labels of neighbors
            let neighborLabels = graph.adjacentNodes(to: node).map { labels[$0]! }.sorted()
            let signature = labels[node]! + neighborLabels.joined()

            // Assign new label
            if let existingLabel = labelMap[signature] {
                newLabels[node] = existingLabel
            } else {
                let newLabel = "\(labelCounter)"
                labelMap[signature] = newLabel
                newLabels[node] = newLabel
                labelCounter += 1
            }
        }

        return newLabels
    }
}
