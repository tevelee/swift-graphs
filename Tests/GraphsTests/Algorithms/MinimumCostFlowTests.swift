#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    @testable import Graphs
    import Testing

    struct MinimumCostFlowTests {

        // MARK: - Helpers

        typealias G = DefaultAdjacencyList

        /// Verifies flow conservation: at every non-source, non-sink vertex the sum of
        /// incoming flows equals the sum of outgoing flows.
        private func verifyFlowConservation(
            graph: G,
            result: MinCostFlowResult<G.VertexDescriptor, G.EdgeDescriptor, Double>,
            source: G.VertexDescriptor,
            sink: G.VertexDescriptor
        ) {
            for vertex in graph.vertices() where vertex != source && vertex != sink {
                let incoming = graph.incomingEdges(of: vertex)
                    .map { result.flow(through: $0) }
                    .reduce(0.0, +)
                let outgoing = graph.outgoingEdges(of: vertex)
                    .map { result.flow(through: $0) }
                    .reduce(0.0, +)
                #expect(abs(incoming - outgoing) < 1e-9, "Flow conservation violated at vertex \(vertex)")
            }
        }

        // MARK: - Basic correctness

        @Test func singleEdge() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            graph.addEdge(from: s, to: t) {
                $0.weight = 5.0
                $0.unitCost = 3.0
            }

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost)
            )

            #expect(result.flowValue == 5.0)
            #expect(result.totalCost == 15.0)
            #expect(result.isFeasible)
        }

        @Test func twoParallelPaths_choosesChéaper() {
            // s→a→t (cost 1+1=2 per unit, cap 3) vs s→b→t (cost 3+3=6 per unit, cap 3)
            // Min cost max flow should route as much as possible via the cheap path first.
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }

            graph.addEdge(from: s, to: a) {
                $0.weight = 3.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: a, to: t) {
                $0.weight = 3.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: s, to: b) {
                $0.weight = 3.0
                $0.unitCost = 3.0
            }
            graph.addEdge(from: b, to: t) {
                $0.weight = 3.0
                $0.unitCost = 3.0
            }

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost)
            )

            // Max flow = 6 (3 via each path). Min cost routes 3 via cheap, 3 via expensive.
            #expect(result.flowValue == 6.0)
            #expect(result.totalCost == 3.0 * 2.0 + 3.0 * 6.0)  // 6 + 18 = 24
            #expect(result.isFeasible)
            verifyFlowConservation(graph: graph, result: result, source: s, sink: t)
        }

        @Test func demandLessThanMaxFlow_stopsAtDemand() {
            // Same graph as above. Demand = 3 → should route along cheap path only.
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }

            graph.addEdge(from: s, to: a) {
                $0.weight = 3.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: a, to: t) {
                $0.weight = 3.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: s, to: b) {
                $0.weight = 3.0
                $0.unitCost = 3.0
            }
            graph.addEdge(from: b, to: t) {
                $0.weight = 3.0
                $0.unitCost = 3.0
            }

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost),
                demand: 3.0
            )

            #expect(result.flowValue == 3.0)
            #expect(result.totalCost == 6.0)  // 3 units × 2 cost per unit
            #expect(result.isFeasible)
            verifyFlowConservation(graph: graph, result: result, source: s, sink: t)
        }

        @Test func demandExceedsMaxFlow_infeasible() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            graph.addEdge(from: s, to: t) {
                $0.weight = 5.0
                $0.unitCost = 1.0
            }

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost),
                demand: 10.0
            )

            #expect(result.flowValue == 5.0)
            #expect(!result.isFeasible)
        }

        @Test func noPath_returnsZeroFlow() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let isolated = graph.addVertex { $0.label = "x" }
            graph.addEdge(from: s, to: isolated) {
                $0.weight = 5.0
                $0.unitCost = 1.0
            }

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost)
            )

            #expect(result.flowValue == 0.0)
            #expect(result.totalCost == 0.0)
            #expect(result.isFeasible)
        }

        @Test func zeroCapacityEdges_ignored() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            graph.addEdge(from: s, to: t) {
                $0.weight = 0.0
                $0.unitCost = 1.0
            }

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost)
            )

            #expect(result.flowValue == 0.0)
        }

        @Test func sourceEqualssSink_returnsZero() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            graph.addEdge(from: s, to: s) {
                $0.weight = 5.0
                $0.unitCost = 1.0
            }

            let result = graph.minimumCostFlow(
                from: s,
                to: s,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost)
            )

            #expect(result.flowValue == 0.0)
            #expect(result.totalCost == 0.0)
            #expect(result.isFeasible)
        }

        // MARK: - Known-optimal solutions

        @Test func classicTransportationNetwork() {
            // Classic textbook example with known optimal solution.
            //
            //       (cap=4, cost=2)
            //   s ─────────────────▶ a
            //   │                    │
            //   │ (cap=3, cost=3)    │ (cap=4, cost=1)
            //   ▼                    ▼
            //   b ─────────────────▶ t
            //       (cap=5, cost=2)
            //
            // Max flow = 7. To route 7 units at minimum cost:
            //   s→a→t: min(4,4) = 4 units × (2+1) = 12
            //   s→b→t: min(3,5) = 3 units × (3+2) = 15
            //   Total cost = 27
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }

            graph.addEdge(from: s, to: a) {
                $0.weight = 4.0
                $0.unitCost = 2.0
            }
            graph.addEdge(from: s, to: b) {
                $0.weight = 3.0
                $0.unitCost = 3.0
            }
            graph.addEdge(from: a, to: t) {
                $0.weight = 4.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: b, to: t) {
                $0.weight = 5.0
                $0.unitCost = 2.0
            }

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost)
            )

            #expect(result.flowValue == 7.0)
            #expect(result.totalCost == 27.0)
            #expect(result.isFeasible)
            verifyFlowConservation(graph: graph, result: result, source: s, sink: t)
        }

        @Test func diamondNetworkWithCrossEdge() {
            // Diamond + cross edge. Tests that the algorithm finds the globally optimal
            // routing rather than a greedy local choice.
            //
            //   s→a (cap=10, cost=1)    a→t (cap=5, cost=2)
            //   s→b (cap=10, cost=3)    b→t (cap=10, cost=1)
            //   a→b (cap=5, cost=0)   — free rerouting edge
            //
            // Optimal for max flow (15 units):
            //   5 via s→a→t (cost 3 each)         = 15
            //   5 via s→a→b→t (cost 1+0+1=2 each) = 10
            //   5 via s→b→t (cost 3+1=4 each)      = 20
            //   Total = 45
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }

            graph.addEdge(from: s, to: a) {
                $0.weight = 10.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: s, to: b) {
                $0.weight = 10.0
                $0.unitCost = 3.0
            }
            graph.addEdge(from: a, to: t) {
                $0.weight = 5.0
                $0.unitCost = 2.0
            }
            graph.addEdge(from: b, to: t) {
                $0.weight = 10.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: a, to: b) {
                $0.weight = 5.0
                $0.unitCost = 0.0
            }

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost)
            )

            #expect(result.flowValue == 15.0)
            #expect(result.totalCost == 45.0)
            #expect(result.isFeasible)
            verifyFlowConservation(graph: graph, result: result, source: s, sink: t)
        }

        @Test func optimalCostWithCapacityBottleneck() {
            // Verifies that SSP routes around bottlenecks optimally.
            //
            // Graph:  s→a (cap=2, cost=5)   a→t (cap=2, cost=1)  — path cost 6
            //         s→b (cap=2, cost=1)   b→t (cap=1, cost=10) — path cost 11, bottleneck 1
            //         a→b (cap=2, cost=0)   — free cross edge
            //
            // Unique feasible flow of value 3 (b→t cap=1 forces at most 1 unit via b→t):
            //   2 units via s→a→t (cost 2×6=12) + 1 unit via s→b→t (cost 1×11=11) = 23
            // (Sending >2 via s→a requires exceeding s→a cap=2; all other splits are infeasible.)
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }

            graph.addEdge(from: s, to: a) {
                $0.weight = 2.0
                $0.unitCost = 5.0
            }
            graph.addEdge(from: s, to: b) {
                $0.weight = 2.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: a, to: t) {
                $0.weight = 2.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: b, to: t) {
                $0.weight = 1.0
                $0.unitCost = 10.0
            }
            graph.addEdge(from: a, to: b) {
                $0.weight = 2.0
                $0.unitCost = 0.0
            }

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost),
                demand: 3.0
            )

            #expect(result.flowValue == 3.0)
            #expect(result.totalCost == 23.0)
            #expect(result.isFeasible)
            verifyFlowConservation(graph: graph, result: result, source: s, sink: t)
        }

        // MARK: - Result API

        @Test func flowThroughEdgeAPI() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let e = graph.addEdge(from: s, to: t)!
            graph[e].weight = 7.0
            graph[e].unitCost = 2.0

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost)
            )

            #expect(result.flow(through: e) == 7.0)
        }

        @Test func unusedEdgesHaveZeroFlow() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }

            // Cheap path s→a→t; expensive but unused path s→b→t
            graph.addEdge(from: s, to: a) {
                $0.weight = 3.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: a, to: t) {
                $0.weight = 3.0
                $0.unitCost = 1.0
            }
            let sb = graph.addEdge(from: s, to: b)!
            graph[sb].weight = 3.0
            graph[sb].unitCost = 100.0
            let bt = graph.addEdge(from: b, to: t)!
            graph[bt].weight = 3.0
            graph[bt].unitCost = 100.0

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                capacity: .property(\.weight),
                unitCost: .property(\.unitCost),
                demand: 3.0
            )

            #expect(result.flowValue == 3.0)
            // The expensive path should carry no flow.
            #expect(result.flow(through: sb) == 0.0)
            #expect(result.flow(through: bt) == 0.0)
        }

        // MARK: - Visitor pattern

        @Test func visitorReceivesAllEvents() {
            // s→a→t, one augmenting path, demand satisfied in one iteration.
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let a = graph.addVertex { $0.label = "a" }
            let t = graph.addVertex { $0.label = "t" }
            graph.addEdge(from: s, to: a) {
                $0.weight = 4.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: a, to: t) {
                $0.weight = 4.0
                $0.unitCost = 2.0
            }

            var findPathCount = 0
            var augmentPathCount = 0
            var updateFlowCount = 0
            var iterationCount = 0

            var visitor = SuccessiveShortestPaths<DefaultAdjacencyList, Double>.Visitor()
            visitor.findPath = { _, _ in findPathCount += 1 }
            visitor.augmentPath = { _, _ in augmentPathCount += 1 }
            visitor.updateFlow = { _, _ in updateFlowCount += 1 }
            visitor.iterationCompleted = { _, _ in iterationCount += 1 }

            _ = graph.minimumCostFlow(
                from: s,
                to: t,
                demand: nil,
                using: .successiveShortestPaths(
                    capacity: .property(\.weight),
                    unitCost: .property(\.unitCost)
                ).withVisitor(visitor)
            )

            #expect(findPathCount >= 1, "findPath fires at least once per iteration")
            #expect(augmentPathCount >= 1, "augmentPath fires when a path is found")
            #expect(updateFlowCount >= 1, "updateFlow fires for each edge whose flow changes")
            #expect(iterationCount >= 1, "iterationCompleted fires after each augmentation")
        }

        @Test func composedVisitorsBothReceiveEvents() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            graph.addEdge(from: s, to: t) {
                $0.weight = 5.0
                $0.unitCost = 2.0
            }

            var count1 = 0
            var count2 = 0

            var vis1 = SuccessiveShortestPaths<DefaultAdjacencyList, Double>.Visitor()
            vis1.iterationCompleted = { _, _ in count1 += 1 }

            var vis2 = SuccessiveShortestPaths<DefaultAdjacencyList, Double>.Visitor()
            vis2.iterationCompleted = { _, _ in count2 += 1 }

            _ = graph.minimumCostFlow(
                from: s,
                to: t,
                demand: nil,
                using: .successiveShortestPaths(
                    capacity: .property(\.weight),
                    unitCost: .property(\.unitCost)
                ).withVisitor(vis1.combined(with: vis2))
            )

            #expect(count1 >= 1)
            #expect(count2 >= 1)
            #expect(count1 == count2, "Both composed visitors must receive identical event counts")
        }

        @Test func iterationCompletedReportsRunningTotals() {
            // Two separate augmenting paths: s→a (cap=2, cost=1) and s→b (cap=3, cost=3)
            // both leading to t. SSP will augment in two iterations.
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }

            graph.addEdge(from: s, to: a) {
                $0.weight = 2.0
                $0.unitCost = 1.0
            }
            graph.addEdge(from: a, to: t) {
                $0.weight = 2.0
                $0.unitCost = 0.0
            }
            graph.addEdge(from: s, to: b) {
                $0.weight = 3.0
                $0.unitCost = 3.0
            }
            graph.addEdge(from: b, to: t) {
                $0.weight = 3.0
                $0.unitCost = 0.0
            }

            var snapshots: [(Double, Double)] = []
            var visitor = SuccessiveShortestPaths<DefaultAdjacencyList, Double>.Visitor()
            visitor.iterationCompleted = { flow, cost in snapshots.append((flow, cost)) }

            _ = graph.minimumCostFlow(
                from: s,
                to: t,
                demand: nil,
                using: .successiveShortestPaths(
                    capacity: .property(\.weight),
                    unitCost: .property(\.unitCost)
                ).withVisitor(visitor)
            )

            #expect(snapshots.count >= 2, "Two distinct augmenting paths → at least two iterations")
            // Flow and cost should be strictly increasing across iterations.
            for i in 1 ..< snapshots.count {
                #expect(snapshots[i].0 >= snapshots[i - 1].0, "Total flow must be non-decreasing")
            }
        }

        // MARK: - Using `.using:` overload explicitly

        @Test func usingAlgorithmOverload() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            graph.addEdge(from: s, to: t) {
                $0.weight = 3.0
                $0.unitCost = 4.0
            }

            let result = graph.minimumCostFlow(
                from: s,
                to: t,
                using: .successiveShortestPaths(
                    capacity: .property(\.weight),
                    unitCost: .property(\.unitCost)
                )
            )

            #expect(result.flowValue == 3.0)
            #expect(result.totalCost == 12.0)
        }
    }
#endif
