import Collections

extension GraphComponent where Edge: Weighted {
    /// Computes all shortest paths from the source node to the destination node in the graph.
    /// - Parameter source: The starting node.
    /// - Parameter destination: The target node.
    /// - Parameter condition: A closure that determines when to stop the search.
    /// - Parameter algorithm: The algorithm to use to compute the shortest paths.
    /// - Returns: A dictionary where the keys are nodes and the values are arrays of paths.
    @inlinable public func allShortestPaths(
        from source: Node,
        to destination: Node,
        until condition: (Node) -> Bool,
        using algorithm: some AllShortestPathsAlgorithm<Node, Edge>
    ) -> [Path<Node, Edge>] {
        algorithm.allShortestPaths(from: source, to: destination, until: condition, in: self)
    }

    /// Computes all shortest paths from the source node to the destination node in the graph using Dijkstra's algorithm.
    /// - Parameter source: The starting node.
    /// - Parameter destination: The target node.
    /// - Parameter condition: A closure that determines when to stop the search.
    /// - Returns: A dictionary where the keys are nodes and the values are arrays of paths.
    @inlinable public func allShortestPaths(
        from source: Node,
        to destination: Node,
        until condition: (Node) -> Bool
    ) -> [Path<Node, Edge>] where Node: Hashable, Edge.Weight: Numeric, Edge.Weight == Edge.Weight.Magnitude {
        allShortestPaths(from: source, to: destination, until: condition, using: DijkstraAlgorithm().backtracking())
    }
}

extension DijkstraAlgorithm {
    /// Creates a Dijkstra algorithm instance.
    /// - Returns: An instance of `DijkstraAlgorithm`.
    @inlinable public func backtracking() -> BacktrackingDijkstraAllShortestPathsAlgorithm<Node, Edge> {
        .init(dijkstraAlgorithm: self)
    }
}

/// A protocol defining the requirements for an algorithm that computes all shortest paths.
public protocol AllShortestPathsAlgorithm<Node, Edge> {
    /// The type of the nodes in the graph.
    associatedtype Node
    /// The type of the edges in the graph.
    associatedtype Edge

    /// Computes all shortest paths from the source node to the destination node in the graph.
    /// - Parameter source: The starting node.
    /// - Parameter destination: The target node.
    /// - Parameter condition: A closure that determines when to stop the search.
    /// - Parameter graph: The graph in which to compute the shortest paths.
    /// - Returns: An array of all shortest paths
    func allShortestPaths(
        from source: Node,
        to destination: Node,
        until condition: (Node) -> Bool,
        in graph: some GraphComponent<Node, Edge>
    ) -> [Path<Node, Edge>]
}

/// An algorithm that computes all shortest paths using Dijkstra's algorithm with backtracking.
public struct BacktrackingDijkstraAllShortestPathsAlgorithm<Node: Hashable, Edge: Weighted>: AllShortestPathsAlgorithm
where Edge.Weight: Numeric, Edge.Weight == Edge.Weight.Magnitude {
    /// The Dijkstra algorithm instance.
    public let dijkstraAlgorithm: DijkstraAlgorithm<Node, Edge>

    /// Creates a backtracking Dijkstra algorithm instance.
    /// - Parameter dijkstraAlgorithm: The Dijkstra algorithm instance.
    @inlinable public init(dijkstraAlgorithm: DijkstraAlgorithm<Node, Edge>) {
        self.dijkstraAlgorithm = dijkstraAlgorithm
    }

    /// Computes all shortest paths from the source node to the destination node in the graph.
    /// - Parameter source: The starting node.
    /// - Parameter destination: The target node.
    /// - Parameter condition: A closure that determines when to stop the search.
    /// - Parameter graph: The graph in which to compute the shortest paths.
    /// - Returns: An array of all shortest paths
    @inlinable public func allShortestPaths(
        from source: Node,
        to destination: Node,
        until condition: (Node) -> Bool,
        in graph: some GraphComponent<Node, Edge>
    ) -> [Path<Node, Edge>] {
        guard let shortestPath = dijkstraAlgorithm.shortestPath(from: source, to: destination, satisfying: condition, in: graph) else {
            return []
        }
        
        let (foundDestination, costs, predecessors) = computeAllShortestPredecessors(from: source, condition: condition, in: graph)
        
        guard let foundDestination,
              let destinationCost = costs[foundDestination],
              destinationCost == shortestPath.cost else {
            return []
        }
        
        var stack: [[Node]] = [[foundDestination]]
        var result: [Path<Node, Edge>] = []
        
        while let currentPath = stack.popLast(), let currentNode = currentPath.first {
            if currentNode == source {
                let reversedNodes = currentPath.reversed()
                let edges = zip(reversedNodes, reversedNodes.dropFirst()).compactMap { u, v in
                    predecessors[u]?.first { $0.source == v }
                }
                result.append(Path(source: source, destination: foundDestination, edges: Array(edges)))
            } else {
                guard let incEdges = predecessors[currentNode], let nodeCost = costs[currentNode] else { continue }
                
                for edge in incEdges {
                    guard let sourceCost = costs[edge.source], sourceCost + edge.value.weight == nodeCost else {
                        continue
                    }
                    var newPath = currentPath
                    newPath.insert(edge.source, at: 0)
                    stack.append(newPath)
                }
            }
        }
        
        return result
    }

    /// The state of the Dijkstra algorithm.
    @usableFromInline typealias State = DijkstraAlgorithm<Node, Edge>.State

    /// Run Dijkstra and store all shortest predecessors. You only call `edges(from:)` as needed.
    @inlinable func computeAllShortestPredecessors(
        from source: Node,
        condition: (Node) -> Bool,
        in graph: some GraphComponent<Node, Edge>
    ) -> (destination: Node?, costs: [Node: Edge.Weight], predecessors: [Node: [GraphEdge<Node, Edge>]]) {
        var openSet = Heap<State>()
        openSet.insert(State(node: source, totalCost: .zero))
        var costs: [Node: Edge.Weight] = [source: .zero]
        var predecessors: [Node: [GraphEdge<Node, Edge>]] = [:]
        var closedSet: Set<Node> = []

        var destination: Node?
        while let currentState = openSet.popMin() {
            let currentNode = currentState.node

            if condition(currentNode) {
                destination = currentNode
                break
            }

            if !closedSet.insert(currentNode).inserted {
                continue
            }

            // Explore neighbors using edges(from:)
            for edge in graph.edges(from: currentNode) {
                let neighbor = edge.destination
                let newCost = currentState.totalCost + edge.value.weight

                if let oldCost = costs[neighbor] {
                    if newCost < oldCost {
                        // Found a strictly better path, reset predecessors
                        costs[neighbor] = newCost
                        predecessors[neighbor] = [edge]
                        openSet.insert(State(node: neighbor, totalCost: newCost))
                    } else if newCost == oldCost {
                        // Found another equally minimal path, append this predecessor
                        predecessors[neighbor]?.append(edge)
                    }
                    // If newCost > oldCost, ignore it (not a shortest path)
                } else {
                    // First time reaching this node
                    costs[neighbor] = newCost
                    predecessors[neighbor] = [edge]
                    openSet.insert(State(node: neighbor, totalCost: newCost))
                }
            }
        }

        return (destination, costs, predecessors)
    }
}
