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
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 0)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    @Test func testGreedyColoringCompleteGraph() {
        let graph = createCompleteGraph()
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 4)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 2)
        #expect(coloring.color(for: vertices[3]) == 3)
    }
    
    @Test func testGreedyColoringBipartiteGraph() {
        let graph = createBipartiteGraph()
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 0)
        #expect(coloring.color(for: vertices[2]) == 1)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    // MARK: - DSatur Algorithm Tests
    
    @Test func testDSaturColoring() {
        let graph = createTestGraph()
        
        let coloring = graph.colorGraph(using: .dsatur(on: graph))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 0)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    @Test func testDSaturColoringCompleteGraph() {
        let graph = createCompleteGraph()
        
        let coloring = graph.colorGraph(using: .dsatur(on: graph))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 4)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 2)
        #expect(coloring.color(for: vertices[3]) == 3)
    }
    
    @Test func testDSaturColoringBipartiteGraph() {
        let graph = createBipartiteGraph()
        
        let coloring = graph.colorGraph(using: .dsatur(on: graph))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 0)
        #expect(coloring.color(for: vertices[2]) == 1)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    // MARK: - Welsh-Powell Algorithm Tests
    
    @Test func testWelshPowellColoring() {
        let graph = createTestGraph()
        
        let coloring = graph.colorGraph(using: .welshPowell(on: graph))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 0)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    @Test func testWelshPowellColoringCompleteGraph() {
        let graph = createCompleteGraph()
        
        let coloring = graph.colorGraph(using: .welshPowell(on: graph))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 4)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 2)
        #expect(coloring.color(for: vertices[3]) == 3)
    }
    
    @Test func testWelshPowellColoringBipartiteGraph() {
        let graph = createBipartiteGraph()
        
        let coloring = graph.colorGraph(using: .welshPowell(on: graph))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 0)
        #expect(coloring.color(for: vertices[2]) == 1)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    // MARK: - Algorithm Comparison Tests
    
    @Test func testAllAlgorithmsProduceProperColoring() {
        let graph = createTestGraph()
        
        let greedyColoring = graph.colorGraph(using: .greedy(on: graph))
        let dsaturColoring = graph.colorGraph(using: .dsatur(on: graph))
        let welshPowellColoring = graph.colorGraph(using: .welshPowell(on: graph))
        
        #expect(greedyColoring.isProper)
        #expect(dsaturColoring.isProper)
        #expect(welshPowellColoring.isProper)
        
        let vertices = Array(graph.vertices())
        #expect(greedyColoring.color(for: vertices[0]) == 0)
        #expect(greedyColoring.color(for: vertices[1]) == 1)
        #expect(greedyColoring.color(for: vertices[2]) == 0)
        #expect(greedyColoring.color(for: vertices[3]) == 1)
        #expect(dsaturColoring.color(for: vertices[0]) == 0)
        #expect(dsaturColoring.color(for: vertices[1]) == 1)
        #expect(dsaturColoring.color(for: vertices[2]) == 0)
        #expect(dsaturColoring.color(for: vertices[3]) == 1)
        #expect(welshPowellColoring.color(for: vertices[0]) == 0)
        #expect(welshPowellColoring.color(for: vertices[1]) == 1)
        #expect(welshPowellColoring.color(for: vertices[2]) == 0)
        #expect(welshPowellColoring.color(for: vertices[3]) == 1)
    }
    
    // MARK: - Edge Cases
    
    @Test func testEmptyGraph() {
        let graph = AdjacencyList()
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
        #expect(coloring.chromaticNumber == 0)
        #expect(coloring.isProper)
        #expect(coloring.vertexColors.isEmpty)
    }
    
    @Test func testSingleVertexGraph() {
        var graph = AdjacencyList()
        
        let vertex = graph.addVertex { $0.label = "A" }
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
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
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let coloring = graph.colorGraph(using: .greedy(on: graph))
        
        #expect(coloring.chromaticNumber == 2)
        #expect(coloring.isProper)
        
        #expect(coloring.color(for: a) == 0)
        #expect(coloring.color(for: b) == 1)
        #expect(coloring.color(for: c) == 0)
        #expect(coloring.color(for: d) == 1)
    }
    
    // MARK: - Sequential Vertex Coloring Tests
    
    @Test func testSequentialVertexColoringWithSmallestLastOrdering() {
        let graph = createTestGraph()
        let coloring = graph.colorGraph(using: .sequential(orderUsing: .reverseCuthillMcKee()))
        
        // Should be a proper coloring
        #expect(coloring.isProper)
        
        // Should use at most 4 colors (graph has 4 vertices)
        #expect(coloring.chromaticNumber <= 4)
        
        // All vertices should be colored
        #expect(coloring.vertexColors.count == 4)
        
        // Check that no adjacent vertices have the same color
        for vertex in graph.vertices() {
            guard let vertexColor = coloring.color(for: vertex) else {
                Issue.record("Vertex \(vertex) should be colored")
                continue
            }
            
            for neighbor in graph.successors(of: vertex) {
                guard let neighborColor = coloring.color(for: neighbor) else {
                    continue
                }
                #expect(vertexColor != neighborColor, 
                       "Adjacent vertices \(vertex) and \(neighbor) have the same color")
            }
        }
    }
    
    @Test func testSequentialVertexColoringWithReverseCuthillMcKeeOrdering() {
        let graph = createTestGraph()
        let coloring = graph.colorGraph(using: .sequential(orderUsing: .smallestLastVertex()))
        
        // Should be a proper coloring
        #expect(coloring.isProper)
        
        // Should use at most 4 colors (graph has 4 vertices)
        #expect(coloring.chromaticNumber <= 4)
        
        // All vertices should be colored
        #expect(coloring.vertexColors.count == 4)
    }
    
    @Test func testSequentialVertexColoringEmptyGraph() {
        let graph = AdjacencyList()
        let coloring = graph.colorGraph(using: .sequential(orderUsing: .reverseCuthillMcKee()))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 0)
        #expect(coloring.vertexColors.isEmpty)
    }
    
    @Test func testSequentialVertexColoringSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        
        let coloring = graph.colorGraph(using: .sequential(orderUsing: .reverseCuthillMcKee()))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 1)
        #expect(coloring.vertexColors.count == 1)
        #expect(coloring.color(for: a) != nil)
    }
    
    @Test func testSequentialVertexColoringDisconnectedGraph() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: d)
        
        let coloring = graph.colorGraph(using: .sequential(orderUsing: .reverseCuthillMcKee()))
        
        // Should be a proper coloring
        #expect(coloring.isProper)
        
        // Should use at most 5 colors (graph has 5 vertices)
        #expect(coloring.chromaticNumber <= 5)
        
        // All vertices should be colored
        #expect(coloring.vertexColors.count == 5)
        
        // Check that no adjacent vertices have the same color
        for vertex in graph.vertices() {
            guard let vertexColor = coloring.color(for: vertex) else {
                Issue.record("Vertex \(vertex) should be colored")
                continue
            }
            
            for neighbor in graph.successors(of: vertex) {
                guard let neighborColor = coloring.color(for: neighbor) else {
                    continue
                }
                #expect(vertexColor != neighborColor, 
                       "Adjacent vertices \(vertex) and \(neighbor) have the same color")
            }
        }
    }
    
    @Test func testSequentialVertexColoringConvenienceExtensions() {
        let graph = createTestGraph()
        
        // Test sequential coloring convenience
        let coloring1 = graph.colorGraph(using: .sequential(orderUsing: .reverseCuthillMcKee()))
        #expect(coloring1.isProper)
        
        let coloring2 = graph.colorGraph(using: .sequential(orderUsing: .smallestLastVertex()))
        #expect(coloring2.isProper)
    }
    
    @Test func testSequentialVertexColoringWithCustomOrdering() {
        let graph = createTestGraph()
        
        // Test with smallest last ordering
        let coloring1 = graph.colorGraph(using: .sequential(orderUsing: .reverseCuthillMcKee()))
        #expect(coloring1.isProper)
        
        // Test with reverse Cuthill-McKee ordering
        let coloring2 = graph.colorGraph(using: .sequential(orderUsing: .smallestLastVertex()))
        #expect(coloring2.isProper)
        
        // Both colorings should be valid, but may use different numbers of colors
        #expect(coloring1.chromaticNumber <= 4)
        #expect(coloring2.chromaticNumber <= 4)
    }
    
    // MARK: - Example Tests
    
    @Test func testColoringExample() {
        // Create a sample graph - pentagon
        var graph = AdjacencyList()
        
        // Add vertices
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        // Add edges to create a pentagon
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: d)
        graph.addEdge(from: e, to: a)
        graph.addEdge(from: a, to: e)
        
        // Test Greedy coloring
        let greedyColoring = graph.colorGraph(using: .greedy(on: graph))
        #expect(greedyColoring.isProper)
        #expect(greedyColoring.chromaticNumber == 3)
        
        // Test DSatur coloring
        let dsaturColoring = graph.colorGraph(using: .dsatur(on: graph))
        #expect(dsaturColoring.isProper)
        #expect(dsaturColoring.chromaticNumber == 3)
        
        // Test Welsh-Powell coloring
        let welshPowellColoring = graph.colorGraph(using: .welshPowell(on: graph))
        #expect(welshPowellColoring.isProper)
        #expect(welshPowellColoring.chromaticNumber == 3)
        
        // Test with a complete graph K4
        var k4Graph = AdjacencyList()
        let v1 = k4Graph.addVertex { $0.label = "V1" }
        let v2 = k4Graph.addVertex { $0.label = "V2" }
        let v3 = k4Graph.addVertex { $0.label = "V3" }
        let v4 = k4Graph.addVertex { $0.label = "V4" }
        
        // Add all possible edges
        let vertices = [v1, v2, v3, v4]
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                k4Graph.addEdge(from: vertices[i], to: vertices[j])
                k4Graph.addEdge(from: vertices[j], to: vertices[i])
            }
        }
        
        let k4Coloring = k4Graph.colorGraph(using: .greedy(on: k4Graph))
        #expect(k4Coloring.isProper)
        #expect(k4Coloring.chromaticNumber == 4) // Complete graph K4 needs exactly 4 colors
    }
}
