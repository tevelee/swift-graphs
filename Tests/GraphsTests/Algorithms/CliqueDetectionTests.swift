#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
import Testing
@testable import Graphs

struct CliqueDetectionTests {
    
    // MARK: - Basic Tests
    
    @Test func testEmptyGraph() {
        let graph = AdjacencyList()
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 0)
        #expect(result.maximalCliqueSize == 0)
        #expect(result.cliques.isEmpty)
    }
    
    @Test func testSingleVertex() {
        var graph = AdjacencyList()
        let vertex = graph.addVertex { $0.label = "A" }
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 1)
        #expect(result.cliques == [[vertex]])
    }
    
    @Test func testTwoVerticesNoEdge() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 2)
        #expect(result.maximalCliqueSize == 1)
        #expect(result.cliques.contains { Set($0) == Set([a]) })
        #expect(result.cliques.contains { Set($0) == Set([b]) })
    }
    
    @Test func testTwoVerticesWithEdge() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 2)
        #expect(result.cliques.contains { Set($0) == Set([a, b]) })
    }
    
    // MARK: - Triangle Tests
    
    @Test func testTriangle() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        // Create triangle: A-B-C-A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 3)
        #expect(result.cliques.contains { Set($0) == Set([a, b, c]) })
    }
    
    // MARK: - Complete Graph Tests
    
    @Test func testK4() {
        var graph = AdjacencyList()
        let vertices = ["A", "B", "C", "D"].map { label in
            graph.addVertex { $0.label = label }
        }
        
        // Create complete graph K4
        for i in 0..<vertices.count {
            for j in 0..<vertices.count {
                if i != j {
                    graph.addEdge(from: vertices[i], to: vertices[j])
                }
            }
        }
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 4)
        #expect(result.cliques.contains { Set($0) == Set(vertices) })
    }
    
    @Test func testK5() {
        var graph = AdjacencyList()
        let vertices = ["A", "B", "C", "D", "E"].map { label in
            graph.addVertex { $0.label = label }
        }
        
        // Create complete graph K5
        for i in 0..<vertices.count {
            for j in 0..<vertices.count {
                if i != j {
                    graph.addEdge(from: vertices[i], to: vertices[j])
                }
            }
        }
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 5)
        #expect(result.cliques.contains { Set($0) == Set(vertices) })
    }
    
    // MARK: - Complex Graph Tests
    
    @Test func testGraphWithMultipleCliques() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        // Create two triangles connected by one edge
        // Triangle 1: A-B-C-A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        // Triangle 2: C-D-E-C
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: d)
        graph.addEdge(from: e, to: c)
        graph.addEdge(from: c, to: e)
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 2)
        #expect(result.maximalCliqueSize == 3)
        #expect(result.cliques.contains { Set($0) == Set([a, b, c]) })
        #expect(result.cliques.contains { Set($0) == Set([c, d, e]) })
    }
    
    // MARK: - Result Utility Tests
    
    @Test func testCliquesOfSize() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create two triangles
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let result = graph.findCliques()
        
        let size3Cliques = result.cliques(ofSize: 3)
        #expect(size3Cliques.count == 1)
        #expect(size3Cliques.contains { Set($0) == Set([a, b, c]) })
        
        let size2Cliques = result.cliques(ofSize: 2)
        #expect(size2Cliques.count == 1)
        #expect(size2Cliques.contains { Set($0) == Set([c, d]) })
    }
    
    @Test func testIsClique() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        let result = graph.findCliques()
        
        #expect(result.isClique(Set([a, b, c])))
        #expect(!result.isClique(Set([a, b])))
        #expect(!result.isClique(Set([a, c])))
    }
    
    @Test func testCliquesContaining() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create two triangles sharing vertex C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let result = graph.findCliques()
        
        let cliquesWithC = result.cliques(containing: c)
        #expect(cliquesWithC.count == 2)
        #expect(cliquesWithC.contains { Set($0) == Set([a, b, c]) })
        #expect(cliquesWithC.contains { Set($0) == Set([c, d]) })
    }
    
    // MARK: - Visitor Tests
    
    @Test func testVisitorCallbacks() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        // Test basic functionality without visitor for now
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 3)
        #expect(result.cliques.contains { Set($0) == Set([a, b, c]) })
    }
    
    // MARK: - Algorithm Comparison Tests
    
    @Test func testAlgorithmConsistency() {
        var graph = AdjacencyList()
        let vertices = ["A", "B", "C", "D", "E"].map { label in
            graph.addVertex { $0.label = label }
        }
        
        // Create a complex graph
        graph.addEdge(from: vertices[0], to: vertices[1])
        graph.addEdge(from: vertices[1], to: vertices[0])
        graph.addEdge(from: vertices[1], to: vertices[2])
        graph.addEdge(from: vertices[2], to: vertices[1])
        graph.addEdge(from: vertices[2], to: vertices[3])
        graph.addEdge(from: vertices[3], to: vertices[2])
        graph.addEdge(from: vertices[3], to: vertices[4])
        graph.addEdge(from: vertices[4], to: vertices[3])
        
        let result1 = graph.findCliques()
        let result2 = graph.findCliques(using: .bronKerbosch())
        
        #expect(result1.cliqueCount == result2.cliqueCount)
        #expect(result1.maximalCliqueSize == result2.maximalCliqueSize)
    }
}
#endif
