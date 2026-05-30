#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    @testable import Graphs
    import Testing

    struct KShortestPathsTests {

        // MARK: - Core Behavior

        @Test func yenFindsShortestPath() throws {
            var graph = AdjacencyList()

            // Create a simple test graph: A -> B -> C
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = 3 }

            let paths = graph.kShortestPaths(from: a, to: c, k: 3, using: .yen(weight: .property(\.weight)))

            #expect(paths.count == 1)

            // First path should be the shortest
            let firstPath = try #require(paths.first)
            #expect(firstPath.vertices.count == 3)
            #expect(firstPath.vertices.first == a)
            #expect(firstPath.vertices.last == c)
        }

        @Test func yenFindsMultiplePaths() {
            var graph = AdjacencyList()

            // Create a graph with multiple paths from A to D
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            // Path 1: A -> B -> D (weight 3)
            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: b, to: d) { $0.weight = 2 }

            // Path 2: A -> C -> D (weight 4)
            graph.addEdge(from: a, to: c) { $0.weight = 2 }
            graph.addEdge(from: c, to: d) { $0.weight = 2 }

            // Path 3: A -> B -> C -> D (weight 5)
            graph.addEdge(from: b, to: c) { $0.weight = 2 }

            let paths = graph.kShortestPaths(from: a, to: d, k: 3, using: .yen(weight: .property(\.weight)))

            #expect(paths.count >= 1)

            // Verify paths are in order of increasing cost
            for i in 0 ..< (paths.count - 1) {
                let currentPath = paths[i]
                let nextPath = paths[i + 1]

                // Calculate total cost for each path
                let currentCost = calculatePathCost(currentPath, in: graph)
                let nextCost = calculatePathCost(nextPath, in: graph)

                #expect(currentCost <= nextCost)
            }
        }

        @Test func yenWithSingleAvailablePath() throws {
            var graph = AdjacencyList()

            // Create a graph with only one path
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: b, to: c) { $0.weight = 2 }

            let paths = graph.kShortestPaths(from: a, to: c, k: 5, using: .yen(weight: .property(\.weight)))

            #expect(paths.count == 1)
            let path = try #require(paths.first)
            #expect(path.vertices.count == 3)
            #expect(path.vertices.first == a)
            #expect(path.vertices.last == c)
        }

        @Test func yenReturnsEmptyWhenNoPath() {
            var graph = AdjacencyList()

            // Create disconnected components
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: c, to: d) { $0.weight = 2 }
            // No connection between A-B and C-D components

            let paths = graph.kShortestPaths(from: a, to: d, k: 3, using: .yen(weight: .property(\.weight)))

            #expect(paths.count == 0)
        }

        @Test func yenHandlesSameSourceAndDestination() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }

            graph.addEdge(from: a, to: b) { $0.weight = 1 }

            let paths = graph.kShortestPaths(from: a, to: a, k: 3, using: .yen(weight: .property(\.weight)))

            #expect(paths.count == 0)
        }

        @Test func yenWithKExceedingAvailablePaths() {
            var graph = AdjacencyList()

            // Create a graph with only one path
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: b, to: c) { $0.weight = 2 }

            let paths = graph.kShortestPaths(from: a, to: c, k: 10, using: .yen(weight: .property(\.weight)))

            #expect(paths.count == 1)  // Only one path available
        }

        // MARK: - Multi-Backend Coverage

        @Test func shortestPathCount_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable, G.EdgeDescriptor: Hashable
            {
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                let c = graph.addVertex { $0.label = "C" }
                let d = graph.addVertex { $0.label = "D" }
                // Two paths a→d: via b (1+2=3) and via c (4+1=5)
                graph.addEdge(from: a, to: b) { $0.weight = 1 }
                graph.addEdge(from: b, to: d) { $0.weight = 2 }
                graph.addEdge(from: a, to: c) { $0.weight = 4 }
                graph.addEdge(from: c, to: d) { $0.weight = 1 }

                let paths = graph.kShortestPaths(from: a, to: d, k: 3, using: .yen(weight: .property(\.weight)))

                #expect(paths.count == 2, "[\(backend)] exactly 2 simple paths from a to d")
                // Paths must be returned in ascending cost order
                if paths.count == 2 {
                    let cost1 = paths[0].edges.reduce(0.0) { $0 + graph[$1].weight }
                    let cost2 = paths[1].edges.reduce(0.0) { $0 + graph[$1].weight }
                    #expect(cost1 <= cost2, "[\(backend)] paths must be in ascending cost order")
                    #expect(cost1 == 3.0, "[\(backend)] cheapest path a→b→d costs 3")
                    #expect(cost2 == 5.0, "[\(backend)] second path a→c→d costs 5")
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

        // MARK: - Visitor Support

        @Test func composedVisitorsReceiveAllEvents() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: b, to: c) { $0.weight = 2 }

            var pathsFound1 = 0
            var pathsFound2 = 0

            let v1 = Yen<DefaultAdjacencyList, Double>.Visitor(
                onPathFound: { _ in pathsFound1 += 1 }
            )
            let v2 = Yen<DefaultAdjacencyList, Double>.Visitor(
                onPathFound: { _ in pathsFound2 += 1 }
            )

            let combined = v1.combined(with: v2)
            let paths = Yen<DefaultAdjacencyList, Double>(edgeWeight: .property(\.weight))
                .kShortestPaths(from: a, to: c, k: 3, in: graph, visitor: combined)

            #expect(paths.count == 1)  // only one simple path: a→b→c
            #expect(pathsFound1 == 1)
            #expect(pathsFound2 == 1)
            #expect(pathsFound1 == pathsFound2)
        }

        private func calculatePathCost<Graph: IncidenceGraph & EdgePropertyGraph>(
            _ path: Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>,
            in graph: Graph
        ) -> Double where Graph.VertexDescriptor: Hashable {
            var totalCost = 0.0
            for edge in path.edges {
                let weight = graph[edge].weight
                totalCost += weight
            }
            return totalCost
        }
    }
#endif
