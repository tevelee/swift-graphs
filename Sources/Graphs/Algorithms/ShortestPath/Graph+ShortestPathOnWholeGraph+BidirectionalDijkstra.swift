import Collections

extension ShortestPathOnWholeGraphAlgorithm {
    /// Creates a bidirectional Dijkstra algorithm instance.
    /// - Returns: An instance of `BidirectionalDijkstraAlgorithm`.
    @inlinable public static func bidirectionalDijkstra<Node, Edge>() -> Self where Self == BidirectionalDijkstraAlgorithm<Node, Edge> {
        .init()
    }
}

public struct BidirectionalDijkstraAlgorithm<Node: Hashable, Edge: Weighted>: ShortestPathOnWholeGraphAlgorithm where Edge.Weight: Comparable & AdditiveArithmetic {
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

        // Initialize visited sets
        var visitedForward: Set<Node> = []
        var visitedBackward: Set<Node> = []

        // Insert starting nodes into queues
        forwardQueue.insert(State(node: source, totalCost: .zero))
        backwardQueue.insert(State(node: destination, totalCost: .zero))

        var mu: Edge.Weight?
        var meetingNode: Node?

        // Build incoming edges map for backward search
        var incomingEdges: [Node: [GraphEdge<Node, Edge>]] = [:]
        for edge in graph.allEdges {
            incomingEdges[edge.destination, default: []].append(edge)
        }

        while !forwardQueue.isEmpty && !backwardQueue.isEmpty {
            // Forward step
            if let currentForward = forwardQueue.popMin() {
                let u = currentForward.node
                if visitedForward.contains(u) {
                    continue
                }
                visitedForward.insert(u)

                // Check for meeting point
                if visitedBackward.contains(u) {
                    let totalCost = distForward[u]! + distBackward[u]!
                    if mu == nil || totalCost < mu! {
                        mu = totalCost
                        meetingNode = u
                    }
                }

                // Termination condition for forward search
                if let muValue = mu, distForward[u]! >= muValue {
                    continue
                }

                // Explore neighbors
                for edge in graph.edges(from: u) {
                    let v = edge.destination
                    let alt = distForward[u]! + edge.value.weight
                    if distForward[v] == nil || alt < distForward[v]! {
                        distForward[v] = alt
                        prevForward[v] = edge
                        forwardQueue.insert(State(node: v, totalCost: alt))
                    }
                }
            }

            // Backward step
            if let currentBackward = backwardQueue.popMin() {
                let u = currentBackward.node
                if visitedBackward.contains(u) {
                    continue
                }
                visitedBackward.insert(u)

                // Check for meeting point
                if visitedForward.contains(u) {
                    let totalCost = distForward[u]! + distBackward[u]!
                    if mu == nil || totalCost < mu! {
                        mu = totalCost
                        meetingNode = u
                    }
                }

                // Termination condition for backward search
                if let muValue = mu, distBackward[u]! >= muValue {
                    continue
                }

                // Explore predecessors (incoming edges)
                for edge in incomingEdges[u] ?? [] {
                    let v = edge.source
                    let alt = distBackward[u]! + edge.value.weight
                    if distBackward[v] == nil || alt < distBackward[v]! {
                        distBackward[v] = alt
                        prevBackward[u] = edge
                        backwardQueue.insert(State(node: v, totalCost: alt))
                    }
                }
            }

            // Overall termination condition
            if let muValue = mu,
               let minForward = forwardQueue.min?.totalCost,
               let minBackward = backwardQueue.min?.totalCost,
               minForward + minBackward >= muValue {
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
            if let edge = prevForward[node] {
                forwardPathEdges.append(edge)
                node = edge.source
            } else {
                // No path exists from the meeting node to the source
                return nil
            }
        }
        pathEdges.append(contentsOf: forwardPathEdges)

        // Backward path: from destination back to meeting node
        node = destination
        var backwardPathEdges: [GraphEdge<Node, Edge>] = []
        while node != meeting {
            if let edge = prevBackward[node] {
                backwardPathEdges.append(edge)
                node = edge.source
            } else {
                // No path exists from the destination to the meeting node
                return nil
            }
        }
        backwardPathEdges.reverse()
        pathEdges.append(contentsOf: backwardPathEdges)

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
            return lhs.totalCost < rhs.totalCost
        }
    }
}
