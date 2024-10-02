extension GraphIsomorphismAlgorithm {
    /// Creates a VF2 algorithm instance.
    @inlinable public static func vf2<Node, Edge>() -> Self where Self == VF2Algorithm<Node, Edge> {
        VF2Algorithm()
    }
}

extension Graph where Node: Hashable {
    /// Determines if the graph is isomorphic to another graph using the VF2 algorithm.
    @inlinable public func isIsomorphic(
        to other: some Graph<Node, Edge>
    ) -> Bool {
        isIsomorphic(to: other, using: .vf2())
    }
}

/// An implementation of the VF2 algorithm for graph isomorphism.
public struct VF2Algorithm<Node: Hashable, Edge>: GraphIsomorphismAlgorithm {
    /// Creates a new VF2 algorithm instance.
    @inlinable public init() {}

    /// Checks if two graphs are isomorphic using the VF2 algorithm.
    /// - Parameters:
    ///  - graph1: The first graph.
    ///  - graph2: The second graph.
    /// - Returns: A boolean value indicating whether the two graphs are isomorphic.
    @inlinable public func areIsomorphic(
        _ graph1: some Graph<Node, Edge>,
        _ graph2: some Graph<Node, Edge>
    ) -> Bool {
        if graph1.allNodes.count != graph2.allNodes.count || graph1.allEdges.count != graph2.allEdges.count {
            return false
        }

        var mappingG1toG2: [Node: Node] = [:]
        var mappingG2toG1: [Node: Node] = [:]

        return match(
            graph1: graph1,
            graph2: graph2,
            mappingG1toG2: &mappingG1toG2,
            mappingG2toG1: &mappingG2toG1,
            depth: 0,
            maxDepth: graph1.allNodes.count
        )
    }

    /// Recursively tries to match nodes from two graphs.
    @usableFromInline func match(
        graph1: some Graph<Node, Edge>,
        graph2: some Graph<Node, Edge>,
        mappingG1toG2: inout [Node: Node],
        mappingG2toG1: inout [Node: Node],
        depth: Int,
        maxDepth: Int
    ) -> Bool {
        if depth == maxDepth {
            // All nodes have been mapped
            return true
        }

        let unmappedG1 = graph1.allNodes.filter { mappingG1toG2[$0] == nil }
        let unmappedG2 = graph2.allNodes.filter { mappingG2toG1[$0] == nil }

        for nodeG1 in unmappedG1 {
            for nodeG2 in unmappedG2 {
                if isFeasiblePair(
                    nodeG1: nodeG1,
                    nodeG2: nodeG2,
                    graph1: graph1,
                    graph2: graph2,
                    mappingG1toG2: mappingG1toG2,
                    mappingG2toG1: mappingG2toG1
                ) {
                    mappingG1toG2[nodeG1] = nodeG2
                    mappingG2toG1[nodeG2] = nodeG1

                    if match(
                        graph1: graph1,
                        graph2: graph2,
                        mappingG1toG2: &mappingG1toG2,
                        mappingG2toG1: &mappingG2toG1,
                        depth: depth + 1,
                        maxDepth: maxDepth
                    ) {
                        return true
                    }

                    mappingG1toG2[nodeG1] = nil
                    mappingG2toG1[nodeG2] = nil
                }
            }
        }

        return false
    }

    /// Checks if a pair of nodes is feasible to be matched.
    @usableFromInline func isFeasiblePair(
        nodeG1: Node,
        nodeG2: Node,
        graph1: some Graph<Node, Edge>,
        graph2: some Graph<Node, Edge>,
        mappingG1toG2: [Node: Node],
        mappingG2toG1: [Node: Node]
    ) -> Bool {
        if graph1.degree(of: nodeG1) != graph2.degree(of: nodeG2) {
            return false
        }

        for neighborG1 in graph1.adjacentNodes(to: nodeG1) {
            if let mappedNeighbor = mappingG1toG2[neighborG1] {
                if !graph2.isAdjacent(nodeG2, mappedNeighbor) {
                    return false
                }
            }
        }

        return true
    }
}
