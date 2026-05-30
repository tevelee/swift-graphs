#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    @testable import Graphs
    import Testing

    struct AllPathsTests {

        func createDiamondGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            let d = graph.addVertex { $0.label = "d" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: d)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: c, to: d)
            graph.addEdge(from: a, to: d)

            return graph
        }

        @Test func findsAllPathsInDiamondGraph() {
            let graph = createDiamondGraph()
            let a = graph.findVertex(labeled: "a")!
            let d = graph.findVertex(labeled: "d")!

            let paths = Array(graph.allPaths(from: a, to: d))

            #expect(paths.count == 3)

            let pathsVertices = paths.map { $0.vertices.map { graph[$0].label } }
            let expectedPaths = [
                ["a", "b", "d"],
                ["a", "c", "d"],
                ["a", "d"],
            ]

            for expected in expectedPaths {
                #expect(pathsVertices.contains(where: { $0 == expected }))
            }
        }

        func createCyclicGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)

            return graph
        }

        @Test func findsAllPathsInCyclicGraph() {
            let graph = createCyclicGraph()
            let a = graph.findVertex(labeled: "a")!
            let c = graph.findVertex(labeled: "c")!

            let paths = Array(graph.allPaths(from: a, to: c))

            #expect(paths.count == 1)
            #expect(paths[0].vertices.map { graph[$0].label } == ["a", "b", "c"])
        }

        func createNoPathGraph() -> some AdjacencyListProtocol {
            var graph = AdjacencyList()
            _ = graph.addVertex { $0.label = "a" }
            _ = graph.addVertex { $0.label = "b" }

            return graph
        }

        @Test func findsNoPathsWhenDisconnected() {
            let graph = createNoPathGraph()
            let a = graph.findVertex(labeled: "a")!
            let b = graph.findVertex(labeled: "b")!

            let paths = Array(graph.allPaths(from: a, to: b))

            #expect(paths.isEmpty)
        }

        // MARK: - Multi-Backend Coverage

        @Test func findsCorrectPathCount_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                // Diamond graph: a→b→d and a→c→d and a→d (direct)
                let a = graph.addVertex { $0.label = "a" }
                let b = graph.addVertex { $0.label = "b" }
                let c = graph.addVertex { $0.label = "c" }
                let d = graph.addVertex { $0.label = "d" }
                graph.addEdge(from: a, to: b)
                graph.addEdge(from: b, to: d)
                graph.addEdge(from: a, to: c)
                graph.addEdge(from: c, to: d)
                graph.addEdge(from: a, to: d)

                let paths = Array(graph.allPaths(from: a, to: d))
                #expect(paths.count == 3, "[\(backend)] diamond graph has exactly 3 simple paths a→d")
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

        @Test func sourceEqualDestinationNoSelfLoop_returnsNoPaths_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                let a = graph.addVertex { $0.label = "a" }
                // When source == destination and there is no self-loop, the DFS algorithm
                // does not emit a trivial path — it only emits paths found via outgoing edges.
                let paths = Array(graph.allPaths(from: a, to: a))
                #expect(paths.isEmpty, "[\(backend)] no path from a to a when there is no self-loop")
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

        @Test func sourceEqualDestinationWithSelfLoop_returnsOnePath_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                let a = graph.addVertex { $0.label = "a" }
                graph.addEdge(from: a, to: a)
                // With a self-loop, allPaths(from: a, to: a) finds the one-edge cycle a→a.
                let paths = Array(graph.allPaths(from: a, to: a))
                #expect(paths.count == 1, "[\(backend)] self-loop yields exactly one path a→a")
                #expect(paths.first?.vertices.count == 2, "[\(backend)] path a→a visits 'a' twice")
                #expect(paths.first?.edges.count == 1, "[\(backend)] path uses the self-loop edge")
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
