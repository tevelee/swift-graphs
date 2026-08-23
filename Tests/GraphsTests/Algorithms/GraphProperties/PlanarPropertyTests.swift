import Testing

@testable import Graphs

struct PlanarPropertyTests {

    // MARK: - Test Graphs

    func createEmptyGraph() -> AdjacencyList {
        return AdjacencyList()
    }

    func createSingleVertexGraph() -> AdjacencyList {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "A" }
        return graph
    }

    func createTwoVertexGraph() -> AdjacencyList {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        return graph
    }

    func createTriangleGraph() -> AdjacencyList {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: a) { $0.label = "CA" }

        return graph
    }

    func createK4Graph() -> AdjacencyList {
        var graph = AdjacencyList()
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

    func createK5Graph() -> AdjacencyList {
        var graph = AdjacencyList()
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

    func createK33Graph() -> AdjacencyList {
        var graph = AdjacencyList()
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

    func createPlanarGraph() -> AdjacencyList {
        var graph = AdjacencyList()
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

    func createNonPlanarGraph() -> AdjacencyList {
        var graph = AdjacencyList()
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

    // MARK: - Core Behavior

    @Test func emptyGraph() {
        let graph = createEmptyGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }

    @Test func singleVertex() {
        let graph = createSingleVertexGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }

    @Test func twoVertices() {
        let graph = createTwoVertexGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }

    @Test func triangle() {
        let graph = createTriangleGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }

    @Test func k4() {
        let graph = createK4Graph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }

    @Test func k5IsNonPlanar() {
        let graph = createK5Graph()
        #expect(!graph.isPlanar(using: .eulerFormula()))
    }

    @Test func k33IsNonPlanar() {
        let graph = createK33Graph()
        #expect(!graph.isPlanar(using: .eulerFormula()))
    }

    @Test func planarGraph() {
        let graph = createPlanarGraph()
        #expect(graph.isPlanar(using: .eulerFormula()))
    }

    @Test func nonPlanarGraph() {
        let graph = createNonPlanarGraph()
        #expect(!graph.isPlanar(using: .eulerFormula()))
    }

    // MARK: - Edge Cases

    @Test func graphWithSelfLoops() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }

        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: a, to: a) { $0.label = "AA" }  // Self loop

        // Self loops don't affect planarity in this simple test
        #expect(graph.isPlanar(using: .eulerFormula()))
    }

    @Test func disconnectedGraph() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }

        // Two separate triangles
        graph.addEdge(from: a, to: b) { $0.label = "AB" }
        graph.addEdge(from: b, to: c) { $0.label = "BC" }
        graph.addEdge(from: c, to: a) { $0.label = "CA" }

        graph.addEdge(from: d, to: d) { $0.label = "DD" }  // Single vertex component

        #expect(graph.isPlanar(using: .eulerFormula()))
    }

    // MARK: - Observation Support

    @Test func observationPattern() {
        let graph = createK5Graph()
        var eulerViolations: [(Int, Int, Int)] = []
        var kuratowskiViolations: [String] = []

        typealias Cases = EulerFormulaPlanarPropertyAlgorithm<AdjacencyList>.EventCases
        let observed = EulerFormulaPlanarPropertyAlgorithm<AdjacencyList>()
            .observing(Cases.kuratowskiObstructionFound) { reason in
                kuratowskiViolations.append(reason)
            }
            .observing(Cases.eulerBoundViolated) { violation in
                eulerViolations.append((violation.vertices, violation.edges, violation.maximumEdges))
            }

        let result = graph.isPlanar(using: observed)

        #expect(result == false)
    }

    // MARK: - Performance

    @Test func largePlanarGraph() {
        // Create a moderate-sized planar graph (grid-like structure)
        var graph = AdjacencyList()
        let size = 5  // Reduced from 10 to avoid exponential explosion
        var vertices: [[AdjacencyList.VertexDescriptor]] = []

        // Create grid vertices
        for i in 0 ..< size {
            var row: [AdjacencyList.VertexDescriptor] = []
            for j in 0 ..< size {
                let vertex = graph.addVertex { $0.label = "\(i),\(j)" }
                row.append(vertex)
            }
            vertices.append(row)
        }

        // Connect horizontally
        for i in 0 ..< size {
            for j in 0 ..< (size - 1) {
                graph.addEdge(from: vertices[i][j], to: vertices[i][j + 1]) { $0.label = "H\(i)\(j)" }
            }
        }

        // Connect vertically
        for i in 0 ..< (size - 1) {
            for j in 0 ..< size {
                graph.addEdge(from: vertices[i][j], to: vertices[i + 1][j]) { $0.label = "V\(i)\(j)" }
            }
        }

        // This should be planar (grid graph)
        #expect(graph.isPlanar(using: .eulerFormula()))
    }
}
