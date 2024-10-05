import Collections

extension ShortestPathOnWholeGraphAlgorithm {
    /// Creates a bidirectional Dijkstra algorithm instance.
    /// - Returns: An instance of `BidirectionalDijkstraAlgorithm`.
    @inlinable public static func bidirectionalDijkstra<Node, Edge>() -> Self where Self == BidirectionalDijkstraAlgorithm<Node, Edge> {
        .init()
    }
}

public struct BidirectionalDijkstraAlgorithm<Node: Hashable, Edge: Weighted>: ShortestPathOnWholeGraphAlgorithm where Edge.Weight: FixedWidthInteger {
    @inlinable public init() {}

    @inlinable public func shortestPath(
        from source: Node,
        to destination: Node,
        in graph: some Graph<Node, Edge>
    ) -> Path<Node, Edge>? {
        // Initialize priority queues
        var forwardQueue = Heap<State>()
        var backwardQueue = Heap<State>()

        // Initialize distance maps
        var distForward: [Node: Edge.Weight] = [source: .zero]
        var distBackward: [Node: Edge.Weight] = [destination: .zero]

        // Initialize predecessor maps
        var prevForward: [Node: GraphEdge<Node, Edge>] = [:]
        var prevBackward: [Node: GraphEdge<Node, Edge>] = [:]

        // Build incoming edges map for backward search
        var incomingEdges: [Node: [GraphEdge<Node, Edge>]] = [:]
        for edge in graph.allEdges {
            incomingEdges[edge.destination, default: []].append(edge)
        }

        // Insert starting nodes into queues
        forwardQueue.insert(State(node: source, totalCost: .zero))
        backwardQueue.insert(State(node: destination, totalCost: .zero))

        var mu: Edge.Weight = .max
        var meetingNode: Node?

        while !forwardQueue.isEmpty || !backwardQueue.isEmpty {
            // Forward step
            if let currentForward = forwardQueue.popMin() {
                let u = currentForward.node

                // Termination condition for forward search
                if distForward[u]! > mu {
                    break
                }

                // Explore neighbors
                for edge in graph.edges(from: u) {
                    let v = edge.destination
                    let alt = distForward[u]! + edge.value.weight
                    if alt < (distForward[v] ?? .max) {
                        distForward[v] = alt
                        prevForward[v] = edge
                        forwardQueue.insert(State(node: v, totalCost: alt))
                        // Check if node was visited in backward search
                        if let distBwd = distBackward[v] {
                            let potentialMu = alt + distBwd
                            if potentialMu < mu {
                                mu = potentialMu
                                meetingNode = v
                            }
                        }
                    }
                }
            }

            // Backward step
            if let currentBackward = backwardQueue.popMin() {
                let u = currentBackward.node

                // Termination condition for backward search
                if distBackward[u]! > mu {
                    break
                }

                // Explore predecessors (incoming edges)
                for edge in incomingEdges[u] ?? [] {
                    let v = edge.source
                    let alt = distBackward[u]! + edge.value.weight
                    if alt < (distBackward[v] ?? .max) {
                        distBackward[v] = alt
                        prevBackward[v] = edge
                        backwardQueue.insert(State(node: v, totalCost: alt))
                        // Check if node was visited in forward search
                        if let distFwd = distForward[v] {
                            let potentialMu = alt + distFwd
                            if potentialMu < mu {
                                mu = potentialMu
                                meetingNode = v
                            }
                        }
                    }
                }
            }

            // Termination condition
            if let minForward = forwardQueue.min?.totalCost, let minBackward = backwardQueue.min?.totalCost {
                if minForward + minBackward >= mu {
                    break
                }
            } else if forwardQueue.isEmpty {
                if let minBackward = backwardQueue.min?.totalCost {
                    if minBackward >= mu {
                        break
                    }
                }
            } else if backwardQueue.isEmpty {
                if let minForward = forwardQueue.min?.totalCost {
                    if minForward >= mu {
                        break
                    }
                }
            } else {
                break
            }
        }

        guard let meeting = meetingNode else {
            // No path exists
            return nil
        }

        // Reconstruct path
        var pathEdges: [GraphEdge<Node, Edge>] = []

        // Forward path: from source to meeting node
        var node = meeting
        var forwardPathEdges: [GraphEdge<Node, Edge>] = []
        while node != source {
            guard let edge = prevForward[node] else {
                // No path exists from the meeting node to the source
                return nil
            }
            forwardPathEdges.append(edge)
            node = edge.source
        }
        forwardPathEdges.reverse()
        pathEdges.append(contentsOf: forwardPathEdges)

        // Backward path: from meeting node to destination
        node = meeting
        while node != destination {
            guard let edge = prevBackward[node] else {
                // No path exists from the meeting node to the destination
                return nil
            }
            pathEdges.append(edge)
            node = edge.destination
        }

        return Path(source: source, destination: destination, edges: pathEdges)
    }

    @usableFromInline struct State: Comparable {
        @usableFromInline let node: Node
        @usableFromInline let totalCost: Edge.Weight

        @inlinable init(node: Node, totalCost: Edge.Weight) {
            self.node = node
            self.totalCost = totalCost
        }

        @inlinable static func < (lhs: State, rhs: State) -> Bool {
            lhs.totalCost < rhs.totalCost
        }
    }
}
