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
    
    // MARK: - Erdos-Renyi Tests
    
    @Test("Erdos-Renyi basic properties")
    func testErdosRenyiBasicProperties() {
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
    func testErdosRenyiReproducibility() {
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
    func testErdosRenyiEdgeProbability() {
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
    func testErdosRenyiAdjacencyMatrix() {
        let graph = AdjacencyMatrix.randomGraph(
            vertexCount: 8,
            using: .erdosRenyi(edgeProbability: 0.4)
                .withGenerator(SeededRandomNumberGenerator(seed: 456))
        )
        
        #expect(graph.vertexCount == 8)
        #expect(graph.edgeCount >= 0)
    }
    
    // MARK: - Barabasi-Albert Tests
    
    @Test("Barabasi-Albert basic properties")
    func testBarabasiAlbertBasicProperties() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 20,
            using: .barabasiAlbert(averageDegree: 4.0).withGenerator(SeededRandomNumberGenerator(seed: 789))
        )
        
        #expect(graph.vertexCount == 20)
        #expect(graph.edgeCount > 0)
    }
    
    @Test("Barabasi-Albert reproducibility with seeded generator")
    func testBarabasiAlbertReproducibility() {
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
    func testBarabasiAlbertScaleFreeProperty() {
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
    func testBarabasiAlbertAdjacencyMatrix() {
        let graph = AdjacencyMatrix.randomGraph(
            vertexCount: 15,
            using: .barabasiAlbert(averageDegree: 3.0)
                .withGenerator(SeededRandomNumberGenerator(seed: 222))
        )
        
        #expect(graph.vertexCount == 15)
        #expect(graph.edgeCount > 0)
    }
    
    // MARK: - Watts-Strogatz Tests
    
    @Test("Watts-Strogatz basic properties")
    func testWattsStrogatzBasicProperties() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 20,
            using: .wattsStrogatz(averageDegree: 6.0, rewiringProbability: 0.3)
                .withGenerator(SeededRandomNumberGenerator(seed: 333))
        )
        
        #expect(graph.vertexCount == 20)
        #expect(graph.edgeCount > 0)
    }
    
    @Test("Watts-Strogatz reproducibility with seeded generator")
    func testWattsStrogatzReproducibility() {
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
    func testWattsStrogatzRewiringProbability() {
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
    func testWattsStrogatzAdjacencyMatrix() {
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
    func testEmptyGraph() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 0,
            using: .erdosRenyi(edgeProbability: 0.5)
                .withGenerator(SeededRandomNumberGenerator(seed: 777))
        )
        
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }
    
    @Test("Single vertex graph")
    func testSingleVertex() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 1,
            using: .erdosRenyi(edgeProbability: 0.5)
                .withGenerator(SeededRandomNumberGenerator(seed: 888))
        )
        
        #expect(graph.vertexCount == 1)
        #expect(graph.edgeCount == 0) // No self-loops in undirected graph
    }
    
    @Test("Zero probability edge case")
    func testZeroProbability() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 5,
            using: .erdosRenyi(edgeProbability: 0.0)
                .withGenerator(SeededRandomNumberGenerator(seed: 999))
        )
        
        #expect(graph.vertexCount == 5)
        #expect(graph.edgeCount == 0)
    }
    
    @Test("One probability edge case")
    func testOneProbability() {
        let graph = AdjacencyList.randomGraph(
            vertexCount: 4,
            using: .erdosRenyi(edgeProbability: 1.0)
                .withGenerator(SeededRandomNumberGenerator(seed: 1000))
        )
        
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 6) // Complete graph with 4 vertices
    }
    
    // MARK: - Fluent API Tests
    
    @Test("Fluent API with different graph types")
    func testFluentAPI() {
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
    func testRandomGraphAlgorithmProtocol() {
        let algorithm = .erdosRenyi(edgeProbability: 0.3) as ErdosRenyi<AdjacencyList>
        let graph = AdjacencyList.randomGraph(vertexCount: 10, using: algorithm)
        
        #expect(graph.vertexCount == 10)
        #expect(graph.edgeCount >= 0)
    }
    
    @Test("Static factory methods")
    func testRandomGraphFactory() {
        let algorithm = .erdosRenyi(edgeProbability: 0.4) as ErdosRenyi<AdjacencyList>
        let graph = AdjacencyList.randomGraph(vertexCount: 8, using: algorithm)
        
        #expect(graph.vertexCount == 8)
        #expect(graph.edgeCount >= 0)
    }
}
