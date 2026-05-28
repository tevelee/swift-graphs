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
    
    // MARK: - Core Behavior (Kruskal)
    
    @Test func kruskalBuildsMinimumTree() {
        let graph = createTestGraph()
        
        let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
        
        // The MST should have 5 edges (6 vertices - 1)
        #expect(mst.edgeCount == 5)
        
        // The MST should include all 6 vertices
        #expect(mst.vertexCount == 6)
        
        // The total weight should be 1 + 2 + 3 + 4 + 5 = 15
        #expect(mst.totalWeight == 15.0)
    }
    
    @Test func kruskalHandlesDisconnectedGraph() {
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
    
    // MARK: - Core Behavior (Prim)
    
    @Test func primBuildsMinimumTree() {
        let graph = createTestGraph()
        
        let mst = graph.minimumSpanningTree(using: .prim(weight: .property(\.weight)))
        
        // The MST should have 5 edges (6 vertices - 1)
        #expect(mst.edgeCount == 5)
        
        // The MST should include all 6 vertices
        #expect(mst.vertexCount == 6)
        
        // The total weight should be 1 + 2 + 3 + 4 + 5 = 15
        #expect(mst.totalWeight == 15.0)
    }
    
    @Test func primStartsFromAnyVertex() {
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
    
    // MARK: - Core Behavior (Borůvka)
    
    @Test func boruvkaBuildsMinimumTree() {
        let graph = createTestGraph()
        
        let mst = graph.minimumSpanningTree(using: .boruvka(weight: .property(\.weight)))
        
        // The MST should have 5 edges (6 vertices - 1)
        #expect(mst.edgeCount == 5)
        
        // The MST should include all 6 vertices
        #expect(mst.vertexCount == 6)
        
        // The total weight should be 1 + 2 + 3 + 4 + 5 = 15
        #expect(mst.totalWeight == 15.0)
    }
    
    // MARK: - Algorithm Comparison
    
    @Test func allAlgorithmsAgreeTotalWeight() {
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
    
    // MARK: - Multi-Backend Coverage

    @Test func kruskalAndPrimAgreeTotalWeight_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            // Connected undirected graph (both directions per edge)
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }; graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 2.0 }; graph.addEdge(from: c, to: b) { $0.weight = 2.0 }
            graph.addEdge(from: c, to: d) { $0.weight = 3.0 }; graph.addEdge(from: d, to: c) { $0.weight = 3.0 }
            graph.addEdge(from: a, to: d) { $0.weight = 9.0 }; graph.addEdge(from: d, to: a) { $0.weight = 9.0 }

            let kruskal = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
            let prim    = graph.minimumSpanningTree(using: .prim(weight: .property(\.weight)))

            #expect(kruskal.edgeCount == 3, "[\(backend)] Kruskal MST has V-1 edges")
            #expect(prim.edgeCount == 3,    "[\(backend)] Prim MST has V-1 edges")
            #expect(kruskal.totalWeight == prim.totalWeight, "[\(backend)] Kruskal and Prim must agree on total weight")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func mstSpansAllVertices_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex(); let b = graph.addVertex()
            let c = graph.addVertex(); let d = graph.addVertex()
            graph.addEdge(from: a, to: b) { $0.weight = 1.0 }; graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
            graph.addEdge(from: b, to: c) { $0.weight = 2.0 }; graph.addEdge(from: c, to: b) { $0.weight = 2.0 }
            graph.addEdge(from: c, to: d) { $0.weight = 1.0 }; graph.addEdge(from: d, to: c) { $0.weight = 1.0 }
            let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
            #expect(mst.vertexCount == 4, "[\(backend)] MST spans all 4 vertices")
            #expect(mst.edgeCount == 3,   "[\(backend)] MST has V-1 = 3 edges")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    // MARK: - Edge Cases

    @Test func singleVertexGraphHasNoEdges() {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "A" }
        let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
        #expect(mst.edgeCount == 0)
        #expect(mst.vertexCount == 1)
        #expect(mst.totalWeight == 0.0)
    }

    @Test func twoVertexGraphHasSingleEdge() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b) { $0.weight = 5.0 }
        graph.addEdge(from: b, to: a) { $0.weight = 5.0 }
        let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
        #expect(mst.edgeCount == 1)
        #expect(mst.vertexCount == 2)
        #expect(mst.totalWeight == 5.0)
    }

    @Test func emptyGraphHasNoMST() {
        let graph = AdjacencyList()
        let mst = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))
        #expect(mst.edgeCount == 0)
        #expect(mst.vertexCount == 0)
        #expect(mst.totalWeight == 0.0)
    }

    /// When two parallel edges connect the same pair of vertices, the MST must use
    /// only the cheaper one.
    ///
    /// Kruskal and Prim both select minimum-weight edges, so parallel edges with different
    /// weights must not both appear in the MST — only the cheaper survives.
    @Test func parallelEdgesSelectsCheaperInMST() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b) { $0.weight = 5.0 }; graph.addEdge(from: b, to: a) { $0.weight = 5.0 }
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }; graph.addEdge(from: b, to: a) { $0.weight = 1.0 }  // cheaper parallel
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }; graph.addEdge(from: c, to: b) { $0.weight = 2.0 }

        let kruskal = graph.minimumSpanningTree(using: .kruskal(weight: .property(\.weight)))

        // MST should use weight-1 edge a−b and weight-2 edge b−c, total = 3
        #expect(kruskal.edgeCount == 2, "MST of a 3-vertex graph has exactly 2 edges")
        #expect(kruskal.totalWeight == 3.0, "MST must select cheaper a−b (w=1) and b−c (w=2)")
    }
}
#endif
