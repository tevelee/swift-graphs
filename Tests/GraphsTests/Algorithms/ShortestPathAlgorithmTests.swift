#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    @testable import Graphs
    import Testing

    struct ShortestPathAlgorithmTests {

        func createLinearGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = 3 }

            return graph
        }

        func createNegativeWeightGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = -1 }

            return graph
        }

        func createDisconnectedGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()

            graph.addVertex { $0.label = "A" }
            graph.addVertex { $0.label = "B" }
            // No edges between A and B

            return graph
        }

        func createSingleVertexGraph() -> some AdjacencyListProtocol {
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

        // MARK: - Visitor Support

        @Test func floydWarshallComposedVisitorsReceiveAllEvents() {
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

            var v1 = FloydWarshall<DefaultAdjacencyList, Double>.Visitor()
            v1.examineVertex = { _ in examined1 += 1 }
            v1.updateDistance = { _, _, _ in updated1 += 1 }

            var v2 = FloydWarshall<DefaultAdjacencyList, Double>.Visitor()
            v2.examineVertex = { _ in examined2 += 1 }
            v2.updateDistance = { _, _, _ in updated2 += 1 }

            let combined = v1.combined(with: v2)
            _ = FloydWarshall(on: graph, edgeWeight: .property(\.weight))
                .shortestPathsForAllPairs(visitor: combined)

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

        /// BellmanFord detects negative cycles and fires the `detectNegativeCycle` visitor callback.
        @Test func bellmanFordDetectsNegativeCycleAndCallsVisitor() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
            graph.addEdge(from: c, to: a) { $0.weight = -3.0 }  // negative cycle

            var cycleDetected = false
            let bellmanFord = BellmanFord(on: graph, edgeWeight: .property(\.weight))
            let result = bellmanFord.shortestPathsFromSource(
                a,
                visitor: .init(
                    detectNegativeCycle: { _ in cycleDetected = true }
                )
            )

            #expect(result.hasNegativeCycle, "result must signal a negative cycle")
            #expect(cycleDetected, "detectNegativeCycle visitor must fire for a→b→c→a (1+1-3=-1)")
        }

        /// `edgeNotRelaxed` fires when an edge is examined but does NOT improve the current best distance.
        /// `completeRelaxationIteration` fires at the end of each relaxation sweep.
        @Test func bellmanFordEdgeNotRelaxedAndIterationCompletionCallbacks() {
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
            _ = bellmanFord.shortestPathsFromSource(
                a,
                visitor: .init(
                    edgeNotRelaxed: { _ in notRelaxedCount += 1 },
                    completeRelaxationIteration: { _ in iterationsCompleted += 1 }
                )
            )

            // In iteration 2, a→c (cost 10 vs settled 3) and a→b (cost 1 vs settled 1) will not be relaxed
            #expect(notRelaxedCount >= 1, "at least one edge must not be relaxed in a converged iteration")
            #expect(iterationsCompleted >= 1, "completeRelaxationIteration must fire for each sweep")
        }

        /// Exercises all six BellmanFord visitor events through a composed visitor pair.
        ///
        /// Graph: a→b(1), a→c(1), b→c(5) — c settles via a→c (cost 1), not b→c (cost 6).
        /// - `examineVertex` fires per vertex per relaxation iteration.
        /// - `examineEdge` fires per edge per iteration.
        /// - `edgeRelaxed` fires for a→b and a→c in iteration 1.
        /// - `edgeNotRelaxed` fires for b→c (c already settled; 1+5=6 > 1) and all edges in iteration 2.
        /// - `completeRelaxationIteration` fires once per iteration (N−1 = 2 times).
        @Test func bellmanFordComposedVisitorsReceiveAllEvents() {
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
            var notRelaxed1 = 0
            var notRelaxed2 = 0
            var iterations1 = 0
            var iterations2 = 0

            var v1 = BellmanFord<DefaultAdjacencyList, Double>.Visitor()
            v1.examineVertex = { _ in examined1 += 1 }
            v1.examineEdge = { _ in examEdge1 += 1 }
            v1.edgeRelaxed = { _ in relaxed1 += 1 }
            v1.edgeNotRelaxed = { _ in notRelaxed1 += 1 }
            v1.completeRelaxationIteration = { _ in iterations1 += 1 }

            var v2 = BellmanFord<DefaultAdjacencyList, Double>.Visitor()
            v2.examineVertex = { _ in examined2 += 1 }
            v2.examineEdge = { _ in examEdge2 += 1 }
            v2.edgeRelaxed = { _ in relaxed2 += 1 }
            v2.edgeNotRelaxed = { _ in notRelaxed2 += 1 }
            v2.completeRelaxationIteration = { _ in iterations2 += 1 }

            let combined = v1.combined(with: v2)
            _ = BellmanFord(on: graph, edgeWeight: .property(\.weight))
                .shortestPathsFromSource(a, visitor: combined)

            #expect(examined1 >= 1, "examineVertex fires per vertex per iteration")
            #expect(examined2 >= 1)
            #expect(examEdge1 >= 3, "examineEdge fires for at least all 3 edges")
            #expect(examEdge2 >= 3)
            #expect(relaxed1 >= 1, "at least a→b and a→c are relaxed in iteration 1")
            #expect(relaxed2 >= 1)
            #expect(notRelaxed1 >= 1, "b→c and edges in iteration 2 are not relaxed")
            #expect(notRelaxed2 >= 1)
            #expect(iterations1 >= 1, "completeRelaxationIteration fires once per sweep")
            #expect(iterations2 >= 1)
            // Both composed visitors must see identical event counts
            #expect(examined1 == examined2)
            #expect(examEdge1 == examEdge2)
            #expect(relaxed1 == relaxed2)
            #expect(notRelaxed1 == notRelaxed2)
            #expect(iterations1 == iterations2)
        }

        /// Ensures the `detectNegativeCycle` event propagates through composed BellmanFord visitors.
        @Test func bellmanFordComposedVisitors_detectNegativeCycleEvent() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
            graph.addEdge(from: c, to: a) { $0.weight = -3.0 }  // negative cycle (sum = -1)

            var detected1 = 0
            var detected2 = 0

            var v1 = BellmanFord<DefaultAdjacencyList, Double>.Visitor()
            v1.detectNegativeCycle = { _ in detected1 += 1 }

            var v2 = BellmanFord<DefaultAdjacencyList, Double>.Visitor()
            v2.detectNegativeCycle = { _ in detected2 += 1 }

            let combined = v1.combined(with: v2)
            _ = BellmanFord(on: graph, edgeWeight: .property(\.weight))
                .shortestPathsFromSource(a, visitor: combined)

            #expect(detected1 >= 1, "detectNegativeCycle must fire through composed visitor v1")
            #expect(detected2 >= 1, "detectNegativeCycle must fire through composed visitor v2")
            #expect(detected1 == detected2, "both composed observers see the same detection events")
        }

        /// Exercises all five BidirectionalDijkstra visitor events through a composed visitor pair.
        ///
        /// Graph: a→b(1), b→c(1), b→a(1), c→b(1) — a path a→b→c with back-edges so both searches run.
        /// - `examineVertex` fires for each vertex settled in either direction.
        /// - `examineEdge` fires for each edge examined in either direction.
        /// - `edgeRelaxed` fires when an edge improves a tentative distance.
        /// - `edgeNotRelaxed` fires for edges pointing to already-settled vertices (e.g. b→a).
        /// - `meetingFound` fires when the forward and backward frontiers share a settled vertex.
        @Test func bidirectionalDijkstraComposedVisitorsReceiveAllEvents() {
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
            var notRelaxed1 = 0
            var notRelaxed2 = 0
            var meetings1 = 0
            var meetings2 = 0

            var v1 = BidirectionalDijkstra<DefaultAdjacencyList, Double>.Visitor()
            v1.examineVertex = { _, _ in examined1 += 1 }
            v1.examineEdge = { _, _ in examEdge1 += 1 }
            v1.edgeRelaxed = { _, _ in relaxed1 += 1 }
            v1.edgeNotRelaxed = { _, _ in notRelaxed1 += 1 }
            v1.meetingFound = { _, _ in meetings1 += 1 }

            var v2 = BidirectionalDijkstra<DefaultAdjacencyList, Double>.Visitor()
            v2.examineVertex = { _, _ in examined2 += 1 }
            v2.examineEdge = { _, _ in examEdge2 += 1 }
            v2.edgeRelaxed = { _, _ in relaxed2 += 1 }
            v2.edgeNotRelaxed = { _, _ in notRelaxed2 += 1 }
            v2.meetingFound = { _, _ in meetings2 += 1 }

            let combined = v1.combined(with: v2)
            _ = BidirectionalDijkstra(on: graph, edgeWeight: .property(\.weight))
                .shortestPath(from: a, to: c, visitor: combined)

            #expect(examined1 >= 1, "examineVertex fires for settled vertices in both directions")
            #expect(examined2 >= 1)
            #expect(examEdge1 >= 1, "examineEdge fires for edges explored in both directions")
            #expect(examEdge2 >= 1)
            #expect(relaxed1 >= 1, "edgeRelaxed fires when an edge improves a tentative distance")
            #expect(relaxed2 >= 1)
            #expect(notRelaxed1 >= 1, "back-edges like b→a do not improve the already-settled source")
            #expect(notRelaxed2 >= 1)
            // Both composed visitors must see identical event counts
            #expect(examined1 == examined2)
            #expect(examEdge1 == examEdge2)
            #expect(relaxed1 == relaxed2)
            #expect(notRelaxed1 == notRelaxed2)
            #expect(meetings1 == meetings2)
        }

        /// Exercises all five BacktrackingDijkstra visitor events through a composed visitor pair.
        ///
        /// Graph: a→b(1), a→c(3), b→c(1) — two paths from a to c:
        ///   - Shortest: a→b→c (cost 2)
        ///   - Longer: a→c (cost 3) — not on any shortest path
        /// - `examineVertex` fires for each vertex settled.
        /// - `examineEdge` fires for each edge examined from settled vertices.
        /// - `edgeOnShortestPath` fires for edges that are part of the shortest path (a→b and b→c).
        /// - `finishVertex` fires when a vertex is fully processed.
        /// - `pathFound` fires once for the single shortest path a→b→c.
        @Test func backtrackingDijkstraComposedVisitorsReceiveAllEvents() {
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

            var v1 = BacktrackingDijkstra<DefaultAdjacencyList, Double>.Visitor()
            v1.examineVertex = { _ in examined1 += 1 }
            v1.examineEdge = { _ in examEdge1 += 1 }
            v1.edgeOnShortestPath = { _ in onShortest1 += 1 }
            v1.finishVertex = { _ in finished1 += 1 }
            v1.pathFound = { _, _ in pathsFound1 += 1 }

            var v2 = BacktrackingDijkstra<DefaultAdjacencyList, Double>.Visitor()
            v2.examineVertex = { _ in examined2 += 1 }
            v2.examineEdge = { _ in examEdge2 += 1 }
            v2.edgeOnShortestPath = { _ in onShortest2 += 1 }
            v2.finishVertex = { _ in finished2 += 1 }
            v2.pathFound = { _, _ in pathsFound2 += 1 }

            let combined = v1.combined(with: v2)
            _ = BacktrackingDijkstra(on: graph, edgeWeight: .property(\.weight))
                .findAllShortestPaths(from: a, to: c, visitor: combined)

            #expect(examined1 >= 1, "examineVertex fires for each settled vertex")
            #expect(examined2 >= 1)
            #expect(examEdge1 >= 1, "examineEdge fires for each edge examined")
            #expect(examEdge2 >= 1)
            #expect(onShortest1 >= 1, "edgeOnShortestPath fires for a→b and b→c")
            #expect(onShortest2 >= 1)
            #expect(finished1 >= 1, "finishVertex fires for each processed vertex")
            #expect(finished2 >= 1)
            #expect(pathsFound1 == 1, "exactly one shortest path: a→b→c")
            #expect(pathsFound2 == 1)
            // Both composed visitors must see identical event counts
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
                var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
                check(&g2, "CSR")
                var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())
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
                var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
                check(&g2, "CSR")
                var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())
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
                var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
                check(&g2, "CSR")
                var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())
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
                var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges())
                check(&g2, "CSR")
                var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges())
                check(&g3, "COO")
            #endif
        }
    }
#endif
