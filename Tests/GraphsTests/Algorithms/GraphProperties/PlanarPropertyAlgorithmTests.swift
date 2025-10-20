import Testing
import Foundation
@testable import Graphs

struct PlanarPropertyAlgorithmTests {
    
    // MARK: - Test Data Creation
    
    func createPlanarGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create a planar graph (square with diagonal)
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: d, to: a) { $0.label = "DA" }
        graph.addEdge(from: a, to: c) { $0.label = "AC" }
        
        return graph
    }
    
    func createNonPlanarGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        // Create K₅ (complete graph on 5 vertices) - non-planar
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: a, to: c) { $0.label = "AC" }
        graph.addEdge(from: a, to: d) { $0.label = "AD" }
        graph.addEdge(from: a, to: e) { $0.label = "AE" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: b, to: d) { $0.label = "BD" }
        graph.addEdge(from: b, to: e) { $0.label = "BE" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: c, to: e) { $0.label = "CE" }
        graph.addEdge(from: d, to: e) { $0.label = "DE" }
        
        return graph
    }
    
    func createK33Graph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a1 = graph.addVertex { $0.label = "A1" }
        let a2 = graph.addVertex { $0.label = "A2" }
        let a3 = graph.addVertex { $0.label = "A3" }
        let b1 = graph.addVertex { $0.label = "B1" }
        let b2 = graph.addVertex { $0.label = "B2" }
        let b3 = graph.addVertex { $0.label = "B3" }
        
        // Create K₃,₃ (complete bipartite graph) - non-planar
        graph.addEdge(from: a1, to: b1) { $0.label = "A1B1" }
        graph.addEdge(from: a1, to: b2) { $0.label = "A1B2" }
        graph.addEdge(from: a1, to: b3) { $0.label = "A1B3" }
        graph.addEdge(from: a2, to: b1) { $0.label = "A2B1" }
        graph.addEdge(from: a2, to: b2) { $0.label = "A2B2" }
        graph.addEdge(from: a2, to: b3) { $0.label = "A2B3" }
        graph.addEdge(from: a3, to: b1) { $0.label = "A3B1" }
        graph.addEdge(from: a3, to: b2) { $0.label = "A3B2" }
        graph.addEdge(from: a3, to: b3) { $0.label = "A3B3" }
        
        return graph
    }
    
    func createEmptyGraph() -> some AdjacencyListProtocol {
        AdjacencyList()
    }
    
    func createSingleVertexGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "A" }
        return graph
    }
    
    func createTwoVertexGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        return graph
    }
    
    // MARK: - Euler Formula Algorithm Tests
    
    @Test func testEulerFormulaEmptyGraph() {
        let graph = createEmptyGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testEulerFormulaSingleVertex() {
        let graph = createSingleVertexGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testEulerFormulaTwoVertices() {
        let graph = createTwoVertexGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testEulerFormulaPlanarGraph() {
        let graph = createPlanarGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testEulerFormulaNonPlanarK5() {
        let graph = createNonPlanarGraph()
        #expect(!graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testEulerFormulaNonPlanarK33() {
        let graph = createK33Graph()
        #expect(!graph.isPlanar(using: .eulerFormula()))
    }
    
    // MARK: - Left-Right Algorithm Tests
    
    @Test func testLeftRightEmptyGraph() {
        let graph = createEmptyGraph()
        #expect(graph.isPlanar(using: .leftRight()))
    }
    
    @Test func testLeftRightSingleVertex() {
        let graph = createSingleVertexGraph()
        #expect(graph.isPlanar(using: .leftRight()))
    }
    
    @Test func testLeftRightTwoVertices() {
        let graph = createTwoVertexGraph()
        #expect(graph.isPlanar(using: .leftRight()))
    }
    
    @Test func testLeftRightPlanarGraph() {
        let graph = createPlanarGraph()
        #expect(graph.isPlanar(using: .leftRight()))
    }
    
    @Test func testLeftRightNonPlanarK5() {
        let graph = createNonPlanarGraph()
        #expect(!graph.isPlanar(using: .leftRight()))
    }
    
    @Test func testLeftRightNonPlanarK33() {
        let graph = createK33Graph()
        #expect(!graph.isPlanar(using: .leftRight()))
    }
    
    // MARK: - Hopcroft-Tarjan Algorithm Tests
    
    @Test func testHopcroftTarjanEmptyGraph() {
        let graph = createEmptyGraph()
        #expect(graph.isPlanar(using: .hopcroftTarjan()))
    }
    
    @Test func testHopcroftTarjanSingleVertex() {
        let graph = createSingleVertexGraph()
        #expect(graph.isPlanar(using: .hopcroftTarjan()))
    }
    
    @Test func testHopcroftTarjanTwoVertices() {
        let graph = createTwoVertexGraph()
        #expect(graph.isPlanar(using: .hopcroftTarjan()))
    }
    
    @Test func testHopcroftTarjanPlanarGraph() {
        let graph = createPlanarGraph()
        #expect(graph.isPlanar(using: .hopcroftTarjan()))
    }
    
    @Test func testHopcroftTarjanNonPlanarK5() {
        let graph = createNonPlanarGraph()
        #expect(!graph.isPlanar(using: .hopcroftTarjan()))
    }
    
    @Test func testHopcroftTarjanNonPlanarK33() {
        let graph = createK33Graph()
        #expect(!graph.isPlanar(using: .hopcroftTarjan()))
    }
    
    // MARK: - Boyer-Myrvold Algorithm Tests
    
    @Test func testBoyerMyrvoldEmptyGraph() {
        let graph = createEmptyGraph()
        #expect(graph.isPlanar(using: .boyerMyrvold()))
    }
    
    @Test func testBoyerMyrvoldSingleVertex() {
        let graph = createSingleVertexGraph()
        #expect(graph.isPlanar(using: .boyerMyrvold()))
    }
    
    @Test func testBoyerMyrvoldTwoVertices() {
        let graph = createTwoVertexGraph()
        #expect(graph.isPlanar(using: .boyerMyrvold()))
    }
    
    @Test func testBoyerMyrvoldPlanarGraph() {
        let graph = createPlanarGraph()
        #expect(graph.isPlanar(using: .boyerMyrvold()))
    }
    
    @Test func testBoyerMyrvoldNonPlanarK5() {
        let graph = createNonPlanarGraph()
        #expect(!graph.isPlanar(using: .boyerMyrvold()))
    }
    
    @Test func testBoyerMyrvoldNonPlanarK33() {
        let graph = createK33Graph()
        #expect(!graph.isPlanar(using: .boyerMyrvold()))
    }
    
    // MARK: - Algorithm Consistency Tests
    
    @Test func testAlgorithmConsistency() {
        let planarGraph = createPlanarGraph()
        let nonPlanarGraph = createNonPlanarGraph()
        let k33Graph = createK33Graph()
        
        // All algorithms should agree on planar graphs
        let planarEuler = planarGraph.isPlanar(using: .eulerFormula())
        let planarLeftRight = planarGraph.isPlanar(using: .leftRight())
        let planarHopcroft = planarGraph.isPlanar(using: .hopcroftTarjan())
        let planarBoyer = planarGraph.isPlanar(using: .boyerMyrvold())
        
        #expect(planarEuler == planarLeftRight)
        #expect(planarLeftRight == planarHopcroft)
        #expect(planarHopcroft == planarBoyer)
        
        // All algorithms should agree on non-planar graphs
        let nonPlanarEuler = nonPlanarGraph.isPlanar(using: .eulerFormula())
        let nonPlanarLeftRight = nonPlanarGraph.isPlanar(using: .leftRight())
        let nonPlanarHopcroft = nonPlanarGraph.isPlanar(using: .hopcroftTarjan())
        let nonPlanarBoyer = nonPlanarGraph.isPlanar(using: .boyerMyrvold())
        
        #expect(nonPlanarEuler == nonPlanarLeftRight)
        #expect(nonPlanarLeftRight == nonPlanarHopcroft)
        #expect(nonPlanarHopcroft == nonPlanarBoyer)
        
        // K₃,₃ should be detected as non-planar
        let k33Euler = k33Graph.isPlanar(using: .eulerFormula())
        let k33LeftRight = k33Graph.isPlanar(using: .leftRight())
        let k33Hopcroft = k33Graph.isPlanar(using: .hopcroftTarjan())
        let k33Boyer = k33Graph.isPlanar(using: .boyerMyrvold())
        
        #expect(k33Euler == k33LeftRight)
        #expect(k33LeftRight == k33Hopcroft)
        #expect(k33Hopcroft == k33Boyer)
    }
    
    // MARK: - Performance Tests
    
    @Test func testPerformanceComparison() {
        let graph = createPlanarGraph()
        
        // This is a basic performance test - in practice, you'd want more sophisticated benchmarking
        let startTime = Date()
        
        for _ in 0..<100 {
            _ = graph.isPlanar(using: .eulerFormula())
        }
        
        let eulerTime = Date().timeIntervalSince(startTime)
        
        // The other algorithms should be reasonably fast too
        let startTime2 = Date()
        
        for _ in 0..<100 {
            _ = graph.isPlanar(using: .leftRight())
        }
        
        let leftRightTime = Date().timeIntervalSince(startTime2)
        
        // Basic assertion that both complete in reasonable time
        #expect(eulerTime < 1.0) // Should complete in less than 1 second
        #expect(leftRightTime < 1.0) // Should complete in less than 1 second
    }
}
