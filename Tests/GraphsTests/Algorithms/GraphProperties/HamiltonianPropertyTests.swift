import Testing

@testable import Graphs

private typealias TestGraph = AdjacencyList<
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

    // MARK: - Visitor Support

    @Test func diracVisitor() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)

        var visitorCalls: [String] = []

        let visitor = DiracProperty<TestGraph>.Visitor(
            insufficientVertices: { n in
                visitorCalls.append("insufficientVertices(\(n))")
            },
            checkMinimumDegree: { minDegree in
                visitorCalls.append("checkMinimumDegree(\(minDegree))")
            },
            checkVertexDegree: { vertex, degree, minDegree in
                visitorCalls.append("checkVertexDegree(\(vertex), \(degree), \(minDegree))")
            },
            degreeTooLow: { vertex, degree, minDegree in
                visitorCalls.append("degreeTooLow(\(vertex), \(degree), \(minDegree))")
            }
        )

        let algorithm = StandardDiracPropertyAlgorithm<TestGraph>()
        _ = algorithm.satisfiesDirac(in: graph, visitor: visitor)

        #expect(visitorCalls.contains("insufficientVertices(2)"))
    }

    @Test func oreVisitor() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)

        var visitorCalls: [String] = []

        let visitor = OreProperty<TestGraph>.Visitor(
            insufficientVertices: { n in
                visitorCalls.append("insufficientVertices(\(n))")
            },
            checkVertexCount: { n in
                visitorCalls.append("checkVertexCount(\(n))")
            },
            checkVertexPair: { u, v, areAdjacent in
                visitorCalls.append("checkVertexPair(\(u), \(v), \(areAdjacent))")
            },
            checkDegreeSum: { u, v, degreeSum, n in
                visitorCalls.append("checkDegreeSum(\(u), \(v), \(degreeSum), \(n))")
            },
            degreeSumTooLow: { u, v, degreeSum, n in
                visitorCalls.append("degreeSumTooLow(\(u), \(v), \(degreeSum), \(n))")
            }
        )

        let algorithm = StandardOrePropertyAlgorithm<TestGraph>()
        _ = algorithm.satisfiesOre(in: graph, visitor: visitor)

        #expect(visitorCalls.contains("insufficientVertices(2)"))
    }

    // MARK: - Composition

    /// `DiracProperty.Visitor` uses `??` composition: the first non-nil callback wins.
    /// Calling `combined(with:)` and running the algorithm exercises the composition code.
    @Test func diracComposedVisitor() {
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

        let v1 = DiracProperty<TestGraph>.Visitor(
            checkMinimumDegree: { _ in checkMinDegree += 1 },
            checkVertexDegree: { _, _, _ in checkVtxDegree += 1 }
        )
        // v2 has no callbacks; combined uses v1's via ??
        let v2 = DiracProperty<TestGraph>.Visitor()
        let combined = v1.combined(with: v2)

        let result = StandardDiracPropertyAlgorithm<TestGraph>().satisfiesDirac(in: graph, visitor: combined)
        #expect(result, "K4 satisfies Dirac's condition")
        #expect(checkMinDegree == 1, "checkMinimumDegree fires once per algorithm run")
        #expect(checkVtxDegree == 4, "checkVertexDegree fires once per vertex")
    }

    /// `OreProperty.Visitor` also uses `??` composition. Exercise `combined(with:)` and
    /// verify the per-pair events fire correctly.
    @Test func oreComposedVisitor() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        // K4 again — every pair is adjacent, so checkVertexPair fires for each pair
        for (u, v) in [(a, b), (a, c), (a, d), (b, c), (b, d), (c, d)] {
            graph.addEdge(from: u, to: v)
            graph.addEdge(from: v, to: u)
        }

        var checkCount = 0
        var checkDegSum = 0

        let v1 = OreProperty<TestGraph>.Visitor(
            checkVertexPair: { _, _, _ in checkCount += 1 },
            checkDegreeSum: { _, _, _, _ in checkDegSum += 1 }
        )
        let v2 = OreProperty<TestGraph>.Visitor()
        let combined = v1.combined(with: v2)

        let result = StandardOrePropertyAlgorithm<TestGraph>().satisfiesOre(in: graph, visitor: combined)
        #expect(result, "K4 satisfies Ore's condition")
        // C(4,2) = 6 pairs checked; all adjacent → checkDegreeSum never fires
        #expect(checkCount == 6, "checkVertexPair fires once per unique pair")
        #expect(checkDegSum == 0, "checkDegreeSum only fires for non-adjacent pairs")
    }
}
