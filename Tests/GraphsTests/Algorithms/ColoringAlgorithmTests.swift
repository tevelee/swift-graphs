@testable import Graphs
import Testing

struct ColoringAlgorithmTests {
    
    // MARK: - Test Data
    
    func createTestGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        // Create a simple graph: A-B-C with A-D
        // A -- B -- C
        // |
        // D
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: d, to: a)
        
        return graph
    }
    
    func createCompleteGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        // Create a complete graph K4
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Add all possible edges
        let vertices = [a, b, c, d]
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                graph.addEdge(from: vertices[i], to: vertices[j])
                graph.addEdge(from: vertices[j], to: vertices[i])
            }
        }
        
        return graph
    }
    
    func createBipartiteGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        // Create a bipartite graph
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Connect A, B to C, D (bipartite)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: d, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: d, to: b)
        
        return graph
    }
    
    // MARK: - Greedy Algorithm Tests
    
    @Test func testGreedyColoring() {
        let graph = createTestGraph()
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
        // Should have a proper coloring
        #expect(coloring.isProper)
        
        // Should use at most 3 colors (graph has max degree 2)
        #expect(coloring.chromaticNumber <= 3)
        
        // All vertices should be colored
        let vertices = Array(graph.vertices())
        for vertex in vertices {
            #expect(coloring.color(for: vertex) != nil)
        }
    }
    
    @Test func testGreedyColoringCompleteGraph() {
        let graph = createCompleteGraph()
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
        // Should have a proper coloring
        #expect(coloring.isProper)
        
        // Complete graph K4 should use 4 colors
        #expect(coloring.chromaticNumber == 4)
        
        // All vertices should be colored
        let vertices = Array(graph.vertices())
        for vertex in vertices {
            #expect(coloring.color(for: vertex) != nil)
        }
    }
    
    @Test func testGreedyColoringBipartiteGraph() {
        let graph = createBipartiteGraph()
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
        // Should have a proper coloring
        #expect(coloring.isProper)
        
        // Bipartite graph should use at most 2 colors
        #expect(coloring.chromaticNumber <= 2)
        
        // All vertices should be colored
        let vertices = Array(graph.vertices())
        for vertex in vertices {
            #expect(coloring.color(for: vertex) != nil)
        }
    }
    
    // MARK: - DSatur Algorithm Tests
    
    @Test func testDSaturColoring() {
        let graph = createTestGraph()
        
        let coloring = graph.colorGraph(using: .dsatur(on: graph))
        
        // Should have a proper coloring
        #expect(coloring.isProper)
        
        // Should use at most 3 colors (graph has max degree 2)
        #expect(coloring.chromaticNumber <= 3)
        
        // All vertices should be colored
        let vertices = Array(graph.vertices())
        for vertex in vertices {
            #expect(coloring.color(for: vertex) != nil)
        }
    }
    
    @Test func testDSaturColoringCompleteGraph() {
        let graph = createCompleteGraph()
        
        let coloring = graph.colorGraph(using: .dsatur(on: graph))
        
        // Should have a proper coloring
        #expect(coloring.isProper)
        
        // Complete graph K4 should use 4 colors
        #expect(coloring.chromaticNumber == 4)
        
        // All vertices should be colored
        let vertices = Array(graph.vertices())
        for vertex in vertices {
            #expect(coloring.color(for: vertex) != nil)
        }
    }
    
    @Test func testDSaturColoringBipartiteGraph() {
        let graph = createBipartiteGraph()
        
        let coloring = graph.colorGraph(using: .dsatur(on: graph))
        
        // Should have a proper coloring
        #expect(coloring.isProper)
        
        // Bipartite graph should use at most 2 colors
        #expect(coloring.chromaticNumber <= 2)
        
        // All vertices should be colored
        let vertices = Array(graph.vertices())
        for vertex in vertices {
            #expect(coloring.color(for: vertex) != nil)
        }
    }
    
    // MARK: - Welsh-Powell Algorithm Tests
    
    @Test func testWelshPowellColoring() {
        let graph = createTestGraph()
        
        let coloring = graph.colorGraph(using: .welshPowell(on: graph))
        
        // Should have a proper coloring
        #expect(coloring.isProper)
        
        // Should use at most 3 colors (graph has max degree 2)
        #expect(coloring.chromaticNumber <= 3)
        
        // All vertices should be colored
        let vertices = Array(graph.vertices())
        for vertex in vertices {
            #expect(coloring.color(for: vertex) != nil)
        }
    }
    
    @Test func testWelshPowellColoringCompleteGraph() {
        let graph = createCompleteGraph()
        
        let coloring = graph.colorGraph(using: .welshPowell(on: graph))
        
        // Should have a proper coloring
        #expect(coloring.isProper)
        
        // Complete graph K4 should use 4 colors
        #expect(coloring.chromaticNumber == 4)
        
        // All vertices should be colored
        let vertices = Array(graph.vertices())
        for vertex in vertices {
            #expect(coloring.color(for: vertex) != nil)
        }
    }
    
    @Test func testWelshPowellColoringBipartiteGraph() {
        let graph = createBipartiteGraph()
        
        let coloring = graph.colorGraph(using: .welshPowell(on: graph))
        
        // Should have a proper coloring
        #expect(coloring.isProper)
        
        // Bipartite graph should use at most 2 colors
        #expect(coloring.chromaticNumber <= 2)
        
        // All vertices should be colored
        let vertices = Array(graph.vertices())
        for vertex in vertices {
            #expect(coloring.color(for: vertex) != nil)
        }
    }
    
    // MARK: - Algorithm Comparison Tests
    
    @Test func testAllAlgorithmsProduceProperColoring() {
        let graph = createTestGraph()
        
        let greedyColoring = graph.colorGraph(using: .greedy(on: graph))
        let dsaturColoring = graph.colorGraph(using: .dsatur(on: graph))
        let welshPowellColoring = graph.colorGraph(using: .welshPowell(on: graph))
        
        // All algorithms should produce proper colorings
        #expect(greedyColoring.isProper)
        #expect(dsaturColoring.isProper)
        #expect(welshPowellColoring.isProper)
        
        // All algorithms should color all vertices
        let vertices = Array(graph.vertices())
        for vertex in vertices {
            #expect(greedyColoring.color(for: vertex) != nil)
            #expect(dsaturColoring.color(for: vertex) != nil)
            #expect(welshPowellColoring.color(for: vertex) != nil)
        }
    }
    
    // MARK: - Edge Cases
    
    @Test func testEmptyGraph() {
        let graph = AdjacencyList()
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
        // Empty graph should have no colors and be proper
        #expect(coloring.chromaticNumber == 0)
        #expect(coloring.isProper)
        #expect(coloring.vertexColors.isEmpty)
    }
    
    @Test func testSingleVertexGraph() {
        var graph = AdjacencyList()
        
        let vertex = graph.addVertex { $0.label = "A" }
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
        // Single vertex should use 1 color and be proper
        #expect(coloring.chromaticNumber == 1)
        #expect(coloring.isProper)
        #expect(coloring.color(for: vertex) != nil)
    }
    
    @Test func testTwoVertexGraph() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
        // Two connected vertices should use 2 colors and be proper
        #expect(coloring.chromaticNumber == 2)
        #expect(coloring.isProper)
        #expect(coloring.color(for: a) != nil)
        #expect(coloring.color(for: b) != nil)
        #expect(coloring.color(for: a) != coloring.color(for: b))
    }
    
    @Test func testDisconnectedGraph() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Two disconnected components
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
        // Disconnected graph should use 2 colors and be proper
        #expect(coloring.chromaticNumber == 2)
        #expect(coloring.isProper)
        
        // All vertices should be colored
        let vertices = [a, b, c, d]
        for vertex in vertices {
            #expect(coloring.color(for: vertex) != nil)
        }
    }
}
