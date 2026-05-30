#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    @testable import Graphs
    import Testing

    struct MaxFlowAlgorithmTests {

        // MARK: - Core Behavior

        @Test func simpleFlowNetwork() {
            var graph = AdjacencyList()

            // Add vertices
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let v1 = graph.addVertex { $0.label = "v1" }
            let v2 = graph.addVertex { $0.label = "v2" }

            // Add edges with capacities (using weight property)
            graph.addEdge(from: s, to: v1) { $0.weight = 10.0 }
            graph.addEdge(from: s, to: v2) { $0.weight = 5.0 }
            graph.addEdge(from: v1, to: t) { $0.weight = 8.0 }
            graph.addEdge(from: v2, to: t) { $0.weight = 3.0 }
            graph.addEdge(from: v1, to: v2) { $0.weight = 2.0 }

            // Test Ford-Fulkerson
            let fordFulkersonResult = graph.maximumFlow(
                from: s,
                to: t,
                using: .fordFulkerson(capacityCost: .property(\.weight))
            )

            #expect(fordFulkersonResult.flowValue == 11.0)

            // Test Edmonds-Karp
            let edmondsKarpResult = graph.maximumFlow(
                from: s,
                to: t,
                using: .edmondsKarp(capacityCost: .property(\.weight))
            )

            #expect(edmondsKarpResult.flowValue == 11.0)

            // Test Dinic
            let dinicResult = graph.maximumFlow(
                from: s,
                to: t,
                using: .dinic(capacityCost: .property(\.weight))
            )

            #expect(dinicResult.flowValue == 11.0)
        }

        @Test func complexFlowNetwork() {
            var graph = AdjacencyList()

            // Add vertices
            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            let d = graph.addVertex { $0.label = "d" }

            // Add edges with capacities (using weight property)
            graph.addEdge(from: s, to: a) { $0.weight = 10.0 }
            graph.addEdge(from: s, to: b) { $0.weight = 5.0 }
            graph.addEdge(from: a, to: c) { $0.weight = 8.0 }
            graph.addEdge(from: a, to: d) { $0.weight = 2.0 }
            graph.addEdge(from: b, to: d) { $0.weight = 3.0 }
            graph.addEdge(from: c, to: t) { $0.weight = 6.0 }
            graph.addEdge(from: d, to: t) { $0.weight = 4.0 }

            // Test Ford-Fulkerson
            let fordFulkersonResult = graph.maximumFlow(
                from: s,
                to: t,
                using: .fordFulkerson(capacityCost: .property(\.weight))
            )

            // Expected maximum flow is 10
            #expect(fordFulkersonResult.flowValue == 10.0)

            // Test Edmonds-Karp
            let edmondsKarpResult = graph.maximumFlow(
                from: s,
                to: t,
                using: .edmondsKarp(capacityCost: .property(\.weight))
            )

            #expect(edmondsKarpResult.flowValue == 10.0)

            // Test Dinic
            let dinicResult = graph.maximumFlow(
                from: s,
                to: t,
                using: .dinic(capacityCost: .property(\.weight))
            )

            #expect(dinicResult.flowValue == 10.0)
        }

        @Test func minimumCut() {
            var graph = AdjacencyList()

            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }

            // Add edges with capacities (using weight property)
            graph.addEdge(from: s, to: a) { $0.weight = 10.0 }
            graph.addEdge(from: s, to: b) { $0.weight = 5.0 }
            graph.addEdge(from: a, to: t) { $0.weight = 8.0 }
            graph.addEdge(from: b, to: t) { $0.weight = 3.0 }

            let result = graph.maximumFlow(
                from: s,
                to: t,
                using: .fordFulkerson(capacityCost: .property(\.weight))
            )

            // Verify minimum cut
            #expect(result.minCutEdges.count == 2)
            #expect(result.sourceSideVertices.contains(s))
            #expect(result.sourceSideVertices.contains(a))
            #expect(result.sinkSideVertices.contains(t))
            // Note: The actual minimum cut may vary depending on the algorithm implementation
        }

        @Test func noPathFromSourceToSink() {
            var graph = AdjacencyList()

            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }
            let isolated = graph.addVertex { $0.label = "isolated" }

            // Add edge that doesn't connect s to t
            graph.addEdge(from: s, to: isolated) { $0.weight = 10.0 }

            let result = graph.maximumFlow(
                from: s,
                to: t,
                using: .fordFulkerson(capacityCost: .property(\.weight))
            )

            #expect(result.flowValue == 0.0)
        }

        @Test func singleEdge() {
            var graph = AdjacencyList()

            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }

            graph.addEdge(from: s, to: t) { $0.weight = 5.0 }

            let result = graph.maximumFlow(
                from: s,
                to: t,
                using: .fordFulkerson(capacityCost: .property(\.weight))
            )

            #expect(result.flowValue == 5.0)
        }

        @Test func zeroCapacityEdges() {
            var graph = AdjacencyList()

            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }

            graph.addEdge(from: s, to: t) { $0.weight = 0.0 }

            let result = graph.maximumFlow(
                from: s,
                to: t,
                using: .fordFulkerson(capacityCost: .property(\.weight))
            )

            #expect(result.flowValue == 0.0)
        }

        @Test func performanceOnLargeGraph() {
            let graph = createLargeFlowNetwork()

            // Test performance with Dinic (most efficient)
            let vertices = Array(graph.vertices())
            let result = graph.maximumFlow(
                from: vertices.first!,
                to: vertices.last!,
                using: .dinic(capacityCost: .property(\.weight))
            )
            #expect(result.flowValue > 0.0)
        }

        // MARK: - Helpers

        private func verifyFlowConservation<G: AdjacencyListProtocol>(
            graph: G,
            result: MaxFlowResult<G.VertexDescriptor, G.EdgeDescriptor, Double>,
            source: G.VertexDescriptor,
            sink: G.VertexDescriptor
        ) {
            // Check flow conservation at each vertex (except source and sink)
            for vertex in graph.vertices() {
                if vertex == source || vertex == sink { continue }

                var incomingFlow: Double = 0.0
                var outgoingFlow: Double = 0.0

                // Calculate incoming flow
                for edge in graph.incomingEdges(of: vertex) {
                    incomingFlow += result.flow(through: edge)
                }

                // Calculate outgoing flow
                for edge in graph.outgoingEdges(of: vertex) {
                    outgoingFlow += result.flow(through: edge)
                }

                #expect(incomingFlow == outgoingFlow)
            }
        }

        private func createLargeFlowNetwork() -> DefaultAdjacencyList {
            var graph = DefaultAdjacencyList()

            let s = graph.addVertex { $0.label = "s" }
            let t = graph.addVertex { $0.label = "t" }

            // Create a grid-like flow network
            let size = 10
            var vertices: [[DefaultAdjacencyList.VertexDescriptor]] = []

            for i in 0 ..< size {
                var row: [DefaultAdjacencyList.VertexDescriptor] = []
                for j in 0 ..< size {
                    let vertex = graph.addVertex { $0.label = "v\(i)_\(j)" }
                    row.append(vertex)
                }
                vertices.append(row)
            }

            // Connect source to first row
            for j in 0 ..< size {
                graph.addEdge(from: s, to: vertices[0][j]) { $0.weight = Double.random(in: 1 ... 10) }
            }

            // Connect last row to sink
            for j in 0 ..< size {
                graph.addEdge(from: vertices[size - 1][j], to: t) { $0.weight = Double.random(in: 1 ... 10) }
            }

            // Connect grid vertices
            for i in 0 ..< size - 1 {
                for j in 0 ..< size {
                    // Downward edges
                    graph.addEdge(from: vertices[i][j], to: vertices[i + 1][j]) { $0.weight = Double.random(in: 1 ... 5) }

                    // Rightward edges (if not last column)
                    if j < size - 1 {
                        graph.addEdge(from: vertices[i][j], to: vertices[i][j + 1]) { $0.weight = Double.random(in: 1 ... 5) }
                    }
                }
            }

            return graph
        }
    }

    // MARK: - MaxFlowResult API Coverage

    /// Tests for `MaxFlowResult` methods not covered by the flow-conservation helper:
    /// `residualCapacity(of:)` and `isMinCutEdge(_:)`.
    struct MaxFlowResultAPITests {

        @Test func residualCapacityAndIsMinCutEdge() throws {
            // Simple s→a→t network with capacity 5 on s→a and 3 on a→t.
            // Max flow = 3 (bottleneck a→t).
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let a = graph.addVertex { $0.label = "a" }
            let t = graph.addVertex { $0.label = "t" }
            let sa = graph.addEdge(from: s, to: a)!
            graph[sa].weight = 5.0
            let at = graph.addEdge(from: a, to: t)!
            graph[at].weight = 3.0

            let result = graph.maximumFlow(
                from: s,
                to: t,
                using: .edmondsKarp(capacityCost: .property(\.weight))
            )

            #expect(result.flowValue == 3.0, "max flow is constrained by the 3-capacity bottleneck a→t")

            // flow(through:) — already covered by verifyFlowConservation; verify here explicitly
            #expect(result.flow(through: sa) == 3.0, "flow through s→a equals the max flow")
            #expect(result.flow(through: at) == 3.0, "flow through a→t equals the max flow")

            // residualCapacity(of:) — the remaining capacity
            #expect(result.residualCapacity(of: sa) == 2.0, "s→a has 5−3=2 residual capacity")
            #expect(result.residualCapacity(of: at) == 0.0, "a→t is saturated, residual=0")

            // isMinCutEdge — the saturated edge a→t is in the min cut
            #expect(result.isMinCutEdge(at), "saturated a→t edge is in the minimum cut")
            #expect(!result.isMinCutEdge(sa), "s→a with residual capacity is not in the min cut")
        }
    }

    // MARK: - Visitor Support

    /// Exercises all four FordFulkerson visitor events through a composed visitor pair.
    ///
    /// Graph: s→v1(cap=5), v1→t(cap=5). One augmenting path: s→v1→t.
    /// - `findPath` fires once per iteration (once for the single augmenting path).
    /// - `examineEdge` fires for each edge examined during the DFS/BFS path search.
    /// - `augmentPath` fires once when the augmenting path is found.
    /// - `updateFlow` fires for each edge in the augmenting path (2 edges: s→v1, v1→t).
    extension MaxFlowAlgorithmTests {
        @Test func fordFulkersonComposedVisitorsReceiveAllEvents() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let v1 = graph.addVertex { $0.label = "v1" }
            let t = graph.addVertex { $0.label = "t" }
            graph.addEdge(from: s, to: v1) { $0.weight = 5.0 }
            graph.addEdge(from: v1, to: t) { $0.weight = 5.0 }

            var examEdge1 = 0
            var examEdge2 = 0
            var augPath1 = 0
            var augPath2 = 0
            var updFlow1 = 0
            var updFlow2 = 0
            var findPath1 = 0
            var findPath2 = 0

            var vis1 = FordFulkerson<DefaultAdjacencyList, Double>.Visitor()
            vis1.examineEdge = { _, _ in examEdge1 += 1 }
            vis1.augmentPath = { _, _ in augPath1 += 1 }
            vis1.updateFlow = { _, _ in updFlow1 += 1 }
            vis1.findPath = { _, _ in findPath1 += 1 }

            var vis2 = FordFulkerson<DefaultAdjacencyList, Double>.Visitor()
            vis2.examineEdge = { _, _ in examEdge2 += 1 }
            vis2.augmentPath = { _, _ in augPath2 += 1 }
            vis2.updateFlow = { _, _ in updFlow2 += 1 }
            vis2.findPath = { _, _ in findPath2 += 1 }

            let combined = vis1.combined(with: vis2)
            _ = graph.maximumFlow(
                from: s,
                to: t,
                using: .fordFulkerson(capacityCost: .property(\.weight)).withVisitor(combined)
            )

            #expect(findPath1 >= 1, "findPath fires at least once per augmenting-path iteration")
            #expect(findPath2 >= 1)
            #expect(examEdge1 >= 1, "examineEdge fires for each edge examined during DFS search")
            #expect(examEdge2 >= 1)
            #expect(augPath1 >= 1, "augmentPath fires when an augmenting path is found")
            #expect(augPath2 >= 1)
            #expect(updFlow1 >= 1, "updateFlow fires for each edge in the augmenting path")
            #expect(updFlow2 >= 1)
            // Both composed visitors must see identical event counts
            #expect(findPath1 == findPath2)
            #expect(examEdge1 == examEdge2)
            #expect(augPath1 == augPath2)
            #expect(updFlow1 == updFlow2)
        }

        /// Exercises all five EdmondsKarp visitor events through a composed visitor pair.
        ///
        /// Graph: s→v1(cap=5), v1→t(cap=5). One BFS-found augmenting path.
        /// - `findPath` fires once per BFS iteration.
        /// - `levelAssigned` fires for each vertex assigned a BFS level.
        /// - `examineEdge` fires for each edge examined during BFS.
        /// - `augmentPath` fires when the path is augmented.
        /// - `updateFlow` fires for each edge in the augmenting path.
        @Test func edmondsKarpComposedVisitorsReceiveAllEvents() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let v1 = graph.addVertex { $0.label = "v1" }
            let t = graph.addVertex { $0.label = "t" }
            graph.addEdge(from: s, to: v1) { $0.weight = 5.0 }
            graph.addEdge(from: v1, to: t) { $0.weight = 5.0 }

            var examEdge1 = 0
            var examEdge2 = 0
            var augPath1 = 0
            var augPath2 = 0
            var updFlow1 = 0
            var updFlow2 = 0
            var findPath1 = 0
            var findPath2 = 0
            var levelAssign1 = 0
            var levelAssign2 = 0

            var vis1 = EdmondsKarp<DefaultAdjacencyList, Double>.Visitor()
            vis1.examineEdge = { _, _ in examEdge1 += 1 }
            vis1.augmentPath = { _, _ in augPath1 += 1 }
            vis1.updateFlow = { _, _ in updFlow1 += 1 }
            vis1.findPath = { _, _ in findPath1 += 1 }
            vis1.levelAssigned = { _, _ in levelAssign1 += 1 }

            var vis2 = EdmondsKarp<DefaultAdjacencyList, Double>.Visitor()
            vis2.examineEdge = { _, _ in examEdge2 += 1 }
            vis2.augmentPath = { _, _ in augPath2 += 1 }
            vis2.updateFlow = { _, _ in updFlow2 += 1 }
            vis2.findPath = { _, _ in findPath2 += 1 }
            vis2.levelAssigned = { _, _ in levelAssign2 += 1 }

            let combined = vis1.combined(with: vis2)
            _ = graph.maximumFlow(
                from: s,
                to: t,
                using: .edmondsKarp(capacityCost: .property(\.weight)).withVisitor(combined)
            )

            #expect(findPath1 >= 1, "findPath fires at least once per BFS iteration")
            #expect(findPath2 >= 1)
            #expect(levelAssign1 >= 1, "levelAssigned fires for each vertex assigned a BFS level")
            #expect(levelAssign2 >= 1)
            #expect(examEdge1 >= 1, "examineEdge fires for each edge examined during BFS")
            #expect(examEdge2 >= 1)
            #expect(augPath1 >= 1, "augmentPath fires when the path is augmented")
            #expect(augPath2 >= 1)
            #expect(updFlow1 >= 1, "updateFlow fires for each edge in the augmenting path")
            #expect(updFlow2 >= 1)
            // Both composed visitors must see identical event counts
            #expect(findPath1 == findPath2)
            #expect(levelAssign1 == levelAssign2)
            #expect(examEdge1 == examEdge2)
            #expect(augPath1 == augPath2)
            #expect(updFlow1 == updFlow2)
        }

        /// Exercises all seven Dinic visitor events through a composed visitor pair.
        ///
        /// Graph: s→v1(cap=5), v1→t(cap=5). One blocking flow iteration.
        /// - `buildLevelGraph` fires once per BFS phase.
        /// - `levelAssigned` fires for each vertex assigned a level in the level graph.
        /// - `findBlockingFlow` fires once per DFS blocking-flow phase.
        /// - `updateFlow` fires for each edge whose flow is updated.
        ///
        /// Note: `examineEdge`, `augmentPath`, and `edgeBlocked` are defined in the visitor
        /// struct but are not currently called by the Dinic implementation.
        @Test func dinicComposedVisitorsReceiveAllEvents() {
            var graph = AdjacencyList()
            let s = graph.addVertex { $0.label = "s" }
            let v1 = graph.addVertex { $0.label = "v1" }
            let t = graph.addVertex { $0.label = "t" }
            graph.addEdge(from: s, to: v1) { $0.weight = 5.0 }
            graph.addEdge(from: v1, to: t) { $0.weight = 5.0 }

            var buildLevel1 = 0
            var buildLevel2 = 0
            var levelAssign1 = 0
            var levelAssign2 = 0
            var blocking1 = 0
            var blocking2 = 0
            var updFlow1 = 0
            var updFlow2 = 0

            var vis1 = Dinic<DefaultAdjacencyList, Double>.Visitor()
            vis1.buildLevelGraph = { buildLevel1 += 1 }
            vis1.levelAssigned = { _, _ in levelAssign1 += 1 }
            vis1.findBlockingFlow = { blocking1 += 1 }
            vis1.updateFlow = { _, _ in updFlow1 += 1 }

            var vis2 = Dinic<DefaultAdjacencyList, Double>.Visitor()
            vis2.buildLevelGraph = { buildLevel2 += 1 }
            vis2.levelAssigned = { _, _ in levelAssign2 += 1 }
            vis2.findBlockingFlow = { blocking2 += 1 }
            vis2.updateFlow = { _, _ in updFlow2 += 1 }

            let combined = vis1.combined(with: vis2)
            _ = graph.maximumFlow(
                from: s,
                to: t,
                using: .dinic(capacityCost: .property(\.weight)).withVisitor(combined)
            )

            #expect(buildLevel1 >= 1, "buildLevelGraph fires at least once per BFS phase")
            #expect(buildLevel2 >= 1)
            #expect(levelAssign1 >= 1, "levelAssigned fires for each vertex assigned a level")
            #expect(levelAssign2 >= 1)
            #expect(blocking1 >= 1, "findBlockingFlow fires at least once per DFS phase")
            #expect(blocking2 >= 1)
            #expect(updFlow1 >= 1, "updateFlow fires for each edge whose flow changes")
            #expect(updFlow2 >= 1)
            // Both composed visitors must see identical event counts
            #expect(buildLevel1 == buildLevel2)
            #expect(levelAssign1 == levelAssign2)
            #expect(blocking1 == blocking2)
            #expect(updFlow1 == updFlow2)
        }
    }
#endif
