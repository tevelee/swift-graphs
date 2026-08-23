#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
    @testable import Graphs
    import Testing

    struct BestFirstSearchTests {

        // MARK: - Core Behavior

        @Test func greedyBestFirst_OrdersByHeuristic() {
            var graph = AdjacencyList()
            graph.addEdges(providing: \.label) {
                ("s", "a")
                ("s", "b")
                ("a", "c")
                ("b", "d")
            }

            // Heuristic that favors 'b' branch first
            let order: [String: UInt] = ["s": 0, "b": 1, "d": 2, "a": 3, "c": 4]
            let result = graph.traverse(
                from: "s",
                using: .bestFirst(
                    heuristic: .init { v, g in
                        order[g[v].label] ?? 999
                    }
                )
            )

            let labels = result.vertexLabels(in: graph)
            #expect(labels == ["s", "b", "d", "a", "c"])
        }

        // MARK: - Scenarios

        @Test func doesNotCrossComponentBoundary() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            _ = graph.addVertex { $0.label = "B" }  // isolated, not reachable from A

            let result = graph.traverse(from: a, using: .bestFirst(heuristic: .uniform(0)))
            #expect(result.vertices.count == 1, "best-first must not cross disconnected component")
        }

        @Test func uniformHeuristicVisitsAllReachableVertices() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: a, to: c)
            let result = graph.traverse(from: a, using: .bestFirst(heuristic: .uniform(0)))
            #expect(result.vertices.count == 3)
        }

        // MARK: - Multi-Backend Coverage

        @Test func visitsAllReachableVertices_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                let c = graph.addVertex { $0.label = "C" }
                let isolated = graph.addVertex { $0.label = "X" }
                graph.addEdge(from: a, to: b)
                graph.addEdge(from: b, to: c)
                let result = graph.traverse(from: a, using: .bestFirst(heuristic: .uniform(0)))
                #expect(result.vertices.count == 3, "[\(backend)] must visit all 3 reachable vertices")
                #expect(!result.vertices.contains(isolated), "[\(backend)] must not cross component boundary")
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

        @Test func differentHeuristicsProduceDifferentOrders() {
            var graph = AdjacencyList()
            let root = graph.addVertex { $0.label = "root" }
            let lo = graph.addVertex { $0.label = "lo" }
            let hi = graph.addVertex { $0.label = "hi" }
            graph.addEdge(from: root, to: lo)
            graph.addEdge(from: root, to: hi)

            // Heuristic 1: lo has lower priority → hi visited first
            let hiFirst = graph.traverse(
                from: root,
                using: .bestFirst(
                    heuristic: .init { v, g in
                        g[v].label == "lo" ? UInt(10) : UInt(0)
                    }
                )
            )

            // Heuristic 2: hi has lower priority → lo visited first
            let loFirst = graph.traverse(
                from: root,
                using: .bestFirst(
                    heuristic: .init { v, g in
                        g[v].label == "hi" ? UInt(10) : UInt(0)
                    }
                )
            )

            let hiFirstLabels = hiFirst.vertexLabels(in: graph)
            let loFirstLabels = loFirst.vertexLabels(in: graph)

            // Both should visit all vertices; only order differs
            #expect(Set(hiFirstLabels) == Set(loFirstLabels))
            #expect(hiFirstLabels != loFirstLabels, "different heuristics should produce different visit orders")
        }

        // MARK: - Observation Support

        /// `BestFirstTraversal` delegates to A* and forwards its observation to the sequence.
        /// Two composed observation groups receive `vertexExamined` for every explored vertex.
        @Test func composedObservationsReceiveAllEvents() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)

            var examined1 = 0
            var examined2 = 0

            let observed = BestFirstTraversal<AdjacencyList, Int>(heuristic: .uniform(0))
                .observing(AStar<AdjacencyList, Int, Int, Int>.EventCases.vertexExamined) { _ in
                    examined1 += 1
                }
                .observing(AStar<AdjacencyList, Int, Int, Int>.EventCases.vertexExamined) { _ in
                    examined2 += 1
                }
            _ = observed.traverse(from: a, in: graph, observation: nil)

            #expect(examined1 == 3, "all 3 vertices in chain a→b→c must be examined")
            #expect(examined2 == 3)
            #expect(examined1 == examined2, "both observation groups receive identical vertexExamined events")
        }
    }
#endif
