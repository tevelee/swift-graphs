#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    @testable import Graphs
    import Testing

    struct SPFATests {

        // MARK: - Core Behavior

        @Test func basicShortestPath() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = 3 }

            let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

            #expect(result.distances[a] == .finite(0.0))
            #expect(result.distances[b] == .finite(2.0))
            #expect(result.distances[c] == .finite(5.0))
            #expect(result.hasNegativeCycle == false)
        }

        @Test func negativeWeightEdges() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = -1 }

            let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

            #expect(result.distances[c] == .finite(1.0))  // A -> B -> C (2 + (-1) = 1)
            #expect(result.hasNegativeCycle == false)
        }

        @Test func negativeCycleDetection() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: b, to: c) { $0.weight = 1 }
            graph.addEdge(from: c, to: a) { $0.weight = -3 }  // Creates negative cycle

            let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

            #expect(result.hasNegativeCycle == true)
        }

        @Test func disconnectedGraph() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            // No edges between A and B

            let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

            #expect(result.distances[a] == .finite(0.0))
            #expect(result.distances[b] == .infinite)
            #expect(result.hasNegativeCycle == false)
        }

        @Test func singleVertex() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }

            let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

            #expect(result.distances[a] == .finite(0.0))
            #expect(result.hasNegativeCycle == false)
        }

        // MARK: - Path Reconstruction

        @Test func pathReconstruction() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = 3 }

            let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))
            let path = result.path(from: a, to: c, in: graph)

            #expect(path != nil)
            #expect(path?.source == a)
            #expect(path?.destination == c)
            #expect(path?.vertices.count == 3)
            #expect(path?.edges.count == 2)
        }

        @Test func pathReconstructionWithNegativeWeights() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: b, to: c) { $0.weight = -2 }
            graph.addEdge(from: a, to: c) { $0.weight = 3 }

            let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))
            let path = result.path(from: a, to: c, in: graph)

            #expect(path != nil)
            #expect(path?.vertices.count == 3)  // A -> B -> C is shorter than A -> C
        }

        @Test func pathReconstructionReturnsNilForNegativeCycle() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: b, to: c) { $0.weight = 1 }
            graph.addEdge(from: c, to: a) { $0.weight = -3 }

            let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))
            let path = result.path(from: a, to: c, in: graph)

            #expect(result.hasNegativeCycle == true)
            #expect(path == nil)
        }

        @Test func multiplePathsPicksOptimal() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            // Path 1: A -> B -> D (cost 10)
            graph.addEdge(from: a, to: b) { $0.weight = 3 }
            graph.addEdge(from: b, to: d) { $0.weight = 7 }

            // Path 2: A -> C -> D (cost 5)
            graph.addEdge(from: a, to: c) { $0.weight = 1 }
            graph.addEdge(from: c, to: d) { $0.weight = 4 }

            let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

            #expect(result.distances[d] == .finite(5.0))  // Picks the shorter A -> C -> D path
        }

        // MARK: - Multi-Backend Coverage

        @Test func shortestPath_allBackends() {
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

                let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

                #expect(result.distances[a] == .finite(0.0), "[\(backend)] distance to source is 0")
                #expect(result.distances[b] == .finite(2.0), "[\(backend)] a→b costs 2")
                #expect(result.distances[c] == .finite(5.0), "[\(backend)] a→b→c (5) cheaper than a→c (10)")
                #expect(result.hasNegativeCycle == false, "[\(backend)] no negative cycle in this graph")
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

        @Test func visitorCallbacks() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }

            graph.addEdge(from: a, to: b) { $0.weight = 2 }

            var examinedVertices: [String] = []
            var relaxedEdgeCount = 0

            let spfa = SPFA(on: graph, edgeWeight: .property(\.weight))
            _ = spfa.shortestPathsFromSource(
                a,
                visitor: .init(
                    examineVertex: { vertex in
                        examinedVertices.append(graph[vertex].label)
                    },
                    edgeRelaxed: { _ in
                        relaxedEdgeCount += 1
                    }
                )
            )

            #expect(examinedVertices.contains("A"))
            #expect(examinedVertices.contains("B"))
            #expect(relaxedEdgeCount == 1)
        }

        @Test func negativeCycleVisitorCallback() {
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: b, to: c) { $0.weight = 1 }
            graph.addEdge(from: c, to: a) { $0.weight = -3 }

            var negativeCycleDetected = false

            let spfa = SPFA(on: graph, edgeWeight: .property(\.weight))
            let result = spfa.shortestPathsFromSource(
                a,
                visitor: .init(
                    detectNegativeCycle: { _ in
                        negativeCycleDetected = true
                    }
                )
            )

            #expect(result.hasNegativeCycle == true)
            #expect(negativeCycleDetected == true)
        }

        /// Exercises all five SPFA visitor events through a composed visitor pair.
        ///
        /// Graph: a→b(1), a→c(1), b→c(5) — c settles via a→c (cost 1), not b→c (cost 6).
        /// - `examineVertex` fires for a, b, c as they are dequeued.
        /// - `examineEdge` fires for each of the 3 edges.
        /// - `edgeRelaxed` fires for a→b and a→c.
        /// - `edgeNotRelaxed` fires for b→c (c already at cost 1; b→c would be 6).
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

            var v1 = SPFA<DefaultAdjacencyList, Double>.Visitor()
            v1.examineVertex = { _ in examined1 += 1 }
            v1.examineEdge = { _ in examEdge1 += 1 }
            v1.edgeRelaxed = { _ in relaxed1 += 1 }
            v1.edgeNotRelaxed = { _ in notRelaxed1 += 1 }

            var v2 = SPFA<DefaultAdjacencyList, Double>.Visitor()
            v2.examineVertex = { _ in examined2 += 1 }
            v2.examineEdge = { _ in examEdge2 += 1 }
            v2.edgeRelaxed = { _ in relaxed2 += 1 }
            v2.edgeNotRelaxed = { _ in notRelaxed2 += 1 }

            let combined = v1.combined(with: v2)
            _ = SPFA(on: graph, edgeWeight: .property(\.weight)).shortestPathsFromSource(a, visitor: combined)

            #expect(examined1 >= 1, "examineVertex fires as vertices are dequeued")
            #expect(examined2 >= 1)
            #expect(examEdge1 == 3, "examineEdge fires for all 3 edges")
            #expect(examEdge2 == 3)
            #expect(relaxed1 == 2, "a→b and a→c both improve their targets")
            #expect(relaxed2 == 2)
            #expect(notRelaxed1 >= 1, "b→c does not improve c (already at cost 1)")
            #expect(notRelaxed2 >= 1)
            // Both composed visitors must see identical event counts
            #expect(examined1 == examined2)
            #expect(examEdge1 == examEdge2)
            #expect(relaxed1 == relaxed2)
            #expect(notRelaxed1 == notRelaxed2)
        }

        /// Ensures the `detectNegativeCycle` event propagates through composed visitors.
        ///
        /// Graph: a→b(1), b→c(-3), c→a(1) forms a negative cycle (total weight: -1).
        /// The composed visitor's `detectNegativeCycle` closure must fire for both observers.
        @Test func composedVisitors_detectNegativeCycleEvent() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = -3.0 }
            graph.addEdge(from: c, to: a) { $0.weight = 1.0 }

            var detected1 = 0
            var detected2 = 0

            var v1 = SPFA<DefaultAdjacencyList, Double>.Visitor()
            v1.detectNegativeCycle = { _ in detected1 += 1 }

            var v2 = SPFA<DefaultAdjacencyList, Double>.Visitor()
            v2.detectNegativeCycle = { _ in detected2 += 1 }

            let combined = v1.combined(with: v2)
            _ = SPFA(on: graph, edgeWeight: .property(\.weight)).shortestPathsFromSource(a, visitor: combined)

            #expect(detected1 >= 1, "detectNegativeCycle must fire through composed visitor v1")
            #expect(detected2 >= 1, "detectNegativeCycle must fire through composed visitor v2")
            #expect(detected1 == detected2, "both composed observers see the same detection events")
        }
    }

#endif
