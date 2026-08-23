import Graphs
import Testing

private enum FamilyWeight: EdgeProperty {
    static let defaultValue = 1.0
}

extension EdgeProperties {
    fileprivate var familyWeight: Double {
        get { self[FamilyWeight.self] }
        set { self[FamilyWeight.self] = newValue }
    }
}

struct AlgorithmObservationFamilyInterfaceTests {
    #if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
        @Test func pathfindingFactoriesForwardCommonObservationShorthands() {
            var graph = AdjacencyList()
            let source = graph.addVertex()
            let destination = graph.addVertex()
            graph.addEdge(from: source, to: destination) { $0.familyWeight = 2 }

            var traversedSource = false
            let traversal = graph.traverse(
                from: source,
                using: .bfs()
                    .observing(.vertexExamined) { vertex in
                        if vertex == source { traversedSource = true }
                    }
            )

            var searchedSource = false
            let path = graph.shortestPath(
                from: source,
                to: destination,
                using: .dijkstra(weight: .property(\.familyWeight))
                    .observing(.vertexExamined) { vertex in
                        if vertex == source { searchedSource = true }
                    }
            )

            #expect(traversedSource)
            #expect(traversal.vertices == [source, destination])
            #expect(searchedSource)
            #expect(path?.vertices == [source, destination])
        }
    #endif

    #if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
        @Test func connectivityFactoryForwardsQualifiedObservation() {
            var graph = AdjacencyList()
            let first = graph.addVertex()
            let second = graph.addVertex()
            graph.addEdge(from: first, to: second)

            var finishedComponent: [AdjacencyList.VertexDescriptor] = []
            let result = graph.connectedComponents(
                using: .dfs()
                    .observing(DFSConnectedComponents<AdjacencyList>.EventCases.componentFinished) { component in
                        finishedComponent = component
                    }
            )

            #expect(Set(finishedComponent) == Set([first, second]))
            #expect(result.componentCount == 1)
            #expect(result.areInSameComponent(first, second))
        }
    #endif

    @Test func propertyFactoryForwardsQualifiedObservation() {
        var graph = AdjacencyList()
        let first = graph.addVertex()
        let second = graph.addVertex()
        graph.addEdge(from: first, to: second)

        var checkedEdgeCount = false
        let isTree = graph.isTree(
            using: .singlePass()
                .observing(DFSTreePropertyAlgorithm<AdjacencyList>.EventCases.edgeCountChecked) { check in
                    checkedEdgeCount = check.actual == 1 && check.expected == 1
                }
        )

        #expect(checkedEdgeCount)
        #expect(isTree)
    }

    #if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
        @Test func optimizationFactoryForwardsQualifiedObservation() {
            var graph = AdjacencyList()
            let first = graph.addVertex()
            let second = graph.addVertex()
            let edge = graph.addEdge(from: first, to: second) { $0.familyWeight = 3 }

            var addedEdge: AdjacencyList.EdgeDescriptor?
            typealias Cases = MinimumSpanningTreeEventCases<
                AdjacencyList.VertexDescriptor,
                AdjacencyList.EdgeDescriptor,
                Double
            >
            let tree = graph.minimumSpanningTree(
                using: .prim(weight: .property(\.familyWeight), startVertex: first)
                    .observing(Cases.edgeAdded) { addition in
                        addedEdge = addition.edge
                    }
            )

            #expect(addedEdge == edge)
            #expect(tree.edgeCount == 1)
            #expect(tree.totalWeight == 3)
        }
    #endif

    #if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
        @Test func analysisFactoryForwardsQualifiedObservation() {
            var graph = AdjacencyList()
            let source = graph.addVertex()
            let destination = graph.addVertex()
            graph.addEdge(from: source, to: destination)

            var computedDegree: Int?
            let result = graph.centrality(
                using: .degree(normalized: false)
                    .observing(DegreeCentrality<AdjacencyList>.EventCases.degreeComputed) { computation in
                        if computation.vertex == source { computedDegree = computation.degree }
                    }
            )

            #expect(computedDegree == 1)
            #expect(result.centrality(for: source) == 1)
        }
    #endif

    #if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
        @Test func advancedFactoryForwardsQualifiedObservation() {
            var graph = AdjacencyList()
            let first = graph.addVertex()
            let second = graph.addVertex()
            graph.addEdge(from: first, to: second)
            graph.addEdge(from: second, to: first)

            var foundClique: [AdjacencyList.VertexDescriptor] = []
            let result = graph.findCliques(
                using: .bronKerbosch()
                    .observing(BronKerboschCliqueDetection<AdjacencyList>.EventCases.cliqueFound) { clique in
                        foundClique = clique
                    }
            )

            #expect(Set(foundClique) == Set([first, second]))
            #expect(result.maximalCliqueSize == 2)
        }
    #endif

    @Test func planarFactoryForwardsVoidObservation() {
        var graph = AdjacencyList()
        let first = graph.addVertex()
        let second = graph.addVertex()
        let third = graph.addVertex()
        graph.addEdge(from: first, to: second)
        graph.addEdge(from: second, to: third)
        graph.addEdge(from: third, to: first)

        var started = false
        let result = graph.planarEmbedding(
            using: .leftRight()
                .observing(LeftRightPlanarEmbedding<AdjacencyList>.EventCases.started) {
                    started = true
                }
        )

        #expect(started)
        guard case .planar = result else {
            Issue.record("A triangle must have a planar embedding")
            return
        }
    }

    #if !GRAPHS_USES_TRAITS || GRAPHS_GENERATION
        @Test func generationFactoryForwardsQualifiedObservation() {
            var observedVertexCount = 0
            let graph = AdjacencyList.randomGraph(
                vertexCount: 3,
                using: .erdosRenyi(edgeProbability: 1)
                    .observing(ErdosRenyi<AdjacencyList>.EventCases.vertexAdded) { _ in
                        observedVertexCount += 1
                    }
            )

            #expect(observedVertexCount == 3)
            #expect(graph.vertexCount == 3)
        }
    #endif
}
