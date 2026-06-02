#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    @testable import Graphs
    import Testing

    #if canImport(simd)
        import simd

        struct AStarTests {

            // MARK: - Core Behavior

            @Test func findsShortestPathWithHeuristic() {
                var graph = AdjacencyList()
                let a = graph.addVertex()
                let b = graph.addVertex()
                let c = graph.addVertex()
                let d = graph.addVertex()

                graph.addEdge(from: a, to: b) { $0.weight = 1 }
                graph.addEdge(from: a, to: c) { $0.weight = 2 }
                graph.addEdge(from: c, to: d) { $0.weight = 1 }
                graph.addEdge(from: b, to: d) { $0.weight = 5 }

                let path = graph.shortestPath(
                    from: a,
                    to: d,
                    using: .aStar(
                        weight: .property(\.weight),
                        heuristic: .euclideanDistance(of: \.coordinates)
                    )
                )
                #expect(path?.vertices == [a, c, d])

                let res = AStar(
                    on: graph,
                    from: a,
                    edgeWeight: .property(\.weight),
                    heuristic: .uniform(0),
                    calculateTotalCost: +
                ).first { $0.currentVertex == d }
                #expect(res?.vertices(to: d, in: graph) == [a, c, d])
            }

            // MARK: - Multi-Backend Coverage

            @Test func findsShortestPath_allBackends() {
                func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
                where
                    G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                    G.VertexDescriptor: Hashable
                {
                    let a = graph.addVertex { $0.label = "A" }
                    let b = graph.addVertex { $0.label = "B" }
                    let c = graph.addVertex { $0.label = "C" }
                    graph.addEdge(from: a, to: b) { $0.weight = 1 }
                    graph.addEdge(from: a, to: c) { $0.weight = 10 }
                    graph.addEdge(from: b, to: c) { $0.weight = 1 }
                    let path = graph.shortestPath(
                        from: a,
                        to: c,
                        using: .aStar(weight: .property(\.weight), heuristic: .uniform(0))
                    )
                    #expect(path?.vertices.count == 3, "[\(backend)] expected 3-vertex path A→B→C")
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

            @Test func returnsNilForUnreachableVertex_allBackends() {
                func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
                where
                    G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                    G.VertexDescriptor: Hashable
                {
                    let a = graph.addVertex { $0.label = "A" }
                    let b = graph.addVertex { $0.label = "B" }
                    let path = graph.shortestPath(
                        from: a,
                        to: b,
                        using: .aStar(weight: .property(\.weight), heuristic: .uniform(0))
                    )
                    #expect(path == nil, "[\(backend)] expected nil for unreachable vertex")
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

            @Test func zeroHeuristicBehavesLikeDijkstra_allBackends() {
                func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
                where
                    G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                    G.VertexDescriptor: Hashable
                {
                    let a = graph.addVertex()
                    let b = graph.addVertex()
                    let c = graph.addVertex()
                    graph.addEdge(from: a, to: b) { $0.weight = 2 }
                    graph.addEdge(from: a, to: c) { $0.weight = 1 }
                    graph.addEdge(from: c, to: b) { $0.weight = 0.5 }

                    let astar = graph.shortestPath(
                        from: a,
                        to: b,
                        using: .aStar(weight: .property(\.weight), heuristic: .uniform(0))
                    )
                    let dijkstra = graph.shortestPath(from: a, to: b, using: .dijkstra(weight: .property(\.weight)))
                    #expect(astar?.vertices.count == dijkstra?.vertices.count, "[\(backend)] A* with zero heuristic should match Dijkstra path length")
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

            // MARK: - Visitor Support

            /// Exercises all five A* visitor events through a composed visitor pair.
            ///
            /// Graph: a→b(1), a→c(1), b→c(5) with a zero heuristic (degrades to Dijkstra).
            /// - `examineVertex` fires for each of the 3 vertices.
            /// - `examineEdge` fires for each of the 3 edges.
            /// - `edgeRelaxed` fires for a→b and a→c (both improve their targets).
            /// - `edgeNotRelaxed` fires for b→c (c already settled at cost 1 via a→c; b→c would cost 6).
            /// - `finishVertex` fires for each of the 3 vertices.
            @Test func composedVisitorsReceiveAllEvents() {
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
                var finished1 = 0
                var finished2 = 0

                var v1 = AStar<DefaultAdjacencyList, Double, Double, Double>.Visitor()
                v1.examineVertex = { _ in examined1 += 1 }
                v1.examineEdge = { _ in examEdge1 += 1 }
                v1.edgeRelaxed = { _ in relaxed1 += 1 }
                v1.edgeNotRelaxed = { _ in notRelaxed1 += 1 }
                v1.finishVertex = { _ in finished1 += 1 }

                var v2 = AStar<DefaultAdjacencyList, Double, Double, Double>.Visitor()
                v2.examineVertex = { _ in examined2 += 1 }
                v2.examineEdge = { _ in examEdge2 += 1 }
                v2.edgeRelaxed = { _ in relaxed2 += 1 }
                v2.edgeNotRelaxed = { _ in notRelaxed2 += 1 }
                v2.finishVertex = { _ in finished2 += 1 }

                let combined = v1.combined(with: v2)
                AStar(on: graph, from: a, edgeWeight: .property(\.weight), heuristic: .uniform(0), calculateTotalCost: +)
                    .withVisitor { combined }
                    .forEach { _ in }

                #expect(examined1 == 3, "examineVertex fires once per vertex")
                #expect(examined2 == 3)
                #expect(examEdge1 == 3, "examineEdge fires once per edge (a→b, a→c, b→c)")
                #expect(examEdge2 == 3)
                #expect(relaxed1 == 2, "a→b and a→c both improve their targets")
                #expect(relaxed2 == 2)
                #expect(notRelaxed1 >= 1, "b→c does not improve c (already at cost 1)")
                #expect(notRelaxed2 >= 1)
                #expect(finished1 == 3, "finishVertex fires once per vertex")
                #expect(finished2 == 3)
                // Both composed visitors must see identical event counts
                #expect(examined1 == examined2)
                #expect(examEdge1 == examEdge2)
                #expect(relaxed1 == relaxed2)
                #expect(notRelaxed1 == notRelaxed2)
                #expect(finished1 == finished2)
            }

            // MARK: - DistanceAlgorithm SIMD overloads

            /// `DistanceAlgorithm.euclidean(_: SIMD2<Double>)` (Double-specific overload) calculates
            /// the correct Euclidean distance via `simd_distance`. Also exercises `SIMD.squared()`.
            @Test func distanceAlgorithmEuclideanSIMD2Double() {
                // 3-4-5 right triangle
                let algo = DistanceAlgorithm<SIMD2<Double>, Double>.euclidean { $0 }
                #expect(algo.calculateDistance(SIMD2(0, 0), SIMD2(3, 4)) == 5.0)
                #expect(algo.calculateDistance(SIMD2(1, 1), SIMD2(1, 1)) == 0.0)
            }

            /// `DistanceAlgorithm.manhattan(_: SIMD2<Double>)` (Double-specific overload) calculates
            /// the correct Manhattan distance as |dx| + |dy|.
            @Test func distanceAlgorithmManhattanSIMD2Double() {
                let algo = DistanceAlgorithm<SIMD2<Double>, Double>.manhattan { $0 }
                #expect(algo.calculateDistance(SIMD2(0, 0), SIMD2(3, 4)) == 7.0)
                #expect(algo.calculateDistance(SIMD2(1, 2), SIMD2(4, 6)) == 7.0)
            }

            /// `DistanceAlgorithm.euclidean(_: SIMD)` (generic SIMD overload) uses `squared().sum().squareRoot()`.
            @Test func distanceAlgorithmEuclideanGenericSIMD() {
                // Use SIMD4<Float> to exercise the generic overload (distinct from SIMD2<Double>)
                let algo = DistanceAlgorithm<SIMD4<Float>, Float>.euclidean { $0 }
                let a = SIMD4<Float>(1, 0, 0, 0)
                let b = SIMD4<Float>(0, 0, 0, 0)
                #expect(algo.calculateDistance(a, b) == 1.0, "unit vector has Euclidean distance 1 from origin")
            }

            /// `DistanceAlgorithm.manhattan(_: SIMD)` (generic SIMD overload) sums component
            /// differences without abs — the result is signed, unlike the Double-specific overload.
            @Test func distanceAlgorithmManhattanGenericSIMD() {
                let algo = DistanceAlgorithm<SIMD2<Float>, Float>.manhattan { $0 }
                // a=(3,4), b=(0,0): (3-0)+(4-0) = 7 (positive when a > b component-wise)
                #expect(algo.calculateDistance(SIMD2(3, 4), SIMD2(0, 0)) == 7.0)
            }

            /// A* with `.manhattanDistance` heuristic finds the correct path.
            @Test func aStarManhattanDistanceHeuristic() {
                var graph = AdjacencyList()
                let a = graph.addVertex { $0.coordinates = SIMD2<Double>(0, 0) }
                let b = graph.addVertex { $0.coordinates = SIMD2<Double>(1, 0) }
                let c = graph.addVertex { $0.coordinates = SIMD2<Double>(0, 1) }
                let d = graph.addVertex { $0.coordinates = SIMD2<Double>(1, 1) }

                graph.addEdge(from: a, to: b) { $0.weight = 1 }
                graph.addEdge(from: b, to: d) { $0.weight = 1 }
                graph.addEdge(from: a, to: c) { $0.weight = 1 }
                graph.addEdge(from: c, to: d) { $0.weight = 5 }

                let path = graph.shortestPath(
                    from: a,
                    to: d,
                    using: .aStar(weight: .property(\.weight), heuristic: .manhattanDistance(of: \.coordinates))
                )
                #expect(path?.vertices == [a, b, d], "Manhattan heuristic prefers a→b→d (cost 2) over a→c→d (cost 6)")
            }
        }
    #endif  // canImport(simd)

    // MARK: - A* Result Context API Coverage
    // These tests do not require simd — they use a uniform heuristic (no coordinate math).

    struct AStarContextTests {

        /// `predecessor(in:)`, `predecessorEdge()`, `vertices(in:)`, `edges(in:)` and `path(in:)` are
        /// currentVertex-based convenience wrappers on `AStar.Result`. Only safe on non-source elements.
        @Test func aStarResultContextMethodsDuringIteration() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 2.0 }

            var pathLengths: [Int] = []
            var edgeLengths: [Int] = []
            for result in AStar(on: graph, from: a, edgeWeight: .property(\.weight), heuristic: .uniform(0), calculateTotalCost: +) {
                pathLengths.append(result.vertices(in: graph).count)
                edgeLengths.append(result.edges(in: graph).count)
                _ = result.path(in: graph)
                if result.currentVertex != a {
                    _ = result.predecessor(in: graph)
                    _ = result.predecessorEdge()
                }
            }

            // a: 1 vertex / 0 edges; b: 2 vertices / 1 edge; c: 3 vertices / 2 edges
            #expect(pathLengths == [1, 2, 3], "path vertex counts grow along the chain")
            #expect(edgeLengths == [0, 1, 2], "path edge counts grow along the chain")
        }

        /// `gScore(of:)` returns the g-score (cost from source) for a given vertex.
        /// `hasPath(to:)` returns true for reachable vertices, false for unreachable ones.
        /// `predecessor(of:in:)` returns the tree predecessor or nil for the source.
        @Test func aStarResultGScoreAndHasPath() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let isolated = graph.addVertex { $0.label = "X" }
            graph.addEdge(from: a, to: b) { $0.weight = 3.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 4.0 }

            let result = AStar(on: graph, from: a, edgeWeight: .property(\.weight), heuristic: .uniform(0), calculateTotalCost: +)
                .reduce(into: nil) { $0 = $1 }

            #expect(result?.gScore(of: a) == .finite(0.0), "g-score of source is 0")
            #expect(result?.gScore(of: b) == .finite(3.0), "g-score of b is 3 (a→b weight)")
            #expect(result?.gScore(of: c) == .finite(7.0), "g-score of c is 7 (a→b→c total)")

            #expect(result?.hasPath(to: a) == true, "source is always reachable")
            #expect(result?.hasPath(to: b) == true, "b reachable via a→b")
            #expect(result?.hasPath(to: c) == true, "c reachable via a→b→c")
            #expect(result?.hasPath(to: isolated) == false, "isolated vertex is not reachable")

            #expect(result?.predecessor(of: a, in: graph) == nil, "source has no predecessor")
            #expect(result?.predecessor(of: b, in: graph) == a, "b's predecessor is a")
            #expect(result?.predecessor(of: c, in: graph) == b, "c's predecessor is b")
        }

        /// `AStar.PriorityItem` is `Equatable` by vertex identity (totalCost is ignored in `==`).
        @Test func aStarPriorityItemEquatable() {
            var graph = AdjacencyList()
            let a = graph.addVertex()
            let b = graph.addVertex()

            let item1 = AStar<DefaultAdjacencyList, Double, Double, Double>.PriorityItem(vertex: a, totalCost: 3.0)
            let item2 = AStar<DefaultAdjacencyList, Double, Double, Double>.PriorityItem(vertex: a, totalCost: 9.0)
            let item3 = AStar<DefaultAdjacencyList, Double, Double, Double>.PriorityItem(vertex: b, totalCost: 3.0)

            #expect(item1 == item2, "same vertex, different totalCost → equal (vertex identity only)")
            #expect(item1 != item3, "different vertices → not equal")
        }

        // MARK: - ShortestPathUntil API

        /// `AStarShortestPathAlgorithm` conforms to `ShortestPathUntilAlgorithm` — the `until`-based
        /// search stops at the first vertex satisfying the condition, using A* to guide exploration.
        @Test func aStarShortestPathUntilCondition() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
            graph.addEdge(from: c, to: d) { $0.weight = 1.0 }

            // Find first vertex whose label equals "C" — must stop at c via a→b→c (not continue to d)
            let path = graph.shortestPath(
                from: a,
                until: { graph[$0].label == "C" },
                using: .aStar(weight: .property(\.weight), heuristic: .uniform(0))
            )
            #expect(path != nil, "A* must find path to first vertex satisfying the condition")
            #expect(path?.destination == c, "the first vertex satisfying 'label == C' is c")
            #expect(path?.vertices.count == 3, "path a→b→c has 3 vertices")
        }

        /// `edgeNotRelaxed` fires when a neighbor already has a better gScore (path cost) from elsewhere.
        ///
        /// Graph: a→b (1), a→c (2), b→d (1), c→d (5).
        /// When c is processed, d already has gScore=2 via a→b→d. The c→d edge (cost 7) is worse, so it fires `edgeNotRelaxed`.
        @Test func aStarEdgeNotRelaxedFiredForSuboptimalEdge() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: a, to: c) { $0.weight = 2.0 }
            graph.addEdge(from: b, to: d) { $0.weight = 1.0 }  // short path: a→b→d cost 2
            graph.addEdge(from: c, to: d) { $0.weight = 5.0 }  // long path: a→c→d cost 7 — not relaxed

            var notRelaxedCount = 0
            AStar(on: graph, from: a, edgeWeight: .property(\.weight), heuristic: .uniform(0), calculateTotalCost: +)
                .withVisitor { .init(edgeNotRelaxed: { _ in notRelaxedCount += 1 }) }
                .forEach { _ in }

            #expect(notRelaxedCount >= 1, "c→d should not be relaxed because d already has gScore 2 via a→b→d")
        }

        /// `edgeNotRelaxed` must fire for edges to already-settled vertices regardless of
        /// the order vertices are dequeued from the priority queue.
        ///
        /// Graph: a→b (1), a→c (1), b→c (5).
        /// Both b and c settle at gScore=1 (via a). When b is processed, c already has
        /// gScore=1, so b→c (would cost 6) is not relaxed. Because `edgeNotRelaxed` must
        /// fire whether c is settled or merely has a better stored gScore, this test is
        /// order-independent: regardless of whether b or c is dequeued first, the
        /// b→c edge always fires `edgeNotRelaxed`.
        @Test func aStarEdgeNotRelaxedFiredEvenForSettledNeighbor() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: a, to: c) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 5.0 }  // b→c costs 6 total; c already at 1

            var notRelaxedCount = 0
            AStar(on: graph, from: a, edgeWeight: .property(\.weight), heuristic: .uniform(0), calculateTotalCost: +)
                .withVisitor { .init(edgeNotRelaxed: { _ in notRelaxedCount += 1 }) }
                .forEach { _ in }

            #expect(notRelaxedCount >= 1, "b→c must fire edgeNotRelaxed regardless of whether c was already dequeued")
        }
    }
#endif
