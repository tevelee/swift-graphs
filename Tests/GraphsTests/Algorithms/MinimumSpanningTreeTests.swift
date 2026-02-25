#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
@testable import Graphs
import Testing

struct MinimumSpanningTreeTests {
    
    // MARK: - Test Data
    
    func createTestGraph() -> some AdjacencyListProtocol {
        var graph = AdjacencyList()
        
        // Create a simple graph: A-B-C with weights 1, 2, 3
        // A --1-- B --2-- C
        // |              |
        // 3              4
        // |              |
        // D --5-- E --6-- F
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        let f = graph.addVertex { $0.label = "F" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
        graph.addEdge(from: c, to: b) { $0.weight = 2.0 }
        graph.addEdge(from: a, to: d) { $0.weight = 3.0 }
        graph.addEdge(from: d, to: a) { $0.weight = 3.0 }
        graph.addEdge(from: c, to: f) { $0.weight = 4.0 }
        graph.addEdge(from: f, to: c) { $0.weight = 4.0 }
        graph.addEdge(from: d, to: e) { $0.weight = 5.0 }
        graph.addEdge(from: e, to: d) { $0.weight = 5.0 }
        graph.addEdge(from: e, to: f) { $0.weight = 6.0 }
        graph.addEdge(from: f, to: e) { $0.weight = 6.0 }
        
        return graph
    }
    
    // MARK: - Kruskal Algorithm Tests
    
    @Test func testKruskalAlgorithm() {
        let graph = createTestGraph()
        
        let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
        
        // The MST should have 5 edges (6 vertices - 1)
        #expect(mst.edgeCount == 5)
        
        // The MST should include all 6 vertices
        #expect(mst.vertexCount == 6)
        
        // The total weight should be 1 + 2 + 3 + 4 + 5 = 15
        #expect(mst.totalWeight == 15.0)
    }
    
    @Test func testKruskalAlgorithmWithDisconnectedGraph() {
        var graph = AdjacencyList()
        
        // Create two disconnected components
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
        graph.addEdge(from: c, to: d) { $0.weight = 2.0 }
        graph.addEdge(from: d, to: c) { $0.weight = 2.0 }
        
        let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
        
        // The MST should have 2 edges (4 vertices - 2 components)
        #expect(mst.edgeCount == 2)
        
        // The MST should include all 4 vertices
        #expect(mst.vertexCount == 4)
        
        // The total weight should be 1 + 2 = 3
        #expect(mst.totalWeight == 3.0)
    }
    
    // MARK: - Prim Algorithm Tests
    
    @Test func testPrimAlgorithm() {
        let graph = createTestGraph()
        
        let mst = graph.minimumSpanningTree(using: .prim(weight: .property(\.weight)))
        
        // The MST should have 5 edges (6 vertices - 1)
        #expect(mst.edgeCount == 5)
        
        // The MST should include all 6 vertices
        #expect(mst.vertexCount == 6)
        
        // The total weight should be 1 + 2 + 3 + 4 + 5 = 15
        #expect(mst.totalWeight == 15.0)
    }
    
    @Test func testPrimAlgorithmWithDifferentStartVertex() {
        let graph = createTestGraph()
        
        // Get the first vertex to use as start
        let firstVertex = Array(graph.vertices()).first!
        
        let mst = graph.minimumSpanningTree(using: .prim(weight: .property(\.weight), startVertex: firstVertex))
        
        // The MST should have 5 edges (6 vertices - 1)
        #expect(mst.edgeCount == 5)
        
        // The MST should include all 6 vertices
        #expect(mst.vertexCount == 6)
        
        // The total weight should be 1 + 2 + 3 + 4 + 5 = 15
        #expect(mst.totalWeight == 15.0)
    }
    
    // MARK: - Boruvka Algorithm Tests
    
    @Test func testBoruvkaAlgorithm() {
        let graph = createTestGraph()
        
        let mst = graph.minimumSpanningTree(using: .boruvka(weight: .property(\.weight)))
        
        // The MST should have 5 edges (6 vertices - 1)
        #expect(mst.edgeCount == 5)
        
        // The MST should include all 6 vertices
        #expect(mst.vertexCount == 6)
        
        // The total weight should be 1 + 2 + 3 + 4 + 5 = 15
        #expect(mst.totalWeight == 15.0)
    }
    
    // MARK: - Algorithm Comparison Tests
    
    @Test func testAllAlgorithmsProduceSameResult() {
        let graph = createTestGraph()
        
        let kruskalMST = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
        let primMST = graph.minimumSpanningTree(using: .prim(weight: .property(\.weight)))
        let boruvkaMST = graph.minimumSpanningTree(using: .boruvka(weight: .property(\.weight)))
        
        // All algorithms should produce the same total weight
        #expect(kruskalMST.totalWeight == primMST.totalWeight)
        #expect(primMST.totalWeight == boruvkaMST.totalWeight)
        
        // All algorithms should produce the same number of edges
        #expect(kruskalMST.edgeCount == primMST.edgeCount)
        #expect(primMST.edgeCount == boruvkaMST.edgeCount)
        
        // All algorithms should include the same vertices
        #expect(kruskalMST.vertexCount == primMST.vertexCount)
        #expect(primMST.vertexCount == boruvkaMST.vertexCount)
    }
    
    // MARK: - Edge Cases
    
    @Test func testSingleVertexGraph() {
        var graph = AdjacencyList()
        
        // Single vertex with no edges
        graph.addVertex { $0.label = "A" }
        
        let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
        
        // MST should have 0 edges and 1 vertex
        #expect(mst.edgeCount == 0)
        #expect(mst.vertexCount == 1)
        #expect(mst.totalWeight == 0.0)
    }
    
    @Test func testTwoVertexGraph() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 5.0 }
        graph.addEdge(from: b, to: a) { $0.weight = 5.0 }
        
        let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
        
        // MST should have 1 edge and 2 vertices
        #expect(mst.edgeCount == 1)
        #expect(mst.vertexCount == 2)
        #expect(mst.totalWeight == 5.0)
    }
    
    @Test func testEmptyGraph() {
        let graph = AdjacencyList()
        
        let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
        
        // MST should be empty
        #expect(mst.edgeCount == 0)
        #expect(mst.vertexCount == 0)
        #expect(mst.totalWeight == 0.0)
    }
}
#endif
