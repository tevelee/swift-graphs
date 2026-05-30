#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
    @testable import Graphs
    import Testing

    struct VertexOrderingTests {

        // MARK: - Core Behavior (Smallest Last)

        @Test func smallestLastOrderingSimpleGraph() {
            // Create a simple graph: A-B-C with A-D
            // A -- B -- C
            // |
            // D
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: a, to: d)
            graph.addEdge(from: d, to: a)

            let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())

            // Verify all vertices are included
            #expect(ordering.orderedVertices.count == 4)
            #expect(ordering.orderedVertices == [b, a, d, c])

            // Verify deterministic ordering: vertices with degree 1 should come first
            // A has degree 2, B has degree 2, C has degree 1, D has degree 1
            // So C and D should be first (in some order), then A and B
            let cPosition = ordering.position(of: c)!
            let dPosition = ordering.position(of: d)!
            let aPosition = ordering.position(of: a)!
            let bPosition = ordering.position(of: b)!

            // The algorithm removes vertices with smallest degree first, so they appear last in the final ordering
            // This means degree-1 vertices should appear later in the ordering
            #expect(cPosition > aPosition || cPosition > bPosition)
            #expect(dPosition > aPosition || dPosition > bPosition)
        }

        @Test func smallestLastOrderingCompleteGraph() {
            // Create a complete graph K4
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            // Add all possible edges
            let vertices = [a, b, c, d]
            for i in 0 ..< vertices.count {
                for j in (i + 1) ..< vertices.count {
                    graph.addEdge(from: vertices[i], to: vertices[j])
                    graph.addEdge(from: vertices[j], to: vertices[i])
                }
            }

            let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())

            // Verify all vertices are included
            #expect(ordering.orderedVertices.count == 4)
            #expect(ordering.orderedVertices == [d, c, b, a])
        }

        @Test func smallestLastOrderingPathGraph() {
            // Create a path graph: A-B-C-D
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: c, to: d)
            graph.addEdge(from: d, to: c)

            let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())

            // Verify all vertices are included
            #expect(ordering.orderedVertices.count == 4)
            #expect(ordering.orderedVertices == [c, b, d, a])
        }

        @Test func smallestLastOrderingStarGraph() {
            // Create a star graph: center connected to all others
            //   B
            //   |
            // A-C-D
            //   |
            //   E
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            let e = graph.addVertex { $0.label = "E" }

            graph.addEdge(from: c, to: a)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: d)
            graph.addEdge(from: d, to: c)
            graph.addEdge(from: c, to: e)
            graph.addEdge(from: e, to: c)

            let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())

            // Verify all vertices are included
            #expect(ordering.orderedVertices.count == 5)
            #expect(ordering.orderedVertices == [c, e, d, b, a])
        }

        // MARK: - Core Behavior (Reverse Cuthill-McKee)

        @Test func reverseCuthillMcKeeOrderingSimpleGraph() {
            // Create a simple graph: A-B-C with A-D
            // A -- B -- C
            // |
            // D
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: a, to: d)
            graph.addEdge(from: d, to: a)

            let ordering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

            // Verify all vertices are included
            #expect(ordering.orderedVertices.count == 4)
            #expect(ordering.orderedVertices == [c, b, d, a])
        }

        @Test func reverseCuthillMcKeeOrderingPathGraph() {
            // Create a path graph: A-B-C-D
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: c, to: d)
            graph.addEdge(from: d, to: c)

            let ordering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

            // Verify all vertices are included
            #expect(ordering.orderedVertices.count == 4)
            #expect(ordering.orderedVertices == [d, c, b, a])
        }

        @Test func reverseCuthillMcKeeOrderingStarGraph() {
            // Create a star graph: center connected to all others
            //   B
            //   |
            // A-C-D
            //   |
            //   E
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            let e = graph.addVertex { $0.label = "E" }

            graph.addEdge(from: c, to: a)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: d)
            graph.addEdge(from: d, to: c)
            graph.addEdge(from: c, to: e)
            graph.addEdge(from: e, to: c)

            let ordering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

            // Verify all vertices are included
            #expect(ordering.orderedVertices.count == 5)
            #expect(ordering.orderedVertices == [e, d, b, c, a])
        }

        @Test func reverseCuthillMcKeeOrderingCompleteGraph() {
            // Create a complete graph K4
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            // Add all possible edges
            let vertices = [a, b, c, d]
            for i in 0 ..< vertices.count {
                for j in (i + 1) ..< vertices.count {
                    graph.addEdge(from: vertices[i], to: vertices[j])
                    graph.addEdge(from: vertices[j], to: vertices[i])
                }
            }

            let ordering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

            // Verify all vertices are included
            #expect(ordering.orderedVertices.count == 4)
            #expect(ordering.orderedVertices == [d, c, b, a])
        }

        // MARK: - Edge Cases

        @Test func emptyGraph() {
            let graph = AdjacencyList()

            let smallestLastOrdering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
            let rcmOrdering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

            #expect(smallestLastOrdering.orderedVertices.isEmpty)
            #expect(rcmOrdering.orderedVertices.isEmpty)
        }

        @Test func singleVertexGraph() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }

            let smallestLastOrdering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
            let rcmOrdering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

            #expect(smallestLastOrdering.orderedVertices == [a])
            #expect(rcmOrdering.orderedVertices == [a])
        }

        @Test func twoVertexGraph() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)

            let smallestLastOrdering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
            let rcmOrdering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

            #expect(smallestLastOrdering.orderedVertices.count == 2)
            #expect(smallestLastOrdering.orderedVertices == [b, a])

            #expect(rcmOrdering.orderedVertices.count == 2)
            #expect(rcmOrdering.orderedVertices == [b, a])
        }

        @Test func disconnectedGraph() {
            // Create two disconnected components: A-B and C-D
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: c, to: d)
            graph.addEdge(from: d, to: c)

            let smallestLastOrdering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
            let rcmOrdering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

            // Verify all vertices are included
            #expect(smallestLastOrdering.orderedVertices.count == 4)
            #expect(smallestLastOrdering.orderedVertices == [d, c, b, a])

            #expect(rcmOrdering.orderedVertices.count == 4)
            #expect(rcmOrdering.orderedVertices == [d, c, b, a])
        }

        // MARK: - Deterministic Ordering

        @Test func deterministicOrdering() {
            // Test that multiple runs produce the same result
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: a, to: d)
            graph.addEdge(from: d, to: a)

            // Run multiple times and verify deterministic results
            let ordering1 = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
            let ordering2 = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
            let ordering3 = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())

            #expect(ordering1.orderedVertices == ordering2.orderedVertices)
            #expect(ordering2.orderedVertices == ordering3.orderedVertices)

            let rcm1 = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
            let rcm2 = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
            let rcm3 = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

            #expect(rcm1.orderedVertices == rcm2.orderedVertices)
            #expect(rcm2.orderedVertices == rcm3.orderedVertices)
        }

        @Test func orderingConsistency() {
            // Test that the ordering is consistent with vertex positions
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: a, to: d)
            graph.addEdge(from: d, to: a)

            let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())

            // Verify that position lookups are consistent
            for (index, vertex) in ordering.orderedVertices.enumerated() {
                #expect(ordering.position(of: vertex) == index)
                #expect(ordering.vertex(at: index) == vertex)
            }

            // Verify that all vertices have valid positions
            for vertex in [a, b, c, d] {
                let position = ordering.position(of: vertex)
                #expect(position != nil)
                #expect(position! >= 0)
                #expect(position! < ordering.orderedVertices.count)
            }
        }

        // MARK: - Complex Graphs

        @Test func complexGraphSmallestLast() {
            // Create a more complex graph with varying degrees
            //     B
            //    /|\
            //   A C D
            //    \|/
            //     E
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            let e = graph.addVertex { $0.label = "E" }

            // A connects to B and E
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: a, to: e)
            graph.addEdge(from: e, to: a)

            // B connects to A, C, D
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: b, to: d)
            graph.addEdge(from: d, to: b)

            // C connects to B and E
            graph.addEdge(from: c, to: e)
            graph.addEdge(from: e, to: c)

            // D connects to B and E
            graph.addEdge(from: d, to: e)
            graph.addEdge(from: e, to: d)

            let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())

            // Verify all vertices are included
            #expect(ordering.orderedVertices.count == 5)
            #expect(ordering.orderedVertices == [e, d, b, c, a])
        }

        @Test func complexGraphReverseCuthillMcKee() {
            // Create the same complex graph
            //     B
            //    /|\
            //   A C D
            //    \|/
            //     E
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            let e = graph.addVertex { $0.label = "E" }

            // A connects to B and E
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: a, to: e)
            graph.addEdge(from: e, to: a)

            // B connects to A, C, D
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: b, to: d)
            graph.addEdge(from: d, to: b)

            // C connects to B and E
            graph.addEdge(from: c, to: e)
            graph.addEdge(from: e, to: c)

            // D connects to B and E
            graph.addEdge(from: d, to: e)
            graph.addEdge(from: e, to: d)

            let ordering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

            // Verify all vertices are included
            #expect(ordering.orderedVertices.count == 5)
            #expect(ordering.orderedVertices == [d, c, e, b, a])
        }

        // MARK: - Multi-Backend Coverage

        @Test func orderingSpansAllVertices_allBackends() {
            func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
            where
                G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
                G.VertexDescriptor: Hashable
            {
                let a = graph.addVertex { $0.label = "A" }
                let b = graph.addVertex { $0.label = "B" }
                let c = graph.addVertex { $0.label = "C" }
                let d = graph.addVertex { $0.label = "D" }
                graph.addEdge(from: a, to: b)
                graph.addEdge(from: b, to: a)
                graph.addEdge(from: b, to: c)
                graph.addEdge(from: c, to: b)
                graph.addEdge(from: c, to: d)
                graph.addEdge(from: d, to: c)

                let slOrder = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
                let rcmOrder = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

                #expect(slOrder.orderedVertices.count == 4, "[\(backend)] Smallest Last must order all 4 vertices")
                #expect(rcmOrder.orderedVertices.count == 4, "[\(backend)] RCM must order all 4 vertices")

                // Both orderings must contain exactly the same vertex set
                #expect(
                    Set(slOrder.orderedVertices) == Set([a, b, c, d]),
                    "[\(backend)] Smallest Last must span all vertices"
                )
                #expect(
                    Set(rcmOrder.orderedVertices) == Set([a, b, c, d]),
                    "[\(backend)] RCM must span all vertices"
                )
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

        // MARK: - Algorithm Comparison

        @Test func algorithmComparison() {
            // Test that both algorithms produce valid orderings for the same graph
            var graph = AdjacencyList()

            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)
            graph.addEdge(from: a, to: d)
            graph.addEdge(from: d, to: a)

            let smallestLastOrdering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
            let rcmOrdering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())

            // Both should include all vertices
            #expect(smallestLastOrdering.orderedVertices.count == 4)
            #expect(rcmOrdering.orderedVertices.count == 4)

            // Both should include the same set of vertices
            #expect(smallestLastOrdering.orderedVertices == [b, a, d, c])
            #expect(rcmOrdering.orderedVertices == [c, b, d, a])

            // The orderings may be different, but both should be valid
            #expect(smallestLastOrdering.orderedVertices != rcmOrdering.orderedVertices)
        }

        // MARK: - Visitor Composition

        /// Verifies the SmallestLastVertexOrderingAlgorithm visitor composition semantics.
        ///
        /// **Important:** SmallestLastVertex uses "last-wins" composition (`other.cb ?? self.cb`),
        /// not the standard "both-fire" pattern used by most algorithm visitors. This means:
        /// - When `other` (v2) has a non-nil callback, `combined` uses v2's callback exclusively.
        /// - When `other` (v2) has a nil callback, `combined` falls back to v1's callback.
        ///
        /// This test exercises all three events (`examineVertex`, `removeVertex`, `updateDegree`)
        /// and verifies both branches of the `??` fall-through.
        @Test func smallestLastVertexComposedVisitorLastWins() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)

            // Scenario 1: both v1 and v2 set all events.
            // Combined should use v2's callbacks exclusively (other wins).
            var examV1 = 0
            var examV2 = 0

            var v1 = SmallestLastVertexOrderingAlgorithm<DefaultAdjacencyList>.Visitor()
            v1.examineVertex = { _ in examV1 += 1 }
            v1.removeVertex = { _, _ in examV1 += 1 }
            v1.updateDegree = { _, _, _ in examV1 += 1 }

            var v2 = SmallestLastVertexOrderingAlgorithm<DefaultAdjacencyList>.Visitor()
            v2.examineVertex = { _ in examV2 += 1 }
            v2.removeVertex = { _, _ in examV2 += 1 }
            v2.updateDegree = { _, _, _ in examV2 += 1 }

            let combined1 = v1.combined(with: v2)
            _ = SmallestLastVertexOrderingAlgorithm<DefaultAdjacencyList>()
                .orderVertices(in: graph, visitor: combined1)

            // "last wins": v2 overrides v1 for all events, so only v2's counters increment
            #expect(examV2 >= 1, "all events route to v2 (other) when v2 has non-nil callbacks")
            #expect(examV1 == 0, "v1 (self) callbacks are not called when v2 overrides them")

            // Scenario 2: only v1 sets events, v2 is empty.
            // Combined should fall back to v1's callbacks.
            var fallback = 0
            var vFallback = SmallestLastVertexOrderingAlgorithm<DefaultAdjacencyList>.Visitor()
            vFallback.examineVertex = { _ in fallback += 1 }
            vFallback.removeVertex = { _, _ in fallback += 1 }
            vFallback.updateDegree = { _, _, _ in fallback += 1 }

            let emptyV2 = SmallestLastVertexOrderingAlgorithm<DefaultAdjacencyList>.Visitor()
            let combined2 = vFallback.combined(with: emptyV2)
            _ = SmallestLastVertexOrderingAlgorithm<DefaultAdjacencyList>()
                .orderVertices(in: graph, visitor: combined2)

            #expect(fallback >= 1, "v1 (self) callbacks are used when v2 (other) callbacks are nil")
        }

        /// Verifies the ReverseCuthillMcKeeOrderingAlgorithm visitor composition semantics.
        ///
        /// Uses the same "last-wins" composition as SmallestLastVertex:
        /// `other.cb ?? self.cb`. When `other` (v2) has callbacks, they win; when nil, v1 is used.
        @Test func reverseCuthillMcKeeComposedVisitorLastWins() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: b)

            // Scenario 1: both visitors set all callbacks — v2 (other) wins.
            var examV1 = 0
            var examV2 = 0

            var v1 = ReverseCuthillMcKeeOrderingAlgorithm<DefaultAdjacencyList>.Visitor()
            v1.examineVertex = { _ in examV1 += 1 }
            v1.enqueueVertex = { _, _ in examV1 += 1 }
            v1.dequeueVertex = { _ in examV1 += 1 }
            v1.startFromVertex = { _ in examV1 += 1 }

            var v2 = ReverseCuthillMcKeeOrderingAlgorithm<DefaultAdjacencyList>.Visitor()
            v2.examineVertex = { _ in examV2 += 1 }
            v2.enqueueVertex = { _, _ in examV2 += 1 }
            v2.dequeueVertex = { _ in examV2 += 1 }
            v2.startFromVertex = { _ in examV2 += 1 }

            let combined1 = v1.combined(with: v2)
            _ = ReverseCuthillMcKeeOrderingAlgorithm<DefaultAdjacencyList>()
                .orderVertices(in: graph, visitor: combined1)

            #expect(examV2 >= 1, "all events route to v2 (other) when v2 has non-nil callbacks")
            #expect(examV1 == 0, "v1 (self) callbacks are not called when v2 overrides them")

            // Scenario 2: only v1 sets events, v2 is empty.
            var fallback = 0
            var vFallback = ReverseCuthillMcKeeOrderingAlgorithm<DefaultAdjacencyList>.Visitor()
            vFallback.examineVertex = { _ in fallback += 1 }
            vFallback.enqueueVertex = { _, _ in fallback += 1 }
            vFallback.dequeueVertex = { _ in fallback += 1 }
            vFallback.startFromVertex = { _ in fallback += 1 }

            let emptyV2 = ReverseCuthillMcKeeOrderingAlgorithm<DefaultAdjacencyList>.Visitor()
            let combined2 = vFallback.combined(with: emptyV2)
            _ = ReverseCuthillMcKeeOrderingAlgorithm<DefaultAdjacencyList>()
                .orderVertices(in: graph, visitor: combined2)

            #expect(fallback >= 1, "v1 (self) callbacks are used when v2 (other) callbacks are nil")
        }
    }
#endif
