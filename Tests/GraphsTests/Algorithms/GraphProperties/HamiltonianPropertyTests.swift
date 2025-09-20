import Testing
@testable import Graphs

typealias TestGraph = AdjacencyList<OrderedVertexStorage, CacheInOutEdges<OrderedEdgeStorage<OrderedVertexStorage.Vertex>>, DictionaryPropertyMap<OrderedVertexStorage.Vertex, VertexPropertyValues>, DictionaryPropertyMap<OrderedEdgeStorage<OrderedVertexStorage.Vertex>.Edge, EdgePropertyValues>>

struct HamiltonianPropertyTests {
    
    // MARK: - Dirac Theorem Tests
    
    @Test func testDiracEmptyGraph() {
        let graph = AdjacencyList()
        #expect(!graph.satisfiesDirac(using: StandardDiracPropertyAlgorithm<AdjacencyList>()))
    }
    
    @Test func testDiracSingleVertex() {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "A" }
        #expect(!graph.satisfiesDirac(using: StandardDiracPropertyAlgorithm<AdjacencyList>()))
    }
    
    @Test func testDiracTwoVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)
        #expect(!graph.satisfiesDirac(using: StandardDiracPropertyAlgorithm<AdjacencyList>()))
    }
    
    @Test func testDiracCompleteGraph() {
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
    
    @Test func testDiracSatisfiesCondition() {
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
    
    @Test func testDiracDoesNotSatisfyCondition() {
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
    
    // MARK: - Ore Theorem Tests
    
    @Test func testOreEmptyGraph() {
        let graph = AdjacencyList()
        #expect(!graph.satisfiesOre(using: StandardOrePropertyAlgorithm<AdjacencyList>()))
    }
    
    @Test func testOreSingleVertex() {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "A" }
        #expect(!graph.satisfiesOre(using: StandardOrePropertyAlgorithm<AdjacencyList>()))
    }
    
    @Test func testOreTwoVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)
        #expect(!graph.satisfiesOre(using: StandardOrePropertyAlgorithm<AdjacencyList>()))
    }
    
    @Test func testOreCompleteGraph() {
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
    
    @Test func testOreSatisfiesCondition() {
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
    
    @Test func testOreDoesNotSatisfyCondition() {
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
    
    @Test func testOreWithIsolatedVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let _ = graph.addVertex { $0.label = "C" }
        let _ = graph.addVertex { $0.label = "D" }
        
        // A and B connected, C and D isolated
        // A-C: degree sum = 1 + 0 = 1 < 4 ✗
        graph.addEdge(from: a, to: b)
        
        #expect(!graph.satisfiesOre(using: StandardOrePropertyAlgorithm<AdjacencyList>()))
    }
    
    // MARK: - Hybrid Approach Tests
    
    @Test func testHybridHamiltonianCycle() {
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
    
    @Test func testHybridHamiltonianPath() {
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
    
    @Test func testHybridFallbackToAlgorithm() {
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
    
    @Test func testHybridNoHamiltonianPath() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let _ = graph.addVertex { $0.label = "C" }
        let _ = graph.addVertex { $0.label = "D" }
        
        // Disconnected graph - no Hamiltonian path
        graph.addEdge(from: a, to: b)
        // c and d are isolated
        
        #expect(!graph.hasHamiltonianPath())
        #expect(!graph.hasHamiltonianCycle())
    }
    
    // MARK: - Visitor Pattern Tests
    
    @Test func testDiracVisitor() {
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
    
    @Test func testOreVisitor() {
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
}
