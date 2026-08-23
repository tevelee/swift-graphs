import Testing

@testable import Graphs

private typealias TestGraph = StorageBackedAdjacencyList<
    OrderedVertexStorage, CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>,
    DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>,
    DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>
>

struct HamiltonianPropertyTests {

    // MARK: - Core Behavior (Dirac Theorem)

    @Test func diracEmptyGraph() {
        let graph = AdjacencyList()
        #expect(!graph.satisfiesDirac(using: StandardDiracPropertyAlgorithm<AdjacencyList>()))
    }

    @Test func diracSingleVertex() {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "A" }
        #expect(!graph.satisfiesDirac(using: StandardDiracPropertyAlgorithm<AdjacencyList>()))
    }

    @Test func diracTwoVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)
        #expect(!graph.satisfiesDirac(using: StandardDiracPropertyAlgorithm<AdjacencyList>()))
    }

    @Test func diracCompleteGraph() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }

        // Complete graph K4 - each vertex has degree 3, min required is 4/2 = 2
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: c, to: d)

        #expect(graph.satisfiesDirac(using: StandardDiracPropertyAlgorithm<AdjacencyList>()))
    }

    @Test func diracSatisfiesCondition() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }

        // Each vertex has degree 3, min required is 5/2 = 2.5 (rounded down to 2)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: a)
        graph.addEdge(from: e, to: b)

        #expect(graph.satisfiesDirac(using: StandardDiracPropertyAlgorithm<AdjacencyList>()))
    }

    @Test func diracDoesNotSatisfyCondition() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }

        // Linear graph: A-B-C-D, each vertex has degree 1 or 2, min required is 4/2 = 2
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: d)

        #expect(!graph.satisfiesDirac(using: StandardDiracPropertyAlgorithm<AdjacencyList>()))
    }

    // MARK: - Core Behavior (Ore Theorem)

    @Test func oreEmptyGraph() {
        let graph = AdjacencyList()
        #expect(!graph.satisfiesOre(using: StandardOrePropertyAlgorithm<AdjacencyList>()))
    }

    @Test func oreSingleVertex() {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "A" }
        #expect(!graph.satisfiesOre(using: StandardOrePropertyAlgorithm<AdjacencyList>()))
    }

    @Test func oreTwoVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)
        #expect(!graph.satisfiesOre(using: StandardOrePropertyAlgorithm<AdjacencyList>()))
    }

    @Test func oreCompleteGraph() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }

        // Complete graph K4 - all vertices are adjacent, so Ore's condition is trivially satisfied
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: c, to: d)

        #expect(graph.satisfiesOre(using: StandardOrePropertyAlgorithm<AdjacencyList>()))
    }

    @Test func oreSatisfiesCondition() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }

        // Graph where non-adjacent pairs have degree sum >= 4
        // A(3) - B(2) - C(3) - D(2)
        // A and C are non-adjacent, degree sum = 3 + 3 = 6 >= 4 ✓
        // B and D are non-adjacent, degree sum = 2 + 2 = 4 >= 4 ✓
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: d)

        #expect(graph.satisfiesOre(using: StandardOrePropertyAlgorithm<AdjacencyList>()))
    }

    @Test func oreDoesNotSatisfyCondition() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }

        // Linear graph: A-B-C-D
        // A and C are non-adjacent, degree sum = 1 + 1 = 2 < 4 ✗
        // A and D are non-adjacent, degree sum = 1 + 1 = 2 < 4 ✗
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: d)

        #expect(!graph.satisfiesOre(using: StandardOrePropertyAlgorithm<AdjacencyList>()))
    }

    @Test func oreWithIsolatedVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        _ = graph.addVertex { $0.label = "C" }
        _ = graph.addVertex { $0.label = "D" }

        // A and B connected, C and D isolated
        // A-C: degree sum = 1 + 0 = 1 < 4 ✗
        graph.addEdge(from: a, to: b)

        #expect(!graph.satisfiesOre(using: StandardOrePropertyAlgorithm<AdjacencyList>()))
    }

    // MARK: - Core Behavior (Hybrid)

    #if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
        @Test func hybridHamiltonianCycle() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            // Complete graph K4 - satisfies Dirac's theorem
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: a, to: d)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: b, to: d)
            graph.addEdge(from: c, to: d)

            #expect(graph.hasHamiltonianCycle())
        }

        @Test func hybridHamiltonianPath() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }

            // Complete graph K4 - satisfies Dirac's theorem, so has both cycle and path
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: a, to: c)
            graph.addEdge(from: a, to: d)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: b, to: d)
            graph.addEdge(from: c, to: d)

            #expect(graph.hasHamiltonianPath())
        }

        @Test func hybridFallbackToAlgorithm() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }

            // Linear graph: A-B-C - doesn't satisfy theorems but has Hamiltonian path
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)

            // Debug: Check what the individual algorithms return
            let dirac = StandardDiracPropertyAlgorithm<TestGraph>()
            let ore = StandardOrePropertyAlgorithm<TestGraph>()

            let satisfiesDirac = graph.satisfiesDirac(using: dirac)
            let satisfiesOre = graph.satisfiesOre(using: ore)

            // This should be false for a linear graph
            #expect(!satisfiesDirac, "Linear graph should not satisfy Dirac's theorem")
            #expect(!satisfiesOre, "Linear graph should not satisfy Ore's theorem")

            #expect(graph.hasHamiltonianPath())
            // Linear graph A-B-C doesn't have a Hamiltonian cycle (needs to return to start)
            #expect(!graph.hasHamiltonianCycle())
        }

        @Test func hybridNoHamiltonianPath() {
            var graph = AdjacencyList()
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            _ = graph.addVertex { $0.label = "C" }
            _ = graph.addVertex { $0.label = "D" }

            // Disconnected graph - no Hamiltonian path
            graph.addEdge(from: a, to: b)
            // c and d are isolated

            #expect(!graph.hasHamiltonianPath())
            #expect(!graph.hasHamiltonianCycle())
        }

    #endif

    // MARK: - Observation Support

    @Test func diracObservation() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)

        var observationCalls: [String] = []
        typealias Cases = DiracProperty<TestGraph>.EventCases
        let observed = StandardDiracPropertyAlgorithm<TestGraph>()
            .observing(Cases.insufficientVertexCount) { count in
                observationCalls.append("insufficientVertexCount(\(count))")
            }
            .observing(Cases.minimumDegreeComputed) { degree in
                observationCalls.append("minimumDegreeComputed(\(degree))")
            }
            .observing(Cases.vertexDegreeChecked) { value in
                observationCalls.append("vertexDegreeChecked(\(value.vertex), \(value.degree), \(value.minimum))")
            }
            .observing(Cases.vertexDegreeTooLow) { value in
                observationCalls.append("vertexDegreeTooLow(\(value.vertex), \(value.degree), \(value.minimum))")
            }

        _ = graph.satisfiesDirac(using: observed)

        #expect(observationCalls.contains("insufficientVertexCount(2)"))
    }

    @Test func oreObservation() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)

        var observationCalls: [String] = []
        typealias Cases = OreProperty<TestGraph>.EventCases
        let observed = StandardOrePropertyAlgorithm<TestGraph>()
            .observing(Cases.insufficientVertexCount) { count in
                observationCalls.append("insufficientVertexCount(\(count))")
            }
            .observing(Cases.vertexCountChecked) { count in
                observationCalls.append("vertexCountChecked(\(count))")
            }
            .observing(Cases.vertexPairChecked) { value in
                observationCalls.append("vertexPairChecked(\(value.0), \(value.1), \(value.adjacent))")
            }
            .observing(Cases.degreeSumChecked) { value in
                observationCalls.append("degreeSumChecked(\(value.0), \(value.1), \(value.sum), \(value.required))")
            }
            .observing(Cases.degreeSumTooLow) { value in
                observationCalls.append("degreeSumTooLow(\(value.0), \(value.1), \(value.sum), \(value.required))")
            }

        _ = graph.satisfiesOre(using: observed)

        #expect(observationCalls.contains("insufficientVertexCount(2)"))
    }

    // MARK: - Composition

    /// Repeated observations compose synchronously and each receive the selected events.
    @Test func diracComposedObservations() {
        // Build a graph with 4 vertices where Dirac's condition is checked per-vertex
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        // K4: all pairs connected → each vertex has degree 3 ≥ n/2 = 2 → Dirac satisfied
        for (u, v) in [(a, b), (a, c), (a, d), (b, c), (b, d), (c, d)] {
            graph.addEdge(from: u, to: v)
            graph.addEdge(from: v, to: u)
        }

        var checkMinDegree = 0
        var checkVtxDegree = 0
        var checkMinDegree2 = 0
        var checkVtxDegree2 = 0

        typealias Cases = DiracProperty<TestGraph>.EventCases
        let observed = StandardDiracPropertyAlgorithm<TestGraph>()
            .observing(Cases.minimumDegreeComputed) { _ in checkMinDegree += 1 }
            .observing(Cases.vertexDegreeChecked) { _ in checkVtxDegree += 1 }
            .observing(Cases.minimumDegreeComputed) { _ in checkMinDegree2 += 1 }
            .observing(Cases.vertexDegreeChecked) { _ in checkVtxDegree2 += 1 }

        let result = graph.satisfiesDirac(using: observed)
        #expect(result, "K4 satisfies Dirac's condition")
        #expect(checkMinDegree == 1, "minimumDegreeComputed fires once per algorithm run")
        #expect(checkVtxDegree == 4, "vertexDegreeChecked fires once per vertex")
        #expect(checkMinDegree == checkMinDegree2)
        #expect(checkVtxDegree == checkVtxDegree2)
    }

    /// Repeated Ore observations compose and receive the same per-pair events.
    @Test func oreComposedObservations() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        // K4 again — every pair is adjacent, so vertexPairChecked fires for each pair.
        for (u, v) in [(a, b), (a, c), (a, d), (b, c), (b, d), (c, d)] {
            graph.addEdge(from: u, to: v)
            graph.addEdge(from: v, to: u)
        }

        var checkCount = 0
        var checkDegSum = 0
        var checkCount2 = 0
        var checkDegSum2 = 0

        typealias Cases = OreProperty<TestGraph>.EventCases
        let observed = StandardOrePropertyAlgorithm<TestGraph>()
            .observing(Cases.vertexPairChecked) { _ in checkCount += 1 }
            .observing(Cases.degreeSumChecked) { _ in checkDegSum += 1 }
            .observing(Cases.vertexPairChecked) { _ in checkCount2 += 1 }
            .observing(Cases.degreeSumChecked) { _ in checkDegSum2 += 1 }

        let result = graph.satisfiesOre(using: observed)
        #expect(result, "K4 satisfies Ore's condition")
        // C(4,2) = 6 pairs checked; all adjacent, so degreeSumChecked never fires.
        #expect(checkCount == 6, "vertexPairChecked fires once per unique pair")
        #expect(checkDegSum == 0, "degreeSumChecked only fires for non-adjacent pairs")
        #expect(checkCount == checkCount2)
        #expect(checkDegSum == checkDegSum2)
    }
}
