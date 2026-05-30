#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    @testable import Graphs
    import Testing

    struct AllShortestPathsTests {

        /// Creates a graph with multiple paths of equal cost.
        /// Structure:
        ///     A --2--> B --1--> D
        ///     |                 ^
        ///     +-----1--> C --2--+
        ///
        /// Two paths from A to D both cost 3:
        /// - A -> B -> D (2 + 1 = 3)
        /// - A -> C -> D (1 + 2 = 3)
        func createMultipleEqualPathsGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: d) { $0.weight = 1 }
            graph.addEdge(from: a, to: c) { $0.weight = 1 }
            graph.addEdge(from: c, to: d) { $0.weight = 2 }

            return graph
        }

        /// Creates a graph with three paths of equal cost.
        /// Structure:
        ///     A --1--> B --1--> C
        ///     |        |        ^
        ///     +--1--> D  --1----+
        ///     |                 ^
        ///     +------2----------+
        ///
        /// Three paths from A to C all cost 2:
        /// - A -> B -> C (1 + 1 = 2)
        /// - A -> D -> C (1 + 1 = 2)
        /// - A -> C (2)
        func createThreeEqualPathsGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: b, to: c) { $0.weight = 1 }
            graph.addEdge(from: a, to: d) { $0.weight = 1 }
            graph.addEdge(from: d, to: c) { $0.weight = 1 }
            graph.addEdge(from: a, to: c) { $0.weight = 2 }

            return graph
        }

        /// Creates a linear graph (single path).
        func createLinearGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = 3 }

            return graph
        }

        /// Creates a disconnected graph (no path).
        func createDisconnectedGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()

            graph.addVertex { $0.label = "A" }
            graph.addVertex { $0.label = "B" }

            return graph
        }

        /// Creates a diamond graph with multiple paths of different costs.
        /// Structure:
        ///     A --1--> B --1--> D
        ///     |                 ^
        ///     +--3--> C --1-----+
        ///
        /// Two paths from A to D:
        /// - A -> B -> D (1 + 1 = 2) - shortest
        /// - A -> C -> D (3 + 1 = 4) - longer
        func createDiamondGraphDifferentCosts() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: b, to: d) { $0.weight = 1 }
            graph.addEdge(from: a, to: c) { $0.weight = 3 }
            graph.addEdge(from: c, to: d) { $0.weight = 1 }

            return graph
        }

        @Test func twoEqualPaths() {
            let graph = createMultipleEqualPathsGraph()

            let a = graph.findVertex(labeled: "A")!
            let d = graph.findVertex(labeled: "D")!

            let paths = graph.allShortestPaths(from: a, to: d, weight: .property(\.weight))

            #expect(paths.count == 2)

            // Both paths should have cost 3
            for path in paths {
                let cost = path.edges.reduce(0.0) { sum, edge in
                    sum + graph[edge].weight
                }
                #expect(cost == 3.0)
            }

            // Verify the paths are the expected ones
            let pathVertexSets = Set(paths.map { Set($0.vertices.map { graph[$0].label }) })
            let expectedPath1 = Set(["A", "B", "D"])
            let expectedPath2 = Set(["A", "C", "D"])

            #expect(pathVertexSets.contains(expectedPath1))
            #expect(pathVertexSets.contains(expectedPath2))
        }

        @Test func threeEqualPaths() {
            let graph = createThreeEqualPathsGraph()

            let a = graph.findVertex(labeled: "A")!
            let c = graph.findVertex(labeled: "C")!

            let paths = graph.allShortestPaths(from: a, to: c, weight: .property(\.weight))

            #expect(paths.count == 3)

            // All paths should have cost 2
            for path in paths {
                let cost = path.edges.reduce(0.0) { sum, edge in
                    sum + graph[edge].weight
                }
                #expect(cost == 2.0)
            }
        }

        @Test func singlePath() {
            let graph = createLinearGraph()

            let a = graph.findVertex(labeled: "A")!
            let c = graph.findVertex(labeled: "C")!

            let paths = graph.allShortestPaths(from: a, to: c, weight: .property(\.weight))

            #expect(paths.count == 1)

            let path = paths[0]
            #expect(path.vertices.count == 3)
            #expect(path.edges.count == 2)

            let cost = path.edges.reduce(0.0) { sum, edge in
                sum + graph[edge].weight
            }
            #expect(cost == 5.0)
        }

        @Test func noPathReturnsEmpty() {
            let graph = createDisconnectedGraph()

            let a = graph.findVertex(labeled: "A")!
            let b = graph.findVertex(labeled: "B")!

            let paths = graph.allShortestPaths(from: a, to: b, weight: .property(\.weight))

            #expect(paths.isEmpty)
        }

        @Test func onlyShortestPathsReturned() {
            let graph = createDiamondGraphDifferentCosts()

            let a = graph.findVertex(labeled: "A")!
            let d = graph.findVertex(labeled: "D")!

            let paths = graph.allShortestPaths(from: a, to: d, weight: .property(\.weight))

            // Should only return the path with cost 2 (A -> B -> D), not the path with cost 4
            #expect(paths.count == 1)

            let path = paths[0]
            let cost = path.edges.reduce(0.0) { sum, edge in
                sum + graph[edge].weight
            }
            #expect(cost == 2.0)
        }

        @Test func selfPath() {
            let graph = createLinearGraph()

            let a = graph.findVertex(labeled: "A")!

            let paths = graph.allShortestPaths(from: a, to: a, weight: .property(\.weight))

            // Path from a vertex to itself
            #expect(paths.count == 1)
            #expect(paths[0].vertices.count == 1)
            #expect(paths[0].edges.isEmpty)
        }

        @Test func backtrackingDijkstraDirectly() {
            let graph = createMultipleEqualPathsGraph()

            let a = graph.findVertex(labeled: "A")!
            let d = graph.findVertex(labeled: "D")!

            let algorithm = BacktrackingDijkstra(on: graph, edgeWeight: .property(\.weight))
            let result = algorithm.findAllShortestPaths(from: a, to: d, visitor: nil)

            #expect(result.paths.count == 2)
            #expect(result.optimalCost == 3.0)
            #expect(result.source == a)
            #expect(result.destination == d)
        }

        @Test func withAlgorithmParameter() {
            let graph = createMultipleEqualPathsGraph()

            let a = graph.findVertex(labeled: "A")!
            let d = graph.findVertex(labeled: "D")!

            let paths = graph.allShortestPaths(
                from: a,
                to: d,
                using: .backtrackingDijkstra(weight: .property(\.weight))
            )

            #expect(paths.count == 2)
        }

        @Test func complexGraph() {
            // Create a more complex graph with multiple intersecting paths
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            let e = graph.addVertex { $0.label = "E" }
            let f = graph.addVertex { $0.label = "F" }

            // Create a graph with multiple shortest paths
            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: a, to: c) { $0.weight = 1 }
            graph.addEdge(from: b, to: d) { $0.weight = 1 }
            graph.addEdge(from: c, to: d) { $0.weight = 1 }
            graph.addEdge(from: d, to: e) { $0.weight = 1 }
            graph.addEdge(from: d, to: f) { $0.weight = 1 }
            graph.addEdge(from: e, to: f) { $0.weight = 0 }

            let paths = graph.allShortestPaths(from: a, to: f, weight: .property(\.weight))

            // Should find multiple paths with cost 3
            #expect(paths.count > 1)

            for path in paths {
                let cost = path.edges.reduce(0.0) { sum, edge in
                    sum + graph[edge].weight
                }
                #expect(cost == 3.0)
            }
        }

        // MARK: - Until-based API

        @Test func untilConditionWithMultipleEqualPaths() {
            let graph = createMultipleEqualPathsGraph()

            let a = graph.findVertex(labeled: "A")!

            // Find all shortest paths until we reach vertex D
            let paths = graph.allShortestPaths(
                from: a,
                until: { vertex in
                    graph[vertex].label == "D"
                },
                weight: .property(\.weight)
            )

            #expect(paths.count == 2)

            // Both paths should have cost 3
            for path in paths {
                let cost = path.edges.reduce(0.0) { sum, edge in
                    sum + graph[edge].weight
                }
                #expect(cost == 3.0)
                #expect(graph[path.destination].label == "D")
            }

            // Verify the paths are the expected ones
            let pathVertexSets = Set(paths.map { Set($0.vertices.map { graph[$0].label }) })
            let expectedPath1 = Set(["A", "B", "D"])
            let expectedPath2 = Set(["A", "C", "D"])

            #expect(pathVertexSets.contains(expectedPath1))
            #expect(pathVertexSets.contains(expectedPath2))
        }

        @Test func untilConditionWithSinglePath() {
            let graph = createLinearGraph()

            let a = graph.findVertex(labeled: "A")!

            // Find shortest path until we reach vertex C
            let paths = graph.allShortestPaths(
                from: a,
                until: { vertex in
                    graph[vertex].label == "C"
                },
                weight: .property(\.weight)
            )

            #expect(paths.count == 1)

            let path = paths[0]
            #expect(path.vertices.count == 3)
            #expect(path.edges.count == 2)
            #expect(graph[path.destination].label == "C")

            let cost = path.edges.reduce(0.0) { sum, edge in
                sum + graph[edge].weight
            }
            #expect(cost == 5.0)
        }

        @Test func untilConditionWithNoMatchingVertex() {
            let graph = createLinearGraph()

            let a = graph.findVertex(labeled: "A")!

            // Find shortest path until we reach a vertex that doesn't exist
            let paths = graph.allShortestPaths(
                from: a,
                until: { vertex in
                    graph[vertex].label == "Z"
                },
                weight: .property(\.weight)
            )

            #expect(paths.isEmpty)
        }

        @Test func untilConditionWithSelf() {
            let graph = createLinearGraph()

            let a = graph.findVertex(labeled: "A")!

            // Find shortest path until we reach the source vertex itself
            let paths = graph.allShortestPaths(
                from: a,
                until: { vertex in
                    vertex == a
                },
                weight: .property(\.weight)
            )

            #expect(paths.count == 1)
            #expect(paths[0].vertices.count == 1)
            #expect(paths[0].edges.isEmpty)
            #expect(paths[0].destination == a)
        }

        @Test func untilConditionWithComplexGraph() {
            // Create a graph where we want to find paths until we reach any vertex with label "D" or "E"
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            let e = graph.addVertex { $0.label = "E" }

            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: a, to: c) { $0.weight = 2 }
            graph.addEdge(from: b, to: d) { $0.weight = 1 }
            graph.addEdge(from: c, to: e) { $0.weight = 1 }

            let paths = graph.allShortestPaths(
                from: a,
                until: { vertex in
                    let label = graph[vertex].label
                    return label == "D" || label == "E"
                },
                weight: .property(\.weight)
            )

            // Should find paths to both D and E, but only the shortest ones
            #expect(paths.count >= 1)

            for path in paths {
                let cost = path.edges.reduce(0.0) { sum, edge in
                    sum + graph[edge].weight
                }
                let destinationLabel = graph[path.destination].label
                #expect(destinationLabel == "D" || destinationLabel == "E")

                // All paths should have the same minimum cost
                if destinationLabel == "D" {
                    #expect(cost == 2.0)  // A -> B -> D
                } else if destinationLabel == "E" {
                    #expect(cost == 3.0)  // A -> C -> E
                }
            }
        }

        @Test func backtrackingDijkstraUntilDirectly() {
            let graph = createMultipleEqualPathsGraph()

            let a = graph.findVertex(labeled: "A")!

            let algorithm = BacktrackingDijkstra(on: graph, edgeWeight: .property(\.weight))
            let result = algorithm.findAllShortestPaths(
                from: a,
                until: { vertex in
                    graph[vertex].label == "D"
                },
                visitor: nil
            )

            #expect(result.paths.count == 2)
            #expect(result.optimalCost == 3.0)
            #expect(result.source == a)
            #expect(graph[result.destination].label == "D")
        }

        @Test func untilWithAlgorithmParameter() {
            let graph = createMultipleEqualPathsGraph()

            let a = graph.findVertex(labeled: "A")!

            let paths = graph.allShortestPaths(
                from: a,
                until: { vertex in graph[vertex].label == "D" },
                using: .backtrackingDijkstra(weight: .property(\.weight))
            )

            #expect(paths.count == 2)
        }

        // MARK: - Multi-Backend Coverage

        @Test func findsAllShortestPathsInDiamondGraph_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                // Diamond: a→b (w=1), b→d (w=1), a→c (w=1), c→d (w=1) — two equal-cost paths a→d
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                let c = graph.addVertex { $0.label = "C" }
                let d = graph.addVertex { $0.label = "D" }
                graph.addEdge(from: a, to: b) { $0.weight = 1 }
                graph.addEdge(from: b, to: d) { $0.weight = 1 }
                graph.addEdge(from: a, to: c) { $0.weight = 1 }
                graph.addEdge(from: c, to: d) { $0.weight = 1 }

                let paths = graph.allShortestPaths(from: a, to: d, weight: .property(\.weight))
                #expect(paths.count == 2, "[\(backend)] diamond graph has exactly 2 equal-cost paths a→d")
                for path in paths {
                    let cost = path.edges.reduce(0.0) { $0 + graph[$1].weight }
                    #expect(cost == 2.0, "[\(backend)] each path costs 1+1=2")
                }
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

        @Test func returnsOnlyOptimalPaths_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                // Diamond with unequal costs: a→b (w=1), b→d (w=1), a→c (w=3), c→d (w=1)
                // Optimal: a→b→d (cost 2); suboptimal: a→c→d (cost 4)
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                let c = graph.addVertex { $0.label = "C" }
                let d = graph.addVertex { $0.label = "D" }
                graph.addEdge(from: a, to: b) { $0.weight = 1 }
                graph.addEdge(from: b, to: d) { $0.weight = 1 }
                graph.addEdge(from: a, to: c) { $0.weight = 3 }
                graph.addEdge(from: c, to: d) { $0.weight = 1 }

                let paths = graph.allShortestPaths(from: a, to: d, weight: .property(\.weight))
                #expect(paths.count == 1, "[\(backend)] only the cost-2 path is returned, not the cost-4 path")
                let cost = paths.first.map { $0.edges.reduce(0.0) { $0 + graph[$1].weight } }
                #expect(cost == 2.0, "[\(backend)] optimal path a→b→d costs 2")
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

        /// `BacktrackingDijkstra.Visitor` fires `pathFound` once per complete shortest path discovered,
        /// and `examineVertex` once per vertex examined during the search.
        /// Two composed visitors must each receive the same events.
        @Test func composedVisitorsReceiveAllEvents() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            // Two equal-cost paths a→b→d and a→c→d (cost 2 each)
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: d) { $0.weight = 1.0 }
            graph.addEdge(from: a, to: c) { $0.weight = 1.0 }
            graph.addEdge(from: c, to: d) { $0.weight = 1.0 }

            var pathsFound1 = 0
            var pathsFound2 = 0
            var examined1 = 0
            var examined2 = 0

            var v1 = BacktrackingDijkstra<DefaultAdjacencyList, Double>.Visitor()
            v1.pathFound = { _, _ in pathsFound1 += 1 }
            v1.examineVertex = { _ in examined1 += 1 }

            var v2 = BacktrackingDijkstra<DefaultAdjacencyList, Double>.Visitor()
            v2.pathFound = { _, _ in pathsFound2 += 1 }
            v2.examineVertex = { _ in examined2 += 1 }

            let combined = v1.combined(with: v2)
            let algorithm = BacktrackingDijkstra(on: graph, edgeWeight: .property(\.weight))
            _ = algorithm.findAllShortestPaths(from: a, until: { $0 == d }, visitor: combined)

            #expect(pathsFound1 == 2, "two equal-cost paths a→b→d and a→c→d must each fire pathFound")
            #expect(pathsFound2 == 2)
            #expect(examined1 >= 1, "at least the source vertex must be examined")
            #expect(examined2 >= 1)
            #expect(pathsFound1 == pathsFound2, "both composed visitors must see the same paths")
            #expect(examined1 == examined2, "both composed visitors must see identical examineVertex events")
        }
    }
#endif
