#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
@testable import Graphs
import Testing

struct ColoringAlgorithmTests {
    
    // MARK: - Test Graphs
    
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
    
    // MARK: - Core Behavior (Greedy)
    
    @Test func greedyColoring() {
        let graph = createTestGraph()
        
        let coloring = graph.colorGraph(using: .greedy())
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 0)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    @Test func greedyColoringCompleteGraph() {
        let graph = createCompleteGraph()
        
        let coloring = graph.colorGraph(using: .greedy())
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 4)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 2)
        #expect(coloring.color(for: vertices[3]) == 3)
    }
    
    @Test func greedyColoringBipartiteGraph() {
        let graph = createBipartiteGraph()
        
        let coloring = graph.colorGraph(using: .greedy())
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 0)
        #expect(coloring.color(for: vertices[2]) == 1)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    // MARK: - Core Behavior (DSatur)
    
    @Test func dsaturColoring() {
        let graph = createTestGraph()
        
        let coloring = graph.colorGraph(using: .dsatur())
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 0)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    @Test func dsaturColoringCompleteGraph() {
        let graph = createCompleteGraph()
        
        let coloring = graph.colorGraph(using: .dsatur())
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 4)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 2)
        #expect(coloring.color(for: vertices[3]) == 3)
    }
    
    @Test func dsaturColoringBipartiteGraph() {
        let graph = createBipartiteGraph()
        
        let coloring = graph.colorGraph(using: .dsatur())
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 0)
        #expect(coloring.color(for: vertices[2]) == 1)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    // MARK: - Core Behavior (Welsh-Powell)
    
    @Test func welshPowellColoring() {
        let graph = createTestGraph()
        
        let coloring = graph.colorGraph(using: .welshPowell())
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 0)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    @Test func welshPowellColoringCompleteGraph() {
        let graph = createCompleteGraph()
        
        let coloring = graph.colorGraph(using: .welshPowell())
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 4)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 1)
        #expect(coloring.color(for: vertices[2]) == 2)
        #expect(coloring.color(for: vertices[3]) == 3)
    }
    
    @Test func welshPowellColoringBipartiteGraph() {
        let graph = createBipartiteGraph()
        
        let coloring = graph.colorGraph(using: .welshPowell())
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 2)
        
        let vertices = Array(graph.vertices())
        #expect(coloring.color(for: vertices[0]) == 0)
        #expect(coloring.color(for: vertices[1]) == 0)
        #expect(coloring.color(for: vertices[2]) == 1)
        #expect(coloring.color(for: vertices[3]) == 1)
    }
    
    // MARK: - Algorithm Comparison
    
    @Test func allAlgorithmsProduceProperColoring() {
        let graph = createTestGraph()
        
        let greedyColoring = graph.colorGraph(using: .greedy())
        let dsaturColoring = graph.colorGraph(using: .dsatur())
        let welshPowellColoring = graph.colorGraph(using: .welshPowell())
        
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
    
    @Test func emptyGraph() {
        let graph = AdjacencyList()
        
        let coloring = graph.colorGraph(using: .greedy())
        
        #expect(coloring.chromaticNumber == 0)
        #expect(coloring.isProper)
        #expect(coloring.vertexColors.isEmpty)
    }
    
    @Test func singleVertexGraph() {
        var graph = AdjacencyList()
        
        let vertex = graph.addVertex { $0.label = "A" }
        
        let coloring = graph.colorGraph(using: .greedy())
        
        #expect(coloring.chromaticNumber == 1)
        #expect(coloring.isProper)
        #expect(coloring.color(for: vertex) != nil)
    }
    
    @Test func twoVertexGraph() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        let coloring = graph.colorGraph(using: .greedy())
        
        #expect(coloring.chromaticNumber == 2)
        #expect(coloring.isProper)
        #expect(coloring.color(for: a) != nil)
        #expect(coloring.color(for: b) != nil)
        #expect(coloring.color(for: a) != coloring.color(for: b))
    }
    
    @Test func disconnectedGraph() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let coloring = graph.colorGraph(using: .greedy())
        
        #expect(coloring.chromaticNumber == 2)
        #expect(coloring.isProper)
        
        #expect(coloring.color(for: a) == 0)
        #expect(coloring.color(for: b) == 1)
        #expect(coloring.color(for: c) == 0)
        #expect(coloring.color(for: d) == 1)
    }
    
    // MARK: - Core Behavior (Sequential)
    
    @Test func sequentialColoringWithSmallestLastOrdering() {
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
    
    @Test func sequentialColoringWithReverseCuthillMcKeeOrdering() {
        let graph = createTestGraph()
        let coloring = graph.colorGraph(using: .sequential(orderUsing: .smallestLastVertex()))
        
        // Should be a proper coloring
        #expect(coloring.isProper)
        
        // Should use at most 4 colors (graph has 4 vertices)
        #expect(coloring.chromaticNumber <= 4)
        
        // All vertices should be colored
        #expect(coloring.vertexColors.count == 4)
    }
    
    @Test func sequentialColoringEmptyGraph() {
        let graph = AdjacencyList()
        let coloring = graph.colorGraph(using: .sequential(orderUsing: .reverseCuthillMcKee()))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 0)
        #expect(coloring.vertexColors.isEmpty)
    }
    
    @Test func sequentialColoringSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        
        let coloring = graph.colorGraph(using: .sequential(orderUsing: .reverseCuthillMcKee()))
        
        #expect(coloring.isProper)
        #expect(coloring.chromaticNumber == 1)
        #expect(coloring.vertexColors.count == 1)
        #expect(coloring.color(for: a) != nil)
    }
    
    @Test func sequentialColoringDisconnectedGraph() {
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
    
    @Test func sequentialColoringConvenienceExtensions() {
        let graph = createTestGraph()
        
        // Test sequential coloring convenience
        let coloring1 = graph.colorGraph(using: .sequential(orderUsing: .reverseCuthillMcKee()))
        #expect(coloring1.isProper)
        
        let coloring2 = graph.colorGraph(using: .sequential(orderUsing: .smallestLastVertex()))
        #expect(coloring2.isProper)
    }
    
    @Test func sequentialColoringWithCustomOrdering() {
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
    
    // MARK: - Examples
    
    @Test func coloringExample() {
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
        let greedyColoring = graph.colorGraph(using: .greedy())
        #expect(greedyColoring.isProper)
        #expect(greedyColoring.chromaticNumber == 3)
        
        // Test DSatur coloring
        let dsaturColoring = graph.colorGraph(using: .dsatur())
        #expect(dsaturColoring.isProper)
        #expect(dsaturColoring.chromaticNumber == 3)
        
        // Test Welsh-Powell coloring
        let welshPowellColoring = graph.colorGraph(using: .welshPowell())
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
        
        let k4Coloring = k4Graph.colorGraph(using: .greedy())
        #expect(k4Coloring.isProper)
        #expect(k4Coloring.chromaticNumber == 4) // Complete graph K4 needs exactly 4 colors
    }

    // MARK: - Multi-Backend Coverage

    @Test func greedyColoringIsProper_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            // Bipartite graph: a-b, a-c, b-d, c-d (diamond without a→d direct)
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            let d = graph.addVertex { $0.label = "d" }
            graph.addEdge(from: a, to: b); graph.addEdge(from: b, to: a)
            graph.addEdge(from: a, to: c); graph.addEdge(from: c, to: a)
            graph.addEdge(from: b, to: d); graph.addEdge(from: d, to: b)
            graph.addEdge(from: c, to: d); graph.addEdge(from: d, to: c)

            let coloring = graph.colorGraph(using: .greedy())
            #expect(coloring.isProper, "[\(backend)] greedy coloring must be proper (no two adjacent vertices share a color)")
            #expect(coloring.chromaticNumber == 2, "[\(backend)] bipartite diamond needs exactly 2 colors")
            #expect(coloring.vertexColors.count == 4, "[\(backend)] all 4 vertices colored")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func allColoringAlgorithmsProduceProperColoring_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            // Pentagon (5-cycle): chromatic number is 3
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            let d = graph.addVertex { $0.label = "d" }
            let e = graph.addVertex { $0.label = "e" }
            graph.addEdge(from: a, to: b); graph.addEdge(from: b, to: a)
            graph.addEdge(from: b, to: c); graph.addEdge(from: c, to: b)
            graph.addEdge(from: c, to: d); graph.addEdge(from: d, to: c)
            graph.addEdge(from: d, to: e); graph.addEdge(from: e, to: d)
            graph.addEdge(from: e, to: a); graph.addEdge(from: a, to: e)

            let greedy     = graph.colorGraph(using: .greedy())
            let dsatur     = graph.colorGraph(using: .dsatur())
            let welshPowell = graph.colorGraph(using: .welshPowell())

            #expect(greedy.isProper,      "[\(backend)] greedy coloring is proper on pentagon")
            #expect(dsatur.isProper,      "[\(backend)] DSatur coloring is proper on pentagon")
            #expect(welshPowell.isProper, "[\(backend)] Welsh-Powell coloring is proper on pentagon")
            #expect(greedy.chromaticNumber == 3,      "[\(backend)] greedy: pentagon needs 3 colors")
            #expect(dsatur.chromaticNumber == 3,      "[\(backend)] DSatur: pentagon needs 3 colors")
            #expect(welshPowell.chromaticNumber == 3, "[\(backend)] Welsh-Powell: pentagon needs 3 colors")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    // MARK: - Visitor Support

    /// `GreedyColoringAlgorithm` fires `examineVertex` for each vertex processed and `assignColor`
    /// when a color is assigned. Two composed visitors must each receive identical event sequences.
    @Test func greedyComposedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        // Undirected path a−b−c
        graph.addEdge(from: a, to: b); graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c); graph.addEdge(from: c, to: b)

        var examined1 = 0; var examined2 = 0
        var assigned1 = 0; var assigned2 = 0

        var v1 = GreedyColoringAlgorithm<DefaultAdjacencyList, Int>.Visitor()
        v1.examineVertex = { _ in examined1 += 1 }
        v1.assignColor   = { _, _ in assigned1 += 1 }

        var v2 = GreedyColoringAlgorithm<DefaultAdjacencyList, Int>.Visitor()
        v2.examineVertex = { _ in examined2 += 1 }
        v2.assignColor   = { _, _ in assigned2 += 1 }

        let combined = v1.combined(with: v2)
        _ = GreedyColoringAlgorithm<DefaultAdjacencyList, Int>().color(graph: graph, visitor: combined)

        // Greedy examines each vertex once and assigns a color to each

        #expect(examined1 == 3, "greedy must examine all 3 vertices")
        #expect(examined2 == 3)
        #expect(assigned1 == 3, "greedy must assign a color to each vertex")
        #expect(assigned2 == 3)
        #expect(examined1 == examined2, "both composed visitors must receive identical examineVertex events")
        #expect(assigned1 == assigned2, "both composed visitors must receive identical assignColor events")
    }

    /// Exercises all four `DSaturColoringAlgorithm.Visitor` events through a composed visitor pair.
    ///
    /// Graph: undirected triangle A−B−C (3 colors needed = 2 for triangle).
    /// - `examineVertex` fires when DSatur selects the next vertex to color.
    /// - `examineEdge` fires for each edge checked when finding available colors.
    /// - `assignColor` fires once per vertex when its color is decided.
    /// - `skipVertex` fires when a vertex is skipped (not triggered for triangle; just verify both see same count).
    /// Both composed visitors must see identical event counts.
    @Test func dsaturComposedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b); graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c); graph.addEdge(from: c, to: b)
        graph.addEdge(from: a, to: c); graph.addEdge(from: c, to: a)

        var examined1 = 0; var examined2 = 0
        var examEdge1 = 0; var examEdge2 = 0
        var assigned1 = 0; var assigned2 = 0
        var skipped1  = 0; var skipped2  = 0

        var v1 = DSaturColoringAlgorithm<DefaultAdjacencyList, Int>.Visitor()
        v1.examineVertex = { _ in examined1 += 1 }
        v1.examineEdge   = { _ in examEdge1 += 1 }
        v1.assignColor   = { _, _ in assigned1 += 1 }
        v1.skipVertex    = { _, _ in skipped1 += 1 }

        var v2 = DSaturColoringAlgorithm<DefaultAdjacencyList, Int>.Visitor()
        v2.examineVertex = { _ in examined2 += 1 }
        v2.examineEdge   = { _ in examEdge2 += 1 }
        v2.assignColor   = { _, _ in assigned2 += 1 }
        v2.skipVertex    = { _, _ in skipped2 += 1 }

        let combined = v1.combined(with: v2)
        _ = DSaturColoringAlgorithm<DefaultAdjacencyList, Int>().color(graph: graph, visitor: combined)

        // DSatur assigns a color to every vertex
        #expect(assigned1 == 3, "DSatur must assign a color to each of the 3 vertices")
        #expect(assigned2 == 3)
        // examineVertex fires at least once per vertex
        #expect(examined1 >= 3, "examineVertex fires when selecting next vertex to color")
        #expect(examined2 >= 3)
        // examineEdge fires when checking neighbors for color conflicts
        #expect(examEdge1 >= 1, "examineEdge fires for each edge checked during coloring")
        #expect(examEdge2 >= 1)
        // Both composed visitors must see identical event counts
        #expect(examined1 == examined2)
        #expect(examEdge1 == examEdge2)
        #expect(assigned1 == assigned2)
        #expect(skipped1 == skipped2)
    }

    /// Exercises all four `WelshPowellColoringAlgorithm.Visitor` events through a composed visitor pair.
    ///
    /// Graph: undirected path A−B−C (A and C can share a color; B needs its own).
    /// - `examineVertex` fires during degree sorting and during coloring passes.
    /// - `examineEdge` fires when checking neighbor colors.
    /// - `assignColor` fires once per vertex when its color is decided (3 total).
    /// - `skipVertex` fires for already-colored vertices during the pass.
    /// Both composed visitors must see identical event counts.
    @Test func welshPowellComposedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b); graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c); graph.addEdge(from: c, to: b)

        var examined1 = 0; var examined2 = 0
        var examEdge1 = 0; var examEdge2 = 0
        var assigned1 = 0; var assigned2 = 0
        var skipped1  = 0; var skipped2  = 0

        var v1 = WelshPowellColoringAlgorithm<DefaultAdjacencyList, Int>.Visitor()
        v1.examineVertex = { _ in examined1 += 1 }
        v1.examineEdge   = { _ in examEdge1 += 1 }
        v1.assignColor   = { _, _ in assigned1 += 1 }
        v1.skipVertex    = { _, _ in skipped1 += 1 }

        var v2 = WelshPowellColoringAlgorithm<DefaultAdjacencyList, Int>.Visitor()
        v2.examineVertex = { _ in examined2 += 1 }
        v2.examineEdge   = { _ in examEdge2 += 1 }
        v2.assignColor   = { _, _ in assigned2 += 1 }
        v2.skipVertex    = { _, _ in skipped2 += 1 }

        let combined = v1.combined(with: v2)
        _ = WelshPowellColoringAlgorithm<DefaultAdjacencyList, Int>().color(graph: graph, visitor: combined)

        // Welsh-Powell assigns a color to every vertex
        #expect(assigned1 == 3, "Welsh-Powell must assign a color to each of the 3 vertices")
        #expect(assigned2 == 3)
        // examineVertex fires during sorting and during coloring passes
        #expect(examined1 >= 3, "examineVertex fires for each vertex considered")
        #expect(examined2 >= 3)
        // skipVertex fires for already-colored vertices encountered in a pass
        #expect(skipped1 >= 1, "skipVertex fires for already-colored vertices")
        #expect(skipped2 >= 1)
        // Both composed visitors must see identical event counts
        #expect(examined1 == examined2)
        #expect(examEdge1 == examEdge2)
        #expect(assigned1 == assigned2)
        #expect(skipped1 == skipped2)
    }

    /// Exercises all five `SequentialVertexColoringAlgorithm.Visitor` events through a composed visitor pair.
    ///
    /// Graph: undirected path A−B−C (bidirectional edges) using SmallestLast ordering.
    /// - `useOrdering` fires once when the ordering algorithm is selected.
    /// - `examineVertex` fires for each vertex processed in the ordering.
    /// - `examineEdge` fires for each edge checked when finding available colors.
    /// - `assignColor` fires once per vertex when its color is decided.
    /// - `skipVertex` would fire for already-colored vertices (not triggered here; verify parity).
    /// Both composed visitors must see identical event counts.
    @Test func sequentialComposedVisitorsReceiveAllEvents() {
        var graph = DefaultAdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b); graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c); graph.addEdge(from: c, to: b)

        var useOrdering1 = 0; var useOrdering2 = 0
        var examined1 = 0;    var examined2 = 0
        var examEdge1 = 0;    var examEdge2 = 0
        var assigned1 = 0;    var assigned2 = 0
        var skipped1  = 0;    var skipped2  = 0

        var v1 = SequentialVertexColoringAlgorithm<DefaultAdjacencyList, Int>.Visitor()
        v1.useOrdering   = { _ in useOrdering1 += 1 }
        v1.examineVertex = { _ in examined1 += 1 }
        v1.examineEdge   = { _ in examEdge1 += 1 }
        v1.assignColor   = { _, _ in assigned1 += 1 }
        v1.skipVertex    = { _, _ in skipped1 += 1 }

        var v2 = SequentialVertexColoringAlgorithm<DefaultAdjacencyList, Int>.Visitor()
        v2.useOrdering   = { _ in useOrdering2 += 1 }
        v2.examineVertex = { _ in examined2 += 1 }
        v2.examineEdge   = { _ in examEdge2 += 1 }
        v2.assignColor   = { _, _ in assigned2 += 1 }
        v2.skipVertex    = { _, _ in skipped2 += 1 }

        let combined = v1.combined(with: v2)
        let algorithm = SequentialVertexColoringAlgorithm<DefaultAdjacencyList, Int>(
            using: SmallestLastVertexOrderingAlgorithm<DefaultAdjacencyList>()
        )
        _ = algorithm.color(graph: graph, visitor: combined)

        // useOrdering fires once when the ordering algorithm is selected
        #expect(useOrdering1 == 1, "useOrdering fires exactly once")
        #expect(useOrdering2 == 1)
        // Sequential assigns a color to every vertex
        #expect(assigned1 == 3, "assignColor fires once per vertex (3 vertices)")
        #expect(assigned2 == 3)
        // examineVertex fires for each vertex in the ordering
        #expect(examined1 >= 3, "examineVertex fires for each vertex processed")
        #expect(examined2 >= 3)
        // examineEdge fires when checking neighbor colors
        #expect(examEdge1 >= 1, "examineEdge fires for each edge checked")
        #expect(examEdge2 >= 1)
        // Both composed visitors must see identical event counts
        #expect(useOrdering1 == useOrdering2)
        #expect(examined1 == examined2)
        #expect(examEdge1 == examEdge2)
        #expect(assigned1 == assigned2)
        #expect(skipped1 == skipped2)
    }

    // MARK: - GraphColoring API and IntegerBasedColor

    /// `GraphColoring.vertices(with:)` returns all vertices assigned a given color.
    @Test func graphColoringVerticesWith() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        // Undirected path a−b−c: greedy assigns 0→a, 1→b, 0→c
        graph.addEdge(from: a, to: b); graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c); graph.addEdge(from: c, to: b)

        let coloring = graph.colorGraph(using: .greedy())

        // vertices(with:) exercises the `compactMap` over vertexColors
        let color0Vertices = coloring.vertices(with: 0)
        let color1Vertices = coloring.vertices(with: 1)
        #expect(color0Vertices.count == 2, "a and c both get color 0 (non-adjacent)")
        #expect(color1Vertices.count == 1, "b gets color 1")
        #expect(coloring.chromaticNumber == 2, "path a−b−c needs exactly 2 colors")
    }

    /// `colorGraph()` no-arg convenience uses Greedy as the default.
    /// `Int.init(integerValue:)` and `Int.integerValue` are exercised by any `Int`-colored
    /// graph since `Int: IntegerBasedColor` via those conformances.
    @Test func colorGraphNoArgConvenienceAndIntColorInit() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b); graph.addEdge(from: b, to: a)

        // no-arg colorGraph() covers the default-implementation method
        let coloring = graph.colorGraph()
        #expect(coloring.chromaticNumber >= 1)

        // Int.init(integerValue:) and Int.integerValue cover the IntegerBasedColor conformance
        let color: Int = Int(integerValue: 42)
        #expect(color.integerValue == 42, "Int.integerValue returns self")
        #expect(Int(integerValue: 0).integerValue == 0)
    }
}
#endif
