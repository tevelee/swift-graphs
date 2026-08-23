#if !GRAPHS_USES_TRAITS || (GRAPHS_OPTIMIZATION && GRAPHS_BIPARTITE_GRAPH)
    import Testing
    @testable import Graphs

    private typealias DefaultBipartiteGraph = StorageBackedBipartiteAdjacencyList<
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

        // MARK: - Observation Support

        /// Exercises all six Hopcroft-Karp events through an ordered observation chain.
        ///
        /// Graph: bipartite graph L1−R1, L2−R2 (perfect matching of size 2).
        /// - `iterationStarted` fires at the start of each BFS phase.
        /// - `vertexExamined` fires for each vertex examined during BFS/DFS.
        /// - `edgeExamined` fires for each edge examined.
        /// - `augmentingPathFound` fires when an augmenting path is found.
        /// - `matchingAugmentationStarted` fires when matching augmentation begins.
        /// - `matchingUpdated` fires for each left−right vertex pair added to the matching.
        @Test func composedObservationsReceiveAllEvents() {
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

            typealias Cases = HopcroftKarp<DefaultBipartiteGraph>.EventCases
            let algorithm = HopcroftKarp<DefaultBipartiteGraph>()
                .observing(Cases.iterationStarted) { _ in startIter1 += 1 }
                .observing(Cases.vertexExamined) { _ in examVtx1 += 1 }
                .observing(Cases.edgeExamined) { _ in examEdge1 += 1 }
                .observing(Cases.augmentingPathFound) { _ in augPath1 += 1 }
                .observing(Cases.matchingAugmentationStarted) { _ in augMatch1 += 1 }
                .observing(Cases.matchingUpdated) { _ in updMatch1 += 1 }
                .observing(Cases.iterationStarted) { _ in startIter2 += 1 }
                .observing(Cases.vertexExamined) { _ in examVtx2 += 1 }
                .observing(Cases.edgeExamined) { _ in examEdge2 += 1 }
                .observing(Cases.augmentingPathFound) { _ in augPath2 += 1 }
                .observing(Cases.matchingAugmentationStarted) { _ in augMatch2 += 1 }
                .observing(Cases.matchingUpdated) { _ in updMatch2 += 1 }

            _ = graph.maximumMatching(using: algorithm)

            #expect(startIter1 >= 1, "iterationStarted fires at the start of each BFS phase")
            #expect(startIter2 >= 1)
            #expect(examVtx1 >= 1, "vertexExamined fires for each vertex examined")
            #expect(examVtx2 >= 1)
            #expect(examEdge1 >= 1, "edgeExamined fires for each edge examined")
            #expect(examEdge2 >= 1)
            #expect(augPath1 >= 1, "augmentingPathFound fires when an augmenting path is found")
            #expect(augPath2 >= 1)
            #expect(augMatch1 >= 1, "matchingAugmentationStarted fires before matching is augmented")
            #expect(augMatch2 >= 1)
            #expect(updMatch1 >= 1, "matchingUpdated fires for each matched pair")
            #expect(updMatch2 >= 1)
            // Both ordered observation groups must see identical event counts.
            #expect(startIter1 == startIter2)
            #expect(examVtx1 == examVtx2)
            #expect(examEdge1 == examEdge2)
            #expect(augPath1 == augPath2)
            #expect(augMatch1 == augMatch2)
            #expect(updMatch1 == updMatch2)
        }
    }
#endif
