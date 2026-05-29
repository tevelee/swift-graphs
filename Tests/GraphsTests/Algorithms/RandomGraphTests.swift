#if !GRAPHS_USES_TRAITS || GRAPHS_GENERATION
import Testing
@testable import Graphs

// Seeded random number generator for reproducible results
struct SeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64
    
    init(seed: UInt64) {
        self.state = seed
    }
    
    mutating func next() -> UInt64 {
        state = state &* 1103515245 &+ 12345
        return state
    }
}

@Suite("Random Graph Generation Tests")
struct RandomGraphTests {
    
    // MARK: - Core Behavior (Erdős-Rényi)
    
    @Test("Erdos-Renyi basic properties")
    func erdosRenyiBasicProperties() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 10,
            using: .erdosRenyi(edgeProbability: 0.3)
                .withGenerator(SeededRandomNumberGenerator(seed: 42))
        )
        
        #expect(graph.vertexCount == 10)
        #expect(graph.edgeCount >= 0)
        #expect(graph.edgeCount <= 45) // Maximum possible edges in 10-vertex graph
    }
    
    @Test("Erdos-Renyi reproducibility with seeded generator")
    func erdosRenyiReproducibility() {
        let algorithm = .erdosRenyi(edgeProbability: 0.5) as ErdosRenyi<AdjacencyList>
        let generator = SeededRandomNumberGenerator(seed: 123)
        
        let graph1 = AdjacencyList.randomGraph(
            vertexCount: 5,
            using: algorithm.withGenerator(generator)
        )
        let graph2 = AdjacencyList.randomGraph(
            vertexCount: 5,
            using: algorithm.withGenerator(generator)
        )
        
        #expect(graph1.vertexCount == graph2.vertexCount)
        #expect(graph1.edgeCount == graph2.edgeCount)
    }
    
    @Test("Erdos-Renyi edge probability effects")
    func erdosRenyiEdgeProbability() {
        let denseAlgorithm = .erdosRenyi(edgeProbability: 0.9) as ErdosRenyi<AdjacencyList>
        let sparseAlgorithm = .erdosRenyi(edgeProbability: 0.1) as ErdosRenyi<AdjacencyList>
        let generator = SeededRandomNumberGenerator(seed: 1)
        
        let denseGraph = AdjacencyList.randomGraph(
            vertexCount: 20,
            using: denseAlgorithm.withGenerator(generator)
        )
        let sparseGraph = AdjacencyList.randomGraph(
            vertexCount: 20,
            using: sparseAlgorithm.withGenerator(generator)
        )
        
        #expect(denseGraph.edgeCount > sparseGraph.edgeCount)
    }
    
    @Test("Erdos-Renyi with AdjacencyMatrix")
    func erdosRenyiAdjacencyMatrix() {
        let graph = AdjacencyMatrix.randomGraph(
            vertexCount: 8,
            using: .erdosRenyi(edgeProbability: 0.4)
                .withGenerator(SeededRandomNumberGenerator(seed: 456))
        )
        
        #expect(graph.vertexCount == 8)
        #expect(graph.edgeCount >= 0)
    }
    
    // MARK: - Core Behavior (Barabási-Albert)
    
    @Test("Barabasi-Albert basic properties")
    func barabasiAlbertBasicProperties() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 20,
            using: .barabasiAlbert(averageDegree: 4.0).withGenerator(SeededRandomNumberGenerator(seed: 789))
        )
        
        #expect(graph.vertexCount == 20)
        #expect(graph.edgeCount > 0)
    }
    
    @Test("Barabasi-Albert reproducibility with seeded generator")
    func barabasiAlbertReproducibility() {
        let algorithm = .barabasiAlbert(averageDegree: 3.0) as BarabasiAlbert<AdjacencyList>
        let generator = SeededRandomNumberGenerator(seed: 999)
        
        let graph1 = AdjacencyList.randomGraph(
            vertexCount: 10,
            using: algorithm.withGenerator(generator)
        )
        let graph2 = AdjacencyList.randomGraph(
            vertexCount: 10,
            using: algorithm.withGenerator(generator)
        )
        
        #expect(graph1.vertexCount == graph2.vertexCount)
        #expect(graph1.edgeCount == graph2.edgeCount)
    }
    
    @Test("Barabasi-Albert scale-free property")
    func barabasiAlbertScaleFreeProperty() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 50,
            using: .barabasiAlbert(averageDegree: 4.0)
                .withGenerator(SeededRandomNumberGenerator(seed: 111))
        )
        
        #expect(graph.vertexCount == 50)
        #expect(graph.edgeCount > 0)
        
        // Calculate degree distribution
        var degreeCounts: [Int: Int] = [:]
        for vertex in graph.vertices() {
            let degree = graph.outDegree(of: vertex)
            degreeCounts[degree, default: 0] += 1
        }
        
        // Should have some high-degree vertices (scale-free property)
        let maxDegree = degreeCounts.keys.max() ?? 0
        #expect(maxDegree > 3) // Some vertices should have high degree
    }
    
    @Test("Barabasi-Albert with AdjacencyMatrix")
    func barabasiAlbertAdjacencyMatrix() {
        let graph = AdjacencyMatrix.randomGraph(
            vertexCount: 15,
            using: .barabasiAlbert(averageDegree: 3.0)
                .withGenerator(SeededRandomNumberGenerator(seed: 222))
        )
        
        #expect(graph.vertexCount == 15)
        #expect(graph.edgeCount > 0)
    }
    
    // MARK: - Core Behavior (Watts-Strogatz)
    
    @Test("Watts-Strogatz basic properties")
    func wattsStrogatzBasicProperties() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 20,
            using: .wattsStrogatz(averageDegree: 6.0, rewiringProbability: 0.3)
                .withGenerator(SeededRandomNumberGenerator(seed: 333))
        )
        
        #expect(graph.vertexCount == 20)
        #expect(graph.edgeCount > 0)
    }
    
    @Test("Watts-Strogatz reproducibility with seeded generator")
    func wattsStrogatzReproducibility() {
        let algorithm = .wattsStrogatz(averageDegree: 4.0, rewiringProbability: 0.5) as WattsStrogatz<AdjacencyList>
        let generator = SeededRandomNumberGenerator(seed: 444)
        
        let graph1 = AdjacencyList.randomGraph(
            vertexCount: 12,
            using: algorithm.withGenerator(generator)
        )
        let graph2 = AdjacencyList.randomGraph(
            vertexCount: 12,
            using: algorithm.withGenerator(generator)
        )
        
        #expect(graph1.vertexCount == graph2.vertexCount)
        #expect(graph1.edgeCount == graph2.edgeCount)
    }
    
    @Test("Watts-Strogatz rewiring probability effects")
    func wattsStrogatzRewiringProbability() {
        let regularAlgorithm = .wattsStrogatz(averageDegree: 4.0, rewiringProbability: 0.1) as WattsStrogatz<AdjacencyList>
        let randomAlgorithm = .wattsStrogatz(averageDegree: 4.0, rewiringProbability: 0.9) as WattsStrogatz<AdjacencyList>
        let generator = SeededRandomNumberGenerator(seed: 555)
        
        let regularGraph = AdjacencyList.randomGraph(
            vertexCount: 16,
            using: regularAlgorithm.withGenerator(generator)
        )
        let randomGraph = AdjacencyList.randomGraph(
            vertexCount: 16,
            using: randomAlgorithm.withGenerator(generator)
        )
        
        // Both should have the same number of edges (approximately)
        #expect(regularGraph.vertexCount == randomGraph.vertexCount)
        #expect(abs(regularGraph.edgeCount - randomGraph.edgeCount) <= 30) // Allow reasonable variance
    }
    
    @Test("Watts-Strogatz with AdjacencyMatrix")
    func wattsStrogatzAdjacencyMatrix() {
        let graph = AdjacencyMatrix.randomGraph(
            vertexCount: 10,
            using: .wattsStrogatz(averageDegree: 4.0, rewiringProbability: 0.2)
                .withGenerator(SeededRandomNumberGenerator(seed: 666))
        )
        
        #expect(graph.vertexCount == 10)
        #expect(graph.edgeCount > 0)
    }
    
    // MARK: - Edge Cases
    
    @Test("Empty graph generation")
    func emptyGraph() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 0,
            using: .erdosRenyi(edgeProbability: 0.5)
                .withGenerator(SeededRandomNumberGenerator(seed: 777))
        )
        
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }
    
    @Test("Single vertex graph")
    func singleVertex() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 1,
            using: .erdosRenyi(edgeProbability: 0.5)
                .withGenerator(SeededRandomNumberGenerator(seed: 888))
        )
        
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0) // No self-loops in undirected graph
    }
    
    @Test("Zero probability edge case")
    func zeroProbability() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 5,
            using: .erdosRenyi(edgeProbability: 0.0)
                .withGenerator(SeededRandomNumberGenerator(seed: 999))
        )
        
        #expect(graph.vertexCount == 5)
        #expect(graph.edgeCount == 0)
    }
    
    @Test("One probability edge case")
    func oneProbability() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 4,
            using: .erdosRenyi(edgeProbability: 1.0)
                .withGenerator(SeededRandomNumberGenerator(seed: 1000))
        )
        
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 6) // Complete graph with 4 vertices
    }
    
    // MARK: - API Convenience
    
    @Test("Fluent API with different graph types")
    func fluentAPI() {
        // Test Erdos-Renyi with AdjacencyList
        let graph1 = AdjacencyList.randomGraph(
            vertexCount: 10,
            using: .erdosRenyi(edgeProbability: 0.3)
                .withGenerator(SeededRandomNumberGenerator(seed: 42))
        )
        
        #expect(graph1.vertexCount == 10)
        #expect(graph1.edgeCount >= 0)
        #expect(graph1.edgeCount <= 45)
        
        // Test Barabasi-Albert with AdjacencyMatrix
        let graph2 = AdjacencyMatrix.randomGraph(
            vertexCount: 20,
            using: .barabasiAlbert(averageDegree: 3.0)
                .withGenerator(SeededRandomNumberGenerator(seed: 123))
        )
        
        #expect(graph2.vertexCount == 20)
        #expect(graph2.edgeCount > 0)
        
        // Test Watts-Strogatz with AdjacencyList
        let graph3 = AdjacencyList.randomGraph(
            vertexCount: 15,
            using: .wattsStrogatz(averageDegree: 4.0, rewiringProbability: 0.1)
                .withGenerator(SeededRandomNumberGenerator(seed: 456))
        )
        
        #expect(graph3.vertexCount == 15)
        #expect(graph3.edgeCount > 0)
    }
    
    @Test("Algorithm protocol conformance")
    func algorithmProtocolConformance() {
        let algorithm = .erdosRenyi(edgeProbability: 0.3) as ErdosRenyi<AdjacencyList>
        let graph = AdjacencyList.randomGraph(vertexCount: 10, using: algorithm)
        
        #expect(graph.vertexCount == 10)
        #expect(graph.edgeCount >= 0)
    }
    
    @Test("Static factory methods")
    func staticFactoryMethods() {
        let algorithm = .erdosRenyi(edgeProbability: 0.4) as ErdosRenyi<AdjacencyList>
        let graph = AdjacencyList.randomGraph(vertexCount: 8, using: algorithm)

        #expect(graph.vertexCount == 8)
        #expect(graph.edgeCount >= 0)
    }

    // MARK: - Visitor Support

    /// Exercises all four ErdosRenyi visitor events through a composed visitor pair.
    ///
    /// Uses a seeded generator and probability 0.5 on a 4-vertex graph so that some edges
    /// are added (`addEdge`) and some are skipped (`skipEdge`). Both events are deterministic
    /// because the generator is seeded.
    /// - `addVertex` fires once per vertex created.
    /// - `examineVertexPair` fires for each (u, v) pair evaluated.
    /// - `addEdge` fires when the probability check passes.
    /// - `skipEdge` fires when the probability check fails.
    @Test("ErdosRenyi composed visitors receive all events")
    func erdosRenyiComposedVisitorsReceiveAllEvents() {
        var addVtx1 = 0;     var addVtx2 = 0
        var examPair1 = 0;   var examPair2 = 0
        var addEdge1 = 0;    var addEdge2 = 0
        var skipEdge1 = 0;   var skipEdge2 = 0

        var v1 = ErdosRenyi<DefaultAdjacencyList>.Visitor()
        v1.addVertex         = { _ in addVtx1 += 1 }
        v1.examineVertexPair = { _, _ in examPair1 += 1 }
        v1.addEdge           = { _, _ in addEdge1 += 1 }
        v1.skipEdge          = { _, _, _ in skipEdge1 += 1 }

        var v2 = ErdosRenyi<DefaultAdjacencyList>.Visitor()
        v2.addVertex         = { _ in addVtx2 += 1 }
        v2.examineVertexPair = { _, _ in examPair2 += 1 }
        v2.addEdge           = { _, _ in addEdge2 += 1 }
        v2.skipEdge          = { _, _, _ in skipEdge2 += 1 }

        let combined = v1.combined(with: v2)
        // p=1.0 ensures addEdge fires for every pair; use a second run with p=0.0 for skipEdge
        _ = DefaultAdjacencyList.randomGraph(
            vertexCount: 4,
            using: (.erdosRenyi(edgeProbability: 1.0) as ErdosRenyi<DefaultAdjacencyList>)
                .withVisitor(combined)
                .withGenerator(SeededRandomNumberGenerator(seed: 1))
        )

        // With p=1.0 all pairs add an edge; skip never fires here
        #expect(addVtx1 == 4,     "addVertex fires exactly 4 times for 4 vertices")
        #expect(addVtx2 == 4)
        #expect(examPair1 >= 1,   "examineVertexPair fires for each evaluated pair")
        #expect(examPair2 >= 1)
        #expect(addEdge1 >= 1,    "addEdge fires when probability check passes (p=1.0)")
        #expect(addEdge2 >= 1)
        // addVtx + examPair + addEdge + skip collectively = all events; verify symmetry
        #expect(addVtx1 == addVtx2)
        #expect(examPair1 == examPair2)
        #expect(addEdge1 == addEdge2)
        #expect(skipEdge1 == skipEdge2)

        // Second run with p=0.0 to trigger skipEdge
        var skipOnly1 = 0;  var skipOnly2 = 0
        var sv1 = ErdosRenyi<DefaultAdjacencyList>.Visitor()
        sv1.skipEdge = { _, _, _ in skipOnly1 += 1 }
        var sv2 = ErdosRenyi<DefaultAdjacencyList>.Visitor()
        sv2.skipEdge = { _, _, _ in skipOnly2 += 1 }
        let skipCombined = sv1.combined(with: sv2)
        _ = DefaultAdjacencyList.randomGraph(
            vertexCount: 4,
            using: (.erdosRenyi(edgeProbability: 0.0) as ErdosRenyi<DefaultAdjacencyList>)
                .withVisitor(skipCombined)
                .withGenerator(SeededRandomNumberGenerator(seed: 1))
        )
        #expect(skipOnly1 >= 1,   "skipEdge fires when probability check fails (p=0.0)")
        #expect(skipOnly2 >= 1)
        #expect(skipOnly1 == skipOnly2, "both composed visitors see the same skipEdge events")
    }

    /// Exercises all four BarabasiAlbert visitor events through a composed visitor pair.
    ///
    /// Generates a preferential-attachment graph with 6 vertices and averageDegree=2.
    /// - `addVertex` fires for each vertex added.
    /// - `selectTarget` fires when preferential attachment selects a target vertex.
    /// - `addEdge` fires for each edge added by the algorithm.
    /// - `updateDegree` fires when a vertex's degree changes.
    @Test("BarabasiAlbert composed visitors receive all events")
    func barabasiAlbertComposedVisitorsReceiveAllEvents() {
        var addVtx1 = 0;    var addVtx2 = 0
        var select1 = 0;    var select2 = 0
        var addEdge1 = 0;   var addEdge2 = 0
        var updDeg1 = 0;    var updDeg2 = 0

        var v1 = BarabasiAlbert<DefaultAdjacencyList>.Visitor()
        v1.addVertex    = { _ in addVtx1 += 1 }
        v1.selectTarget = { _, _ in select1 += 1 }
        v1.addEdge      = { _, _ in addEdge1 += 1 }
        v1.updateDegree = { _, _ in updDeg1 += 1 }

        var v2 = BarabasiAlbert<DefaultAdjacencyList>.Visitor()
        v2.addVertex    = { _ in addVtx2 += 1 }
        v2.selectTarget = { _, _ in select2 += 1 }
        v2.addEdge      = { _, _ in addEdge2 += 1 }
        v2.updateDegree = { _, _ in updDeg2 += 1 }

        let combined = v1.combined(with: v2)
        _ = DefaultAdjacencyList.randomGraph(
            vertexCount: 6,
            using: (.barabasiAlbert(averageDegree: 2.0) as BarabasiAlbert<DefaultAdjacencyList>)
                .withVisitor(combined)
                .withGenerator(SeededRandomNumberGenerator(seed: 42))
        )

        #expect(addVtx1 == 6,   "addVertex fires exactly 6 times for 6 vertices")
        #expect(addVtx2 == 6)
        #expect(select1 >= 1,   "selectTarget fires during preferential attachment")
        #expect(select2 >= 1)
        #expect(addEdge1 >= 1,  "addEdge fires for each edge created")
        #expect(addEdge2 >= 1)
        #expect(updDeg1 >= 1,   "updateDegree fires when a vertex's degree changes")
        #expect(updDeg2 >= 1)
        // Both composed visitors must see identical event counts
        #expect(addVtx1 == addVtx2)
        #expect(select1 == select2)
        #expect(addEdge1 == addEdge2)
        #expect(updDeg1 == updDeg2)
    }

    /// Exercises WattsStrogatz visitor events through a composed visitor pair.
    ///
    /// Generates a small-world graph with rewiringProbability=1.0 to ensure `rewireEdge` fires
    /// for every eligible edge. With `rewiringProbability=0.0`, `skipRewiring` fires instead.
    /// - `addVertex` fires for each vertex created.
    /// - `createRingLattice` fires when the ring lattice edge is created.
    /// - `rewireEdge` fires when an edge is rewired (p=1.0 test).
    /// - `skipRewiring` fires when rewiring is skipped (p=0.0 test).
    ///
    /// Note: `addEdge` is defined in the visitor struct but is not currently called by
    /// the WattsStrogatz implementation.
    @Test("WattsStrogatz composed visitors receive all events")
    func wattsStrogatzComposedVisitorsReceiveAllEvents() {
        var addVtx1 = 0;    var addVtx2 = 0
        var lattice1 = 0;   var lattice2 = 0
        var rewire1 = 0;    var rewire2 = 0

        var v1 = WattsStrogatz<DefaultAdjacencyList>.Visitor()
        v1.addVertex       = { _ in addVtx1 += 1 }
        v1.createRingLattice = { _, _ in lattice1 += 1 }
        v1.rewireEdge      = { _, _, _ in rewire1 += 1 }

        var v2 = WattsStrogatz<DefaultAdjacencyList>.Visitor()
        v2.addVertex       = { _ in addVtx2 += 1 }
        v2.createRingLattice = { _, _ in lattice2 += 1 }
        v2.rewireEdge      = { _, _, _ in rewire2 += 1 }

        let combined = v1.combined(with: v2)
        // rewiringProbability=1.0 ensures rewireEdge fires for every eligible edge
        _ = DefaultAdjacencyList.randomGraph(
            vertexCount: 8,
            using: (.wattsStrogatz(averageDegree: 2.0, rewiringProbability: 1.0) as WattsStrogatz<DefaultAdjacencyList>)
                .withVisitor(combined)
                .withGenerator(SeededRandomNumberGenerator(seed: 7))
        )

        #expect(addVtx1 == 8,   "addVertex fires exactly 8 times for 8 vertices")
        #expect(addVtx2 == 8)
        #expect(lattice1 >= 1,  "createRingLattice fires for each initial ring edge")
        #expect(lattice2 >= 1)
        #expect(rewire1 >= 1,   "rewireEdge fires when an edge is rewired (p=1.0)")
        #expect(rewire2 >= 1)
        #expect(addVtx1 == addVtx2)
        #expect(lattice1 == lattice2)
        #expect(rewire1 == rewire2)

        // Separate run with p=0.0 to trigger skipRewiring
        var skip1 = 0;  var skip2 = 0
        var sv1 = WattsStrogatz<DefaultAdjacencyList>.Visitor()
        sv1.skipRewiring = { _, _, _ in skip1 += 1 }
        var sv2 = WattsStrogatz<DefaultAdjacencyList>.Visitor()
        sv2.skipRewiring = { _, _, _ in skip2 += 1 }
        let skipCombined = sv1.combined(with: sv2)
        _ = DefaultAdjacencyList.randomGraph(
            vertexCount: 8,
            using: (.wattsStrogatz(averageDegree: 2.0, rewiringProbability: 0.0) as WattsStrogatz<DefaultAdjacencyList>)
                .withVisitor(skipCombined)
                .withGenerator(SeededRandomNumberGenerator(seed: 7))
        )
        #expect(skip1 >= 1,    "skipRewiring fires when rewiring probability check fails (p=0.0)")
        #expect(skip2 >= 1)
        #expect(skip1 == skip2, "both composed visitors see the same skipRewiring events")
    }

    // MARK: - Convenience factory methods

    /// `randomGraph()`, `randomScaleFreeGraph()`, and `randomSmallWorldGraph()` are
    /// no-arg convenience wrappers that call the underlying algorithm with defaults.
    @Test func randomGraphConvenienceMethods() {
        // randomGraph() — uses Erdos-Renyi with default probability 0.5
        let g1 = DefaultAdjacencyList.randomGraph(vertexCount: 5)
        #expect(g1.vertexCount == 5, "randomGraph() creates the specified vertex count")

        // randomScaleFreeGraph() — uses Barabasi-Albert with default averageDegree 2.0
        let g2 = DefaultAdjacencyList.randomScaleFreeGraph(vertexCount: 5)
        #expect(g2.vertexCount == 5, "randomScaleFreeGraph() creates the specified vertex count")

        // randomSmallWorldGraph() — uses Watts-Strogatz with defaults
        let g3 = DefaultAdjacencyList.randomSmallWorldGraph(vertexCount: 6)
        #expect(g3.vertexCount == 6, "randomSmallWorldGraph() creates the specified vertex count")
    }
}
#endif
