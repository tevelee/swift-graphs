#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    import Collections
    import DequeModule

    /// Successive Shortest Paths algorithm for computing minimum cost flow.
    ///
    /// The algorithm repeatedly finds the minimum cost augmenting path from source to sink
    /// in the residual graph using SPFA (Shortest Path Faster Algorithm / Bellman-Ford with
    /// a queue), then augments as much flow as possible along that path. Because it always
    /// chooses the cheapest available path, the result is optimal.
    ///
    /// An internal residual graph is maintained with forward edges (from the original graph)
    /// and backward edges (at negated cost) so the algorithm can reroute previously committed
    /// flow to find a globally cheaper solution.
    ///
    /// - Complexity: O(V · E · F) where V is vertex count, E edge count, and F total flow.
    ///   Each SPFA call is O(V · E); the number of augmentations is at most F for integer flows.
    ///
    /// - Note: Assumes no negative-cost cycles in the original graph. Negative cost edges are
    ///   supported, but negative cycles would cause SPFA to loop indefinitely.
    public struct SuccessiveShortestPaths<
        Graph: IncidenceGraph & EdgeListGraph & VertexListGraph,
        Value: AdditiveArithmetic & Comparable & SignedNumeric
    >
    where
        Graph.VertexDescriptor: Hashable,
        Graph.EdgeDescriptor: Hashable
    {
        /// The vertex type of the graph.
        public typealias Vertex = Graph.VertexDescriptor
        /// The edge type of the graph.
        public typealias Edge = Graph.EdgeDescriptor

        /// A visitor that observes Successive Shortest Paths algorithm progress.
        public struct Visitor {
            /// Called at the start of each minimum-cost augmenting path search.
            public var findPath: ((Vertex, Vertex) -> Void)?
            /// Called when a path is found and flow is about to be augmented.
            ///
            /// The first argument lists the original edges along the path; entries are `nil`
            /// for backward (residual) edges that have no counterpart in the original graph.
            public var augmentPath: (([Edge?], Value) -> Void)?
            /// Called each time the flow on an original edge changes.
            public var updateFlow: ((Edge, Value) -> Void)?
            /// Called after each augmentation with the cumulative totals.
            public var iterationCompleted: ((Value, Value) -> Void)?

            /// Creates a new visitor with optional event handlers.
            @inlinable
            public init(
                findPath: ((Vertex, Vertex) -> Void)? = nil,
                augmentPath: (([Edge?], Value) -> Void)? = nil,
                updateFlow: ((Edge, Value) -> Void)? = nil,
                iterationCompleted: ((Value, Value) -> Void)? = nil
            ) {
                self.findPath = findPath
                self.augmentPath = augmentPath
                self.updateFlow = updateFlow
                self.iterationCompleted = iterationCompleted
            }
        }

        /// A definition of how to extract each edge's capacity.
        @usableFromInline
        let capacityCost: CostDefinition<Graph, Value>

        /// A definition of how to extract each edge's per-unit-flow cost.
        @usableFromInline
        let unitCost: CostDefinition<Graph, Value>

        /// Creates a new Successive Shortest Paths algorithm.
        ///
        /// - Parameters:
        ///   - capacity: A definition of how to extract each edge's capacity.
        ///   - unitCost: A definition of how to extract each edge's per-unit-flow cost.
        @inlinable
        public init(capacity: CostDefinition<Graph, Value>, unitCost: CostDefinition<Graph, Value>) {
            self.capacityCost = capacity
            self.unitCost = unitCost
        }

        // MARK: - Internal residual graph

        @usableFromInline
        struct ResidualEdge {
            @usableFromInline var residualCapacity: Value
            @usableFromInline let cost: Value
            @usableFromInline let to: Vertex
            /// Index of the paired reverse edge in the residual edge array.
            @usableFromInline let reverseIndex: Int
            /// The original graph edge, or `nil` for backward (residual) edges.
            @usableFromInline let originalEdge: Edge?

            @usableFromInline
            init(to: Vertex, residualCapacity: Value, cost: Value, reverseIndex: Int, originalEdge: Edge?) {
                self.to = to
                self.residualCapacity = residualCapacity
                self.cost = cost
                self.reverseIndex = reverseIndex
                self.originalEdge = originalEdge
            }
        }

        // MARK: - Main entry point

        /// Computes the minimum cost flow using Successive Shortest Paths.
        ///
        /// - Parameters:
        ///   - source: The source vertex.
        ///   - sink: The sink vertex.
        ///   - demand: The required flow amount, or `nil` for minimum cost maximum flow.
        ///   - graph: The flow network graph.
        ///   - visitor: An optional visitor to observe algorithm progress.
        /// - Returns: The minimum cost flow result.
        @inlinable
        public func minimumCostFlow(
            from source: Vertex,
            to sink: Vertex,
            demand: Value?,
            in graph: Graph,
            visitor: Visitor?
        ) -> MinCostFlowResult<Vertex, Edge, Value> {
            guard source != sink else {
                let feasible = demand.map { $0 <= .zero } ?? true
                return MinCostFlowResult(flowValue: .zero, totalCost: .zero, edgeFlows: [:], isFeasible: feasible)
            }

            // Build residual graph: each original edge becomes a forward + backward edge pair.
            // Forward edge index 2i, backward edge index 2i+1 (reverseIndex toggles via XOR or stored).
            var residualEdges: [ResidualEdge] = []
            var adjacency: [Vertex: [Int]] = [:]
            var edgeFlows: [Edge: Value] = [:]

            for edge in graph.edges() {
                guard let src = graph.source(of: edge),
                    let dst = graph.destination(of: edge)
                else { continue }

                let cap = capacityCost.costToExplore(edge, graph)
                let cost = unitCost.costToExplore(edge, graph)

                let forwardIdx = residualEdges.count
                let backwardIdx = forwardIdx + 1

                residualEdges.append(ResidualEdge(to: dst, residualCapacity: cap, cost: cost, reverseIndex: backwardIdx, originalEdge: edge))
                // Backward edge has zero initial capacity and negated cost.
                residualEdges.append(ResidualEdge(to: src, residualCapacity: .zero, cost: .zero - cost, reverseIndex: forwardIdx, originalEdge: nil))

                adjacency[src, default: []].append(forwardIdx)
                adjacency[dst, default: []].append(backwardIdx)
                edgeFlows[edge] = .zero
            }

            for vertex in graph.vertices() {
                if adjacency[vertex] == nil { adjacency[vertex] = [] }
            }

            var totalFlow: Value = .zero
            var totalCost: Value = .zero

            while true {
                if let demand, totalFlow >= demand { break }

                visitor?.findPath?(source, sink)

                guard
                    let (parentEdge, pathCost) = spfa(
                        source: source,
                        sink: sink,
                        residualEdges: residualEdges,
                        adjacency: adjacency
                    )
                else { break }

                // Reconstruct path (residual edge indices, source→sink order).
                var pathIndices: [Int] = []
                var v = sink
                while v != source {
                    guard let edgeIdx = parentEdge[v] else { break }
                    pathIndices.append(edgeIdx)
                    // Source of this edge = reverse edge's destination.
                    v = residualEdges[residualEdges[edgeIdx].reverseIndex].to
                }
                pathIndices.reverse()
                guard !pathIndices.isEmpty else { break }

                // Find bottleneck capacity along the path.
                var bottleneck = residualEdges[pathIndices[0]].residualCapacity
                for edgeIdx in pathIndices.dropFirst() {
                    let cap = residualEdges[edgeIdx].residualCapacity
                    if cap < bottleneck { bottleneck = cap }
                }
                guard bottleneck > .zero else { break }

                // Clamp to remaining demand if one was specified.
                let flowToSend: Value
                if let demand {
                    let remaining = demand - totalFlow
                    flowToSend = bottleneck < remaining ? bottleneck : remaining
                } else {
                    flowToSend = bottleneck
                }

                visitor?.augmentPath?(pathIndices.map { residualEdges[$0].originalEdge }, flowToSend)

                // Augment: update residual capacities and track original-edge flows.
                for edgeIdx in pathIndices {
                    residualEdges[edgeIdx].residualCapacity -= flowToSend
                    residualEdges[residualEdges[edgeIdx].reverseIndex].residualCapacity += flowToSend

                    if let original = residualEdges[edgeIdx].originalEdge {
                        edgeFlows[original] = (edgeFlows[original] ?? .zero) + flowToSend
                        visitor?.updateFlow?(original, edgeFlows[original]!)
                    } else {
                        // Backward edge: the paired forward edge's original edge loses flow.
                        let fwdIdx = residualEdges[edgeIdx].reverseIndex
                        if let original = residualEdges[fwdIdx].originalEdge {
                            edgeFlows[original] = (edgeFlows[original] ?? .zero) - flowToSend
                            visitor?.updateFlow?(original, edgeFlows[original]!)
                        }
                    }
                }

                totalFlow += flowToSend
                // pathCost is the per-unit cost of this augmenting path.
                totalCost += flowToSend * pathCost
                visitor?.iterationCompleted?(totalFlow, totalCost)
            }

            let isFeasible = demand.map { totalFlow >= $0 } ?? true

            return MinCostFlowResult(
                flowValue: totalFlow,
                totalCost: totalCost,
                edgeFlows: edgeFlows,
                isFeasible: isFeasible
            )
        }

        // MARK: - SPFA

        /// Finds the minimum cost path from source to sink in the residual graph.
        ///
        /// Uses SPFA (Bellman-Ford with a queue) to handle negative-cost backward edges.
        /// Returns the parent-edge map and the sink's minimum cost distance, or `nil` if
        /// the sink is unreachable.
        @usableFromInline
        func spfa(
            source: Vertex,
            sink: Vertex,
            residualEdges: [ResidualEdge],
            adjacency: [Vertex: [Int]]
        ) -> ([Vertex: Int], Value)? {
            var dist: [Vertex: Value] = [source: .zero]
            var inQueue: Set<Vertex> = [source]
            var parentEdge: [Vertex: Int] = [:]
            var queue: Deque<Vertex> = [source]

            while !queue.isEmpty {
                let u = queue.removeFirst()
                inQueue.remove(u)

                guard let du = dist[u] else { continue }

                for edgeIdx in adjacency[u, default: []] {
                    let edge = residualEdges[edgeIdx]
                    guard edge.residualCapacity > .zero else { continue }

                    let newDist = du + edge.cost
                    if dist[edge.to] == nil || newDist < dist[edge.to]! {
                        dist[edge.to] = newDist
                        parentEdge[edge.to] = edgeIdx
                        if !inQueue.contains(edge.to) {
                            inQueue.insert(edge.to)
                            queue.append(edge.to)
                        }
                    }
                }
            }

            guard let sinkDist = dist[sink] else { return nil }
            return (parentEdge, sinkDist)
        }
    }

    extension SuccessiveShortestPaths: VisitorSupporting {}
#endif
