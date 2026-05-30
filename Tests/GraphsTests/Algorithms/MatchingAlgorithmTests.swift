#if !GRAPHS_USES_TRAITS || (GRAPHS_OPTIMIZATION && GRAPHS_BIPARTITE_GRAPH)
    import Testing
    @testable import Graphs

    private typealias DefaultBipartiteGraph = BipartiteAdjacencyList<
        OrderedVertexStorage,
        OrderedEdgeStorage<OrderedVertexStorage.Vertex>,
        DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
        DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
    >

    struct MatchingAlgorithmTests {

        @Test
        func hopcroftKarpSimpleMatching() {
            var graph = BipartiteAdjacencyList()

            // Create a simple bipartite graph
            let left1 = graph.addVertex(to: .left)
            let left2 = graph.addVertex(to: .left)
            let right1 = graph.addVertex(to: .right)
            let right2 = graph.addVertex(to: .right)

            // Add edges
            graph.addEdge(from: left1, to: right1)
            graph.addEdge(from: left2, to: right2)

            // Find maximum matching
            let result = graph.maximumMatching(using: .hopcroftKarp())

            #expect(result.matchingSize == 2)
            #expect(result.matchingEdges.count == 2)
            #expect(result.matchedVertices.count == 4)
            #expect(result.unmatchedVertices.isEmpty)
        }

        @Test
        func hopcroftKarpPartialMatching() {
            var graph = BipartiteAdjacencyList()

            // Create a bipartite graph where not all vertices can be matched
            let left1 = graph.addVertex(to: .left)
            let left2 = graph.addVertex(to: .left)
            let left3 = graph.addVertex(to: .left)
            let right1 = graph.addVertex(to: .right)
            let right2 = graph.addVertex(to: .right)

            // Add edges - only 2 left vertices can be matched
            graph.addEdge(from: left1, to: right1)
            graph.addEdge(from: left2, to: right2)
            graph.addEdge(from: left3, to: right1)  // This creates a conflict

            // Find maximum matching
            let result = graph.maximumMatching(using: .hopcroftKarp())

            #expect(result.matchingSize == 2)
            #expect(result.matchingEdges.count == 2)
            #expect(result.matchedVertices.count == 4)
            #expect(result.unmatchedVertices.count == 1)
            #expect(result.unmatchedLeftVertices.count == 1)
        }

        @Test
        func hopcroftKarpEmptyGraph() {
            let graph = BipartiteAdjacencyList()

            // Find maximum matching in empty graph
            let result = graph.maximumMatching(using: .hopcroftKarp())

            #expect(result.matchingSize == 0)
            #expect(result.matchingEdges.isEmpty)
            #expect(result.matchedVertices.isEmpty)
            #expect(result.unmatchedVertices.isEmpty)
        }

        @Test
        func hopcroftKarpNoEdges() {
            var graph = BipartiteAdjacencyList()

            // Add vertices but no edges
            _ = graph.addVertex(to: .left)
            _ = graph.addVertex(to: .left)
            _ = graph.addVertex(to: .right)
            _ = graph.addVertex(to: .right)

            // Find maximum matching
            let result = graph.maximumMatching(using: .hopcroftKarp())

            #expect(result.matchingSize == 0)
            #expect(result.matchingEdges.isEmpty)
            #expect(result.matchedVertices.isEmpty)
            #expect(result.unmatchedVertices.count == 4)
        }

        @Test(.disabled("indeterministic"))
        func hopcroftKarpComplexMatching() {
            var graph = BipartiteAdjacencyList()

            // Create a more complex bipartite graph
            let left1 = graph.addVertex(to: .left)
            let left2 = graph.addVertex(to: .left)
            let left3 = graph.addVertex(to: .left)
            let right1 = graph.addVertex(to: .right)
            let right2 = graph.addVertex(to: .right)
            let right3 = graph.addVertex(to: .right)

            // Add edges creating multiple possible matchings
            graph.addEdge(from: left1, to: right1)
            graph.addEdge(from: left1, to: right2)
            graph.addEdge(from: left2, to: right1)
            graph.addEdge(from: left2, to: right3)
            graph.addEdge(from: left3, to: right2)
            graph.addEdge(from: left3, to: right3)

            // Find maximum matching
            let result = graph.maximumMatching(using: .hopcroftKarp())

            // Should find a matching of size 3 (all vertices matched)
            #expect(result.matchingSize == 3)
            #expect(result.matchingEdges.count == 3)
            #expect(result.matchedVertices.count == 6)
            #expect(result.unmatchedVertices.isEmpty)
        }

        @Test
        func matchingResultQueries() {
            var graph = BipartiteAdjacencyList()

            let left1 = graph.addVertex(to: .left)
            let left2 = graph.addVertex(to: .left)
            let right1 = graph.addVertex(to: .right)
            let right2 = graph.addVertex(to: .right)

            graph.addEdge(from: left1, to: right1)
            graph.addEdge(from: left2, to: right2)

            let result = graph.maximumMatching(using: .hopcroftKarp())

            // Test vertex matching queries
            #expect(result.isMatched(left1))
            #expect(result.isMatched(right1))
            #expect(result.isMatched(left2))
            #expect(result.isMatched(right2))

            // Test partner lookup
            #expect(result.partner(of: left1) == right1)
            #expect(result.partner(of: right1) == left1)
            #expect(result.partner(of: left2) == right2)
            #expect(result.partner(of: right2) == left2)
            #expect(result.partner(of: left1) != left2)  // left1's partner should be right1, not left2

            // Test partition-specific queries
            #expect(result.matchedLeftVertices.count == 2)
            #expect(result.matchedRightVertices.count == 2)
            #expect(result.unmatchedLeftVertices.isEmpty)
            #expect(result.unmatchedRightVertices.isEmpty)
        }

        @Test
        func defaultMatchingAlgorithm() {
            var graph = BipartiteAdjacencyList()

            let left1 = graph.addVertex(to: .left)
            let left2 = graph.addVertex(to: .left)
            let right1 = graph.addVertex(to: .right)
            let right2 = graph.addVertex(to: .right)

            graph.addEdge(from: left1, to: right1)
            graph.addEdge(from: left2, to: right2)

            // Test default algorithm (should be Hopcroft-Karp)
            let result = graph.maximumMatching()

            #expect(result.matchingSize == 2)
            #expect(result.matchingEdges.count == 2)
        }

        // MARK: - Visitor Support

        /// Exercises all six HopcroftKarp visitor events through a composed visitor pair.
        ///
        /// Graph: bipartite graph L1−R1, L2−R2 (perfect matching of size 2).
        /// - `startIteration` fires at the start of each BFS phase.
        /// - `examineVertex` fires for each vertex examined during BFS/DFS.
        /// - `examineEdge` fires for each edge examined.
        /// - `findAugmentingPath` fires when an augmenting path is found.
        /// - `augmentMatching` fires when the matching is augmented along a path.
        /// - `updateMatching` fires for each left−right vertex pair added to the matching.
        @Test func composedVisitorsReceiveAllEvents() {
            var graph = BipartiteAdjacencyList()
            let left1 = graph.addVertex(to: .left)
            let left2 = graph.addVertex(to: .left)
            let right1 = graph.addVertex(to: .right)
            let right2 = graph.addVertex(to: .right)
            graph.addEdge(from: left1, to: right1)
            graph.addEdge(from: left2, to: right2)

            var startIter1 = 0
            var startIter2 = 0
            var examVtx1 = 0
            var examVtx2 = 0
            var examEdge1 = 0
            var examEdge2 = 0
            var augPath1 = 0
            var augPath2 = 0
            var augMatch1 = 0
            var augMatch2 = 0
            var updMatch1 = 0
            var updMatch2 = 0

            var v1 = HopcroftKarp<DefaultBipartiteGraph>.Visitor()
            v1.startIteration = { _ in startIter1 += 1 }
            v1.examineVertex = { _ in examVtx1 += 1 }
            v1.examineEdge = { _ in examEdge1 += 1 }
            v1.findAugmentingPath = { _ in augPath1 += 1 }
            v1.augmentMatching = { _ in augMatch1 += 1 }
            v1.updateMatching = { _, _ in updMatch1 += 1 }

            var v2 = HopcroftKarp<DefaultBipartiteGraph>.Visitor()
            v2.startIteration = { _ in startIter2 += 1 }
            v2.examineVertex = { _ in examVtx2 += 1 }
            v2.examineEdge = { _ in examEdge2 += 1 }
            v2.findAugmentingPath = { _ in augPath2 += 1 }
            v2.augmentMatching = { _ in augMatch2 += 1 }
            v2.updateMatching = { _, _ in updMatch2 += 1 }

            let combined = v1.combined(with: v2)
            _ = graph.maximumMatching(using: .hopcroftKarp().withVisitor(combined))

            #expect(startIter1 >= 1, "startIteration fires at the start of each BFS phase")
            #expect(startIter2 >= 1)
            #expect(examVtx1 >= 1, "examineVertex fires for each vertex examined")
            #expect(examVtx2 >= 1)
            #expect(examEdge1 >= 1, "examineEdge fires for each edge examined")
            #expect(examEdge2 >= 1)
            #expect(augPath1 >= 1, "findAugmentingPath fires when an augmenting path is found")
            #expect(augPath2 >= 1)
            #expect(augMatch1 >= 1, "augmentMatching fires when the matching is augmented")
            #expect(augMatch2 >= 1)
            #expect(updMatch1 >= 1, "updateMatching fires for each matched pair")
            #expect(updMatch2 >= 1)
            // Both composed visitors must see identical event counts
            #expect(startIter1 == startIter2)
            #expect(examVtx1 == examVtx2)
            #expect(examEdge1 == examEdge2)
            #expect(augPath1 == augPath2)
            #expect(augMatch1 == augMatch2)
            #expect(updMatch1 == updMatch2)
        }
    }
#endif
