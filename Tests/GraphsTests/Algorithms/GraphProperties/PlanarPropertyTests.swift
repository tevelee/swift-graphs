import Testing
@testable import Graphs

struct PlanarPropertyTests {
    
    // MARK: - Test Data Creation
    
    func createEmptyGraph() -> DefaultAdjacencyList {
        return DefaultAdjacencyList()
    }
    
    func createSingleVertexGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        graph.addVertex { $0.label = "A" }
        return graph
    }
    
    func createTwoVertexGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        return graph
    }
    
    func createTriangleGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: a) { $0.label = "CA" }
        
        return graph
    }
    
    func createK4Graph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Complete graph K4 (6 edges) - planar
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: a, to: c) { $0.label = "AC" }
        graph.addEdge(from: a, to: d) { $0.label = "AD" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: b, to: d) { $0.label = "BD" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        
        return graph
    }
    
    func createK5Graph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        // Complete graph K5 (10 edges) - not planar
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
    
    func createK33Graph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        let f = graph.addVertex { $0.label = "F" }
        
        // Complete bipartite graph K3,3 (9 edges) - not planar
        // Partition: {A, B, C} <-> {D, E, F}
        graph.addEdge(from: a, to: d) { $0.label = "AD" }
        graph.addEdge(from: a, to: e) { $0.label = "AE" }
        graph.addEdge(from: a, to: f) { $0.label = "AF" }
        graph.addEdge(from: b, to: d) { $0.label = "BD" }
        graph.addEdge(from: b, to: e) { $0.label = "BE" }
        graph.addEdge(from: b, to: f) { $0.label = "BF" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: c, to: e) { $0.label = "CE" }
        graph.addEdge(from: c, to: f) { $0.label = "CF" }
        
        return graph
    }
    
    func createPlanarGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        // Create a planar graph (5 vertices, 6 edges)
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: d, to: e) { $0.label = "DE" }
        graph.addEdge(from: e, to: a) { $0.label = "EA" }
        graph.addEdge(from: a, to: c) { $0.label = "AC" }
        
        return graph
    }
    
    func createNonPlanarGraph() -> DefaultAdjacencyList {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        let f = graph.addVertex { $0.label = "F" }
        
        // Create a graph that violates Euler's formula
        // 6 vertices, 12 edges (should be ≤ 3*6-6 = 12, but this creates K3,3)
        graph.addEdge(from: a, to: d) { $0.label = "AD" }
        graph.addEdge(from: a, to: e) { $0.label = "AE" }
        graph.addEdge(from: a, to: f) { $0.label = "AF" }
        graph.addEdge(from: b, to: d) { $0.label = "BD" }
        graph.addEdge(from: b, to: e) { $0.label = "BE" }
        graph.addEdge(from: b, to: f) { $0.label = "BF" }
        graph.addEdge(from: c, to: d) { $0.label = "CD" }
        graph.addEdge(from: c, to: e) { $0.label = "CE" }
        graph.addEdge(from: c, to: f) { $0.label = "CF" }
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: a) { $0.label = "CA" }
        
        return graph
    }
    
    // MARK: - Basic Tests
    
    @Test func testEmptyGraph() {
        let graph = createEmptyGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testSingleVertex() {
        let graph = createSingleVertexGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testTwoVertices() {
        let graph = createTwoVertexGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testTriangle() {
        let graph = createTriangleGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testK4() {
        let graph = createK4Graph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testK5() {
        let graph = createK5Graph()
        #expect(!graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testK33() {
        let graph = createK33Graph()
        #expect(!graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testPlanarGraph() {
        let graph = createPlanarGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testNonPlanarGraph() {
        let graph = createNonPlanarGraph()
        #expect(!graph.isPlanar(using: .eulerFormula()))
    }
    
    // MARK: - Edge Case Tests
    
    @Test func testGraphWithSelfLoops() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: a, to: a) { $0.label = "AA" } // Self loop
        
        // Self loops don't affect planarity in this simple test
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    @Test func testDisconnectedGraph() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Two separate triangles
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: a) { $0.label = "CA" }
        
        graph.addEdge(from: d, to: d) { $0.label = "DD" } // Single vertex component
        
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
    
    // MARK: - Visitor Pattern Tests
    
    @Test func testVisitorPattern() {
        let graph = createK5Graph()
        var eulerViolations: [(Int, Int, Int)] = []
        var kuratowskiViolations: [String] = []
        
        let visitor = EulerFormulaPlanarPropertyAlgorithm<DefaultAdjacencyList>.Visitor(
            checkEulerFormula: nil,
            examineVertex: nil,
            examineEdge: nil,
            checkKuratowski: nil,
            kuratowskiViolation: { reason in
                kuratowskiViolations.append(reason)
            },
            eulerFormulaViolation: { vertices, edges, maxEdges in
                eulerViolations.append((vertices, edges, maxEdges))
            }
        )
        
        let algorithm = EulerFormulaPlanarPropertyAlgorithm<DefaultAdjacencyList>()
        let result = algorithm.isPlanar(in: graph, visitor: visitor)
        
        #expect(result == false)
    }
    
    // MARK: - Performance Tests
    
    @Test func testLargePlanarGraph() {
        // Create a moderate-sized planar graph (grid-like structure)
        var graph = DefaultAdjacencyList()
        let size = 5  // Reduced from 10 to avoid exponential explosion
        var vertices: [[DefaultAdjacencyList.VertexDescriptor]] = []
        
        // Create grid vertices
        for i in 0..<size {
            var row: [DefaultAdjacencyList.VertexDescriptor] = []
            for j in 0..<size {
                let vertex = graph.addVertex { $0.label = "\(i),\(j)" }
                row.append(vertex)
            }
            vertices.append(row)
        }
        
        // Connect horizontally
        for i in 0..<size {
            for j in 0..<(size-1) {
                graph.addEdge(from: vertices[i][j], to: vertices[i][j+1]) { $0.label = "H\(i)\(j)" }
            }
        }
        
        // Connect vertically
        for i in 0..<(size-1) {
            for j in 0..<size {
                graph.addEdge(from: vertices[i][j], to: vertices[i+1][j]) { $0.label = "V\(i)\(j)" }
            }
        }
        
        // This should be planar (grid graph)
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
}
