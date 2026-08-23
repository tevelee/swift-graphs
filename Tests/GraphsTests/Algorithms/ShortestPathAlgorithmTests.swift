#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    @testable import Graphs
    import Testing

    struct ShortestPathAlgorithmTests {

        func createLinearGraph() -> AdjacencyList {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = 3 }

            return graph
        }

        func createNegativeWeightGraph() -> AdjacencyList {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = -1 }

            return graph
        }

        func createDisconnectedGraph() -> AdjacencyList {
            var graph = AdjacencyList()

            graph.addVertex { $0.label = "A" }
            graph.addVertex { $0.label = "B" }
            // No edges between A and B

            return graph
        }

        func createSingleVertexGraph() -> AdjacencyList {
            var graph = AdjacencyList()

            graph.addVertex { $0.label = "A" }

            return graph
        }

        // MARK: - Core Behavior

        @Test func floydWarshallFindsAllPairs() {
            let graph = createLinearGraph()

            let a = graph.findVertex(labeled: "A")!
            let b = graph.findVertex(labeled: "B")!
            let c = graph.findVertex(labeled: "C")!

            let floydWarshall = FloydWarshall(on: graph, edgeWeight: .property(\.weight))
            let result = floydWarshall.shortestPathsForAllPairs()

            #expect(result.distance(from: a, to: c) == 5.0)  // A -> B -> C (2 + 3 = 5)
            #expect(result.distance(from: a, to: b) == 2.0)  // A -> B
            #expect(result.distance(from: a, to: a) == 0.0)  // Self-loop
        }

        @Test func dijkstraFindsAllPaths() {
            let graph = createLinearGraph()

            let a = graph.findVertex(labeled: "A")!
            let b = graph.findVertex(labeled: "B")!
            let c = graph.findVertex(labeled: "C")!

            let dijkstra = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight))
            let result = dijkstra.reduce(into: nil) { $0 = $1 }!

            // Extract distances from property map
            let distanceToC = result.propertyMap[c][result.distanceProperty]
            let distanceToB = result.propertyMap[b][result.distanceProperty]
            let distanceToA = result.propertyMap[a][result.distanceProperty]

            #expect(distanceToC == .finite(5.0))
            #expect(distanceToB == .finite(2.0))
            #expect(distanceToA == .finite(0.0))
        }

        @Test func kShortestPaths() throws {
            let graph = createLinearGraph()

            let a = graph.findVertex(labeled: "A")!
            let c = graph.findVertex(labeled: "C")!

            let paths = graph.kShortestPaths(from: a, to: c, k: 3, using: .yen(weight: .property(\.weight)))

            #expect(paths.count == 1)

            let firstPath = try #require(paths.first)
            #expect(firstPath.vertices.count == 3)
        }

        @Test func bellmanFordHandlesNegativeWeights() {
            let graph = createNegativeWeightGraph()

            let a = graph.findVertex(labeled: "A")!
            let c = graph.findVertex(labeled: "C")!

            let bellmanFord = BellmanFord(on: graph, edgeWeight: .property(\.weight))
            let result = bellmanFord.shortestPathsFromSource(a)

            #expect(result.distances[c] == .finite(1.0))  // A -> B -> C (2 + (-1) = 1)
        }

        @Test func bidirectionalDijkstra() {
            let graph = createLinearGraph()

            let a = graph.findVertex(labeled: "A")!
            let c = graph.findVertex(labeled: "C")!

            let bidirectionalDijkstra = BidirectionalDijkstra(on: graph, edgeWeight: .property(\.weight))
            let result = bidirectionalDijkstra.shortestPath(from: a, to: c)

            #expect(result.path != nil)
            // BidirectionalDijkstra.reconstructPath puts only the meeting vertex in `vertices`
            // (source and destination are stored in path.source / path.destination, not vertices)
            #expect(result.path?.vertices.count == 1)
            #expect(result.path?.edges.count == 2)
        }

        @Test func bidirectionalDijkstraReturnsNilForUnreachable() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            // No edges: b is unreachable from a

            let bidirectionalDijkstra = BidirectionalDijkstra(on: graph, edgeWeight: .property(\.weight))
            let result = bidirectionalDijkstra.shortestPath(from: a, to: b)

            #expect(result.path == nil, "BidirectionalDijkstra must return nil path when destination is unreachable")
        }

        // MARK: - Edge Cases

        @Test func noPathExists() {
            let graph = createDisconnectedGraph()

            let a = graph.findVertex(labeled: "A")!
            let b = graph.findVertex(labeled: "B")!

            let dijkstra = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight))
            let result = dijkstra.reduce(into: nil) { $0 = $1 }!

            // Check that b is unreachable (distance should be infinite)
            let distanceToB = result.propertyMap[b][result.distanceProperty]
            #expect(distanceToB == .infinite)
        }

        @Test func singleVertex() {
            let graph = createSingleVertexGraph()

            let a = graph.findVertex(labeled: "A")!

            let dijkstra = Dijkstra(on: graph, from: a, edgeWeight: .property(\.weight))
            let result = dijkstra.reduce(into: nil) { $0 = $1 }!

            // Check that distance to self is 0
            let distanceToA = result.propertyMap[a][result.distanceProperty]
            #expect(distanceToA == .finite(0.0))
        }

        // MARK: - Observation Support

        @Test func floydWarshallComposedObservationsReceiveAllEvents() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = 3 }

            var examined1 = 0
            var examined2 = 0
            var updated1 = 0
            var updated2 = 0

            let algorithm = FloydWarshallAllPairs<AdjacencyList, Double>(weight: .property(\.weight))
                .observing { event in
                    switch event {
                        case .vertexExamined: examined1 += 1
                        case .distanceUpdated: updated1 += 1
                        default: break
                    }
                }
                .observing { event in
                    switch event {
                        case .vertexExamined: examined2 += 1
                        case .distanceUpdated: updated2 += 1
                        default: break
                    }
                }
            _ = graph.shortestPathsForAllPairs(using: algorithm)

            #expect(examined1 >= 1)  // each vertex examined as intermediate
            #expect(examined2 >= 1)
            #expect(examined1 == examined2)
            #expect(updated1 == updated2)
            // a→c path update: via b, cost 5
            let result = FloydWarshall(on: graph, edgeWeight: .property(\.weight)).shortestPathsForAllPairs()
            #expect(result.distance(from: a, to: c) == 5.0)
        }

        // MARK: - BellmanFord Direct API Coverage

        /// `BellmanFord.shortestPath(from:to:)` is the direct method that returns a `Path` struct.
        /// It differs from `BellmanFordShortestPath` (used via `.bellmanFord(...)`) which delegates
        /// to `shortestPathsFromSource`.
        @Test func bellmanFordShortestPathDirectAPI() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = -2.0 }
            graph.addEdge(from: a, to: c) { $0.weight = 3.0 }

            let bellmanFord = BellmanFord(on: graph, edgeWeight: .property(\.weight))

            // Normal path reconstruction via direct API
            let path = bellmanFord.shortestPath(from: a, to: c)
            #expect(path != nil, "path must exist from a to c")
            #expect(path?.vertices.count == 3, "a→b→c (cost -1) beats direct a→c (cost 3)")
            #expect(path?.source == a)
            #expect(path?.destination == c)
            #expect(path?.edges.count == 2, "two edges on the path")
        }

        /// `BellmanFord.shortestPath(from:to:)` returns nil for unreachable destinations.
        @Test func bellmanFordShortestPathReturnsNilForUnreachable() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            // No edges: b is unreachable from a

            let bellmanFord = BellmanFord(on: graph, edgeWeight: .property(\.weight))
            let path = bellmanFord.shortestPath(from: a, to: b)
            #expect(path == nil, "unreachable destination must return nil")
        }

        /// `BellmanFord.shortestPath(from:to:)` returns nil when a negative cycle exists.
        @Test func bellmanFordShortestPathReturnsNilForNegativeCycle() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
            graph.addEdge(from: c, to: a) { $0.weight = -3.0 }  // negative cycle

            let bellmanFord = BellmanFord(on: graph, edgeWeight: .property(\.weight))
            let path = bellmanFord.shortestPath(from: a, to: c)
            #expect(path == nil, "negative cycle must cause shortestPath to return nil")
        }

        /// BellmanFord detects negative cycles and emits `negativeCycleDetected`.
        @Test func bellmanFordDetectsNegativeCycleAndEmitsObservation() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
            graph.addEdge(from: c, to: a) { $0.weight = -3.0 }  // negative cycle

            var cycleDetected = false
            let bellmanFord = BellmanFord(on: graph, edgeWeight: .property(\.weight))
            let observation = AlgorithmObservation<BellmanFord<AdjacencyList, Double>.Event> { event in
                guard case .negativeCycleDetected = event else { return }
                cycleDetected = true
            }
            let result = bellmanFord.shortestPathsFromSource(a, observation: observation)

            #expect(result.hasNegativeCycle, "result must signal a negative cycle")
            #expect(cycleDetected, "negativeCycleDetected must be emitted for a→b→c→a (1+1-3=-1)")
        }

        /// `edgeNotRelaxed` is emitted when an edge does NOT improve the current best distance.
        /// `relaxationIterationCompleted` is emitted at the end of each relaxation sweep.
        @Test func bellmanFordEmitsEdgeNotRelaxedAndIterationCompleted() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            // Two paths to c: a→b→c (cost 3) and a→c (cost 10)
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: a, to: c) { $0.weight = 10.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 2.0 }

            var notRelaxedCount = 0
            var iterationsCompleted = 0
            let bellmanFord = BellmanFord(on: graph, edgeWeight: .property(\.weight))
            let observation = AlgorithmObservation<BellmanFord<AdjacencyList, Double>.Event> { event in
                switch event {
                    case .edgeNotRelaxed: notRelaxedCount += 1
                    case .relaxationIterationCompleted: iterationsCompleted += 1
                    default: break
                }
            }
            _ = bellmanFord.shortestPathsFromSource(a, observation: observation)

            // In iteration 2, a→c (cost 10 vs settled 3) and a→b (cost 1 vs settled 1) will not be relaxed
            #expect(notRelaxedCount >= 1, "at least one edge must not be relaxed in a converged iteration")
            #expect(iterationsCompleted >= 1, "relaxationIterationCompleted must be emitted for each sweep")
        }

        /// Exercises BellmanFord's progress events through a composed observation pair.
        ///
        /// Graph: a→b(1), a→c(1), b→c(5) — c settles via a→c (cost 1), not b→c (cost 6).
        /// - `vertexExamined` is emitted per vertex per relaxation iteration.
        /// - `edgeExamined` is emitted per edge per iteration.
        /// - `edgeRelaxed` is emitted for a→b and a→c in iteration 1.
        /// - `edgeNotRelaxed` is emitted for b→c and all edges in iteration 2.
        /// - `relaxationIterationCompleted` is emitted once per iteration (N−1 = 2 times).
        @Test func bellmanFordComposedObservationsReceiveAllEvents() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            // a→b and a→c cost 1; b→c costs 5 so c settles via a→c (dist=1), not b→c (dist=6)
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: a, to: c) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 5.0 }

            var examined1 = 0
            var examined2 = 0
            var examEdge1 = 0
            var examEdge2 = 0
            var relaxed1 = 0
            var relaxed2 = 0
            var relaxedCosts: [Double] = []
            var notRelaxed1 = 0
            var notRelaxed2 = 0
            var iterations1 = 0
            var iterations2 = 0

            let algorithm = BellmanFordShortestPath<AdjacencyList, Double>(weight: .property(\.weight))
                .observing { event in
                    switch event {
                        case .vertexExamined: examined1 += 1
                        case .edgeExamined: examEdge1 += 1
                        case .edgeRelaxed(let relaxation):
                            relaxed1 += 1
                            relaxedCosts.append(relaxation.newCost)
                        case .edgeNotRelaxed: notRelaxed1 += 1
                        case .relaxationIterationCompleted: iterations1 += 1
                        case .negativeCycleDetected: break
                    }
                }
                .observing { event in
                    switch event {
                        case .vertexExamined: examined2 += 1
                        case .edgeExamined: examEdge2 += 1
                        case .edgeRelaxed: relaxed2 += 1
                        case .edgeNotRelaxed: notRelaxed2 += 1
                        case .relaxationIterationCompleted: iterations2 += 1
                        case .negativeCycleDetected: break
                    }
                }
            _ = graph.shortestPaths(from: a, using: algorithm)

            #expect(examined1 >= 1, "vertexExamined is emitted per vertex per iteration")
            #expect(examined2 >= 1)
            #expect(examEdge1 >= 3, "edgeExamined is emitted for at least all 3 edges")
            #expect(examEdge2 >= 3)
            #expect(relaxed1 >= 1, "at least a→b and a→c are relaxed in iteration 1")
            #expect(relaxed2 >= 1)
            #expect(relaxedCosts.allSatisfy { $0 >= 0 }, "Bellman-Ford reports finite updated costs")
            #expect(notRelaxed1 >= 1, "b→c and edges in iteration 2 are not relaxed")
            #expect(notRelaxed2 >= 1)
            #expect(iterations1 >= 1, "relaxationIterationCompleted is emitted once per sweep")
            #expect(iterations2 >= 1)
            // Both composed observations must see identical event counts
            #expect(examined1 == examined2)
            #expect(examEdge1 == examEdge2)
            #expect(relaxed1 == relaxed2)
            #expect(notRelaxed1 == notRelaxed2)
            #expect(iterations1 == iterations2)
        }

        /// Ensures `negativeCycleDetected` propagates through composed BellmanFord observations.
        @Test func bellmanFordComposedObservationsReceiveNegativeCycleEvent() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
            graph.addEdge(from: c, to: a) { $0.weight = -3.0 }  // negative cycle (sum = -1)

            var detected1 = 0
            var detected2 = 0

            let algorithm = BellmanFordShortestPath<AdjacencyList, Double>(weight: .property(\.weight))
                .observing(BellmanFord<AdjacencyList, Double>.EventCases.negativeCycleDetected) { _ in
                    detected1 += 1
                }
                .observing(BellmanFord<AdjacencyList, Double>.EventCases.negativeCycleDetected) { _ in
                    detected2 += 1
                }
            _ = graph.shortestPaths(from: a, using: algorithm)

            #expect(detected1 >= 1, "negativeCycleDetected must reach the first observation")
            #expect(detected2 >= 1, "negativeCycleDetected must reach the second observation")
            #expect(detected1 == detected2, "both composed observers see the same detection events")
        }

        /// Exercises all five BidirectionalDijkstra events through a composed observation pair.
        ///
        /// Graph: a→b(1), b→c(1), b→a(1), c→b(1) — a path a→b→c with back-edges so both searches run.
        /// - `vertexExamined` is emitted for each vertex settled in either direction.
        /// - `edgeExamined` is emitted for each edge examined in either direction.
        /// - `edgeRelaxed` is emitted when an edge improves a tentative distance.
        /// - `edgeNotRelaxed` is emitted for edges pointing to already-settled vertices.
        /// - `meetingFound` is emitted when the forward and backward frontiers share a settled vertex.
        @Test func bidirectionalDijkstraComposedObservationsReceiveAllEvents() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
            // Reverse edges allow the backward search to run from c toward a
            graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
            graph.addEdge(from: c, to: b) { $0.weight = 1.0 }

            var examined1 = 0
            var examined2 = 0
            var examEdge1 = 0
            var examEdge2 = 0
            var relaxed1 = 0
            var relaxed2 = 0
            var relaxedEdges: [AdjacencyList.EdgeDescriptor] = []
            var relaxedCosts: [Double] = []
            var observedRelaxationDirection = false
            var notRelaxed1 = 0
            var notRelaxed2 = 0
            var meetings1 = 0
            var meetings2 = 0

            let algorithm = BidirectionalDijkstraShortestPath<AdjacencyList, Double>(weight: .property(\.weight))
                .observing { event in
                    switch event {
                        case .vertexExamined: examined1 += 1
                        case .edgeExamined: examEdge1 += 1
                        case .edgeRelaxed(let relaxation):
                            relaxed1 += 1
                            relaxedEdges.append(relaxation.edge)
                            relaxedCosts.append(relaxation.newCost)
                            switch relaxation.direction {
                                case .forward, .backward: observedRelaxationDirection = true
                            }
                        case .edgeNotRelaxed: notRelaxed1 += 1
                        case .meetingFound: meetings1 += 1
                    }
                }
                .observing { event in
                    switch event {
                        case .vertexExamined: examined2 += 1
                        case .edgeExamined: examEdge2 += 1
                        case .edgeRelaxed: relaxed2 += 1
                        case .edgeNotRelaxed: notRelaxed2 += 1
                        case .meetingFound: meetings2 += 1
                    }
                }
            _ = graph.shortestPath(from: a, to: c, using: algorithm)

            #expect(examined1 >= 1, "vertexExamined is emitted for settled vertices in both directions")
            #expect(examined2 >= 1)
            #expect(examEdge1 >= 1, "edgeExamined is emitted for edges explored in both directions")
            #expect(examEdge2 >= 1)
            #expect(relaxed1 >= 1, "edgeRelaxed fires when an edge improves a tentative distance")
            #expect(relaxed2 >= 1)
            #expect(relaxedEdges.count == relaxed1)
            #expect(relaxedCosts.allSatisfy { $0 >= 0 }, "directional relaxations report finite frontier costs")
            #expect(observedRelaxationDirection)
            #expect(notRelaxed1 >= 1, "back-edges like b→a do not improve the already-settled source")
            #expect(notRelaxed2 >= 1)
            // Both composed observations must see identical event counts
            #expect(examined1 == examined2)
            #expect(examEdge1 == examEdge2)
            #expect(relaxed1 == relaxed2)
            #expect(notRelaxed1 == notRelaxed2)
            #expect(meetings1 == meetings2)
        }

        /// Exercises all five BacktrackingDijkstra events through a composed observation pair.
        ///
        /// Graph: a→b(1), a→c(3), b→c(1) — two paths from a to c:
        ///   - Shortest: a→b→c (cost 2)
        ///   - Longer: a→c (cost 3) — not on any shortest path
        /// - `vertexExamined` is emitted for each vertex settled.
        /// - `edgeExamined` is emitted for each edge examined from settled vertices.
        /// - `edgeFoundOnShortestPath` is emitted for edges on the shortest path.
        /// - `vertexFinished` is emitted when a vertex is fully processed.
        /// - `pathFound` is emitted once for the single shortest path a→b→c.
        @Test func backtrackingDijkstraComposedObservationsReceiveAllEvents() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            // Shortest path: a→b→c (cost 2). Direct a→c (cost 3) is not on any shortest path.
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: a, to: c) { $0.weight = 3.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 1.0 }

            var examined1 = 0
            var examined2 = 0
            var examEdge1 = 0
            var examEdge2 = 0
            var onShortest1 = 0
            var onShortest2 = 0
            var finished1 = 0
            var finished2 = 0
            var pathsFound1 = 0
            var pathsFound2 = 0

            let algorithm = BacktrackingDijkstraAllShortestPathsAlgorithm<AdjacencyList, Double>(
                weight: .property(\.weight)
            )
            .observing { event in
                switch event {
                    case .vertexExamined: examined1 += 1
                    case .edgeExamined: examEdge1 += 1
                    case .edgeFoundOnShortestPath: onShortest1 += 1
                    case .vertexFinished: finished1 += 1
                    case .pathFound: pathsFound1 += 1
                }
            }
            .observing { event in
                switch event {
                    case .vertexExamined: examined2 += 1
                    case .edgeExamined: examEdge2 += 1
                    case .edgeFoundOnShortestPath: onShortest2 += 1
                    case .vertexFinished: finished2 += 1
                    case .pathFound: pathsFound2 += 1
                }
            }
            _ = graph.allShortestPaths(from: a, to: c, using: algorithm)

            #expect(examined1 >= 1, "vertexExamined is emitted for each settled vertex")
            #expect(examined2 >= 1)
            #expect(examEdge1 >= 1, "edgeExamined is emitted for each edge examined")
            #expect(examEdge2 >= 1)
            #expect(onShortest1 >= 1, "edgeFoundOnShortestPath is emitted for a→b and b→c")
            #expect(onShortest2 >= 1)
            #expect(finished1 >= 1, "vertexFinished is emitted for each processed vertex")
            #expect(finished2 >= 1)
            #expect(pathsFound1 == 1, "exactly one shortest path: a→b→c")
            #expect(pathsFound2 == 1)
            // Both composed observations must see identical event counts
            #expect(examined1 == examined2)
            #expect(examEdge1 == examEdge2)
            #expect(onShortest1 == onShortest2)
            #expect(finished1 == finished2)
            #expect(pathsFound1 == pathsFound2)
        }

        // MARK: - Multi-Backend Coverage

        @Test func dijkstraChoosesShortestPath_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                let c = graph.addVertex { $0.label = "C" }
                graph.addEdge(from: a, to: b) { $0.weight = 2 }
                graph.addEdge(from: b, to: c) { $0.weight = 3 }
                graph.addEdge(from: a, to: c) { $0.weight = 10 }  // longer direct path

                let path = graph.shortestPath(from: a, to: c, using: .dijkstra(weight: .property(\.weight)))
                // a→b→c (cost 5) must be preferred over a→c direct (cost 10)
                #expect(path != nil, "[\(backend)] path from a to c must exist")
                #expect(path?.vertices.count == 3, "[\(backend)] shortest route visits a, b, c (not the direct 2-vertex path)")
            }
            var g1 = AdjacencyList()
            check(&g1, "default")
            var g4 = AdjacencyMatrix()
            check(&g4, "Matrix")
            #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
                var g2 = StorageBackedAdjacencyList(edgeStorage: CSREdgeStorage().cacheInOutEdges())
                check(&g2, "CSR")
                var g3 = StorageBackedAdjacencyList(edgeStorage: COOEdgeStorage().cacheInOutEdges())
                check(&g3, "COO")
            #endif
        }

        @Test func dijkstraUnreachableReturnsNil_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                // no edge between a and b

                let path = graph.shortestPath(from: a, to: b, using: .dijkstra(weight: .property(\.weight)))
                #expect(path == nil, "[\(backend)] no path from a to b in disconnected graph")
            }
            var g1 = AdjacencyList()
            check(&g1, "default")
            var g4 = AdjacencyMatrix()
            check(&g4, "Matrix")
            #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
                var g2 = StorageBackedAdjacencyList(edgeStorage: CSREdgeStorage().cacheInOutEdges())
                check(&g2, "CSR")
                var g3 = StorageBackedAdjacencyList(edgeStorage: COOEdgeStorage().cacheInOutEdges())
                check(&g3, "COO")
            #endif
        }

        @Test func bellmanFordChoosesNegativeWeightPath_allBackends() {
            // BellmanFord additionally requires EdgeListGraph; both AdjacencyList and AdjacencyMatrix satisfy it.
            func check<G: TestablePropertyGraph & EdgeListGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                let c = graph.addVertex { $0.label = "C" }
                graph.addEdge(from: a, to: b) { $0.weight = 1 }
                graph.addEdge(from: b, to: c) { $0.weight = -2 }
                graph.addEdge(from: a, to: c) { $0.weight = 3 }  // suboptimal direct path

                let path = graph.shortestPath(from: a, to: c, using: .bellmanFord(weight: .property(\.weight)))
                // a→b→c (cost 1+(-2)=-1) beats direct a→c (cost 3)
                #expect(path != nil, "[\(backend)] path must exist")
                #expect(path?.vertices.count == 3, "[\(backend)] BellmanFord chooses 3-vertex path a→b→c over direct 2-vertex a→c")
            }
            var g1 = AdjacencyList()
            check(&g1, "default")
            var g4 = AdjacencyMatrix()
            check(&g4, "Matrix")
            #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
                var g2 = StorageBackedAdjacencyList(edgeStorage: CSREdgeStorage().cacheInOutEdges())
                check(&g2, "CSR")
                var g3 = StorageBackedAdjacencyList(edgeStorage: COOEdgeStorage().cacheInOutEdges())
                check(&g3, "COO")
            #endif
        }

        /// `BidirectionalDijkstra` requires a `BidirectionalGraph` (for backward search).
        /// Both `AdjacencyList` (with `CacheInOutEdges`) and `AdjacencyMatrix` satisfy this.
        /// Reverse edges must be present so the backward search has somewhere to go.
        @Test func bidirectionalDijkstraFindsPath_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                let c = graph.addVertex { $0.label = "C" }
                graph.addEdge(from: a, to: b) { $0.weight = 1 }
                graph.addEdge(from: b, to: a) { $0.weight = 1 }  // reverse edge for backward search
                graph.addEdge(from: b, to: c) { $0.weight = 1 }
                graph.addEdge(from: c, to: b) { $0.weight = 1 }  // reverse edge for backward search

                let path = graph.shortestPath(from: a, to: c, using: .bidirectionalDijkstra(weight: .property(\.weight)))
                #expect(path != nil, "[\(backend)] BidirectionalDijkstra must find a path from a to c")
                #expect(path?.edges.count == 2, "[\(backend)] path a→b→c uses 2 edges")
            }
            var g1 = AdjacencyList()
            check(&g1, "default")
            var g4 = AdjacencyMatrix()
            check(&g4, "Matrix")
            #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
                var g2 = StorageBackedAdjacencyList(edgeStorage: CSREdgeStorage().cacheInOutEdges())
                check(&g2, "CSR")
                var g3 = StorageBackedAdjacencyList(edgeStorage: COOEdgeStorage().cacheInOutEdges())
                check(&g3, "COO")
            #endif
        }
    }
#endif
