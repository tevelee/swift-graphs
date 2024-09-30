extension Graph where Node: Hashable {
    /// Checks if the graph is connected.
    /// - Returns: `true` if the graph is connected, `false` otherwise.
    @inlinable public func isConnected() -> Bool {
        if allNodes.isEmpty {
            return true
        }
        for node in allNodes where traverse(from: node, strategy: .bfs().visitEachNodeOnce()).count == allNodes.count {
            return true
        }
        return false
    }

    /// Checks if the graph contains a cycle.
    /// - Returns: `true` if the graph contains a cycle, `false` otherwise.
    @inlinable public func isCyclic() -> Bool {
        var visited = Set<Node>()
        for node in allNodes where !visited.contains(node) {
            for newNode in traversal(from: node, strategy: .dfs()) {
                visited.insert(newNode)
            }
        }
        return false
    }

    /// Checks if the graph is a tree.
    /// - Returns: `true` if the graph is a tree, `false` otherwise.
    @inlinable public func isTree() -> Bool {
        return isConnected() && !isCyclic()
    }

    /// Checks if the graph has an Eulerian path.
    /// - Returns: `true` if the graph has an Eulerian path, `false` otherwise.
    @inlinable public func hasEulerianPath() -> Bool {
        eulerianProperties().hasEulerianPath
    }

    /// Checks if the graph has an Eulerian cycle.
    /// - Returns: `true` if the graph has an Eulerian cycle, `false` otherwise.
    @inlinable public func hasEulerianCycle() -> Bool {
        eulerianProperties().hasEulerianCycle
    }

    /// Computes the Eulerian properties of the graph.
    /// - Returns: A tuple containing two Boolean values indicating whether the graph has an Eulerian path and an Eulerian cycle.
    @inlinable public func eulerianProperties() -> (hasEulerianPath: Bool, hasEulerianCycle: Bool) {
        guard isConnected() else {
            return (false, false)
        }

        var inDegree: [Node: Int] = [:]
        var outDegree: [Node: Int] = [:]

        for edge in allEdges {
            outDegree[edge.source, default: 0] += 1
            inDegree[edge.destination, default: 0] += 1
        }

        var startNodeCount = 0
        var endNodeCount = 0
        var isBalanced = true

        for node in allNodes {
            let out = outDegree[node] ?? 0
            let `in` = inDegree[node] ?? 0

            if out == `in` + 1 {
                startNodeCount += 1
                if startNodeCount > 1 {
                    isBalanced = false
                    break
                }
            } else if `in` == out + 1 {
                endNodeCount += 1
                if endNodeCount > 1 {
                    isBalanced = false
                    break
                }
            } else if `in` != out {
                isBalanced = false
                break
            }
        }

        let hasEulerianCycle = isBalanced && startNodeCount == 0 && endNodeCount == 0
        let hasEulerianPath = (startNodeCount == 1 && endNodeCount == 1) || hasEulerianCycle
        return (hasEulerianPath, hasEulerianCycle)
    }

    /// Returns the degree of the specified node.
    /// - Parameter node: The node for which to calculate the degree.
    /// - Returns: The degree of the specified node.
    public func degree(of node: Node) -> Int {
        edges(connectedTo: node).count
    }

    /// Returns the out-degree of the specified node.
    /// - Parameter node: The node for which to calculate the out-degree.
    /// - Returns: The out-degree of the specified node.
    @inlinable public func outDegree(of node: Node) -> Int {
        allEdges.filter { $0.source == node }.count
    }

    /// Returns the in-degree of the specified node.
    /// - Parameter node: The node for which to calculate the in-degree.
    /// - Returns: The in-degree of the specified node.
    @inlinable public func inDegree(of node: Node) -> Int {
        allEdges.filter { $0.destination == node }.count
    }

    /// Checks if two nodes are adjacent.
    /// - Parameters:
    ///   - node1: The first node.
    ///   - node2: The second node.
    /// - Returns: `true` if the nodes are adjacent, `false` otherwise.
    @inlinable public func isAdjacent(_ node1: Node, _ node2: Node) -> Bool {
        allEdges.contains { ($0.source == node1 && $0.destination == node2) || ($0.source == node2 && $0.destination == node1) }
    }

    /// Returns all edges connected to the specified node.
    /// - Parameter node: The node for which to get the connected edges.
    /// - Returns: An array of `GraphEdge` instances containing the edges connected to the specified node.
    public func edges(connectedTo node: Node) -> [GraphEdge<Node, Edge>] {
        allEdges.filter { $0.source == node || $0.destination == node }
    }

    /// Returns all nodes adjacent to the specified node.
    /// - Parameter node: The node for which to get adjacent nodes.
    /// - Returns: An array of nodes adjacent to the specified node.
    public func adjacentNodes(to node: Node) -> [Node] {
        edges(connectedTo: node).map { $0.source == node ? $0.destination : $0.source }
    }

    /// Checks if the graph satisfies Dirac's theorem.
    /// - Returns: `true` if the graph satisfies Dirac's theorem, `false` otherwise.
    @inlinable public func satisfiesDirac() -> Bool {
        let n = allNodes.count
        guard n >= 3 else { return false }
        return allNodes.allSatisfy { node in
            outDegree(of: node) >= n / 2
        }
    }

    /// Checks if the graph satisfies Ore's theorem.
    /// - Returns: `true` if the graph satisfies Ore's theorem, `false` otherwise.
    @inlinable public func satisfiesOre() -> Bool {
        let n = allNodes.count
        guard n >= 3 else { return false }
        for node in allNodes {
            for other in allNodes where other != node && !isAdjacent(node, other) {
                if outDegree(of: node) + outDegree(of: other) < n {
                    return false
                }
            }
        }
        return true
    }

    /// Performs a topological sort on the graph.
    /// - Returns: An array of nodes in topologically sorted order, or `nil` if the graph contains a cycle.
    @inlinable public func topologicalSort() -> [Node]? {
        let count = allNodes.count
        return allNodes.lazy.map {
            self.traverse(from: $0, strategy: .dfs().visitEachNodeOnce())
        }.first { $0.count == count }
    }

    /// Checks if the graph is planar.
    /// - Returns: `true` if the graph is planar, `false` otherwise.
    @inlinable public func isPlanar() -> Bool {
        let v = allNodes.count
        let e = allEdges.count

        if v <= 4 {
            return true
        }

        return e <= 3 * v - 6
    }

    /// Checks if the graph is bipartite.
    /// - Returns: `true` if the graph is bipartite, `false` otherwise.
    @inlinable public func isBipartite() -> Bool {
        func bipartiteDFS(node: Node, color: inout [Node: Int], currentColor: Int) -> Bool {
            color[node] = currentColor

            for edge in edges(from: node) {
                let neighbor = edge.destination

                if color[neighbor] == nil {
                    if !bipartiteDFS(node: neighbor, color: &color, currentColor: 1 - currentColor) {
                        return false
                    }
                } else if color[neighbor] == color[node] {
                    return false
                }
            }

            return true
        }

        var color: [Node: Int] = [:]
        for node in allNodes {
            if color[node] == nil {
                if !bipartiteDFS(node: node, color: &color, currentColor: 0) {
                    return false
                }
            }
        }
        return true
    }
}
