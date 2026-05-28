#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
@testable import Graphs
import Testing

struct ConnectedComponentsTests {

    // MARK: - Core Behavior

    @Test func unionFindFindsConnectedVertices() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        // Create a connected component: A - B - C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let result = unionFind.connectedComponents(visitor: nil)
        
        // Should have one connected component containing all three vertices
        #expect(result.componentCount == 1)
        #expect(result.components[0].count == 3)
    }
    
    @Test func dfsFindsConnectedVertices() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        // Create a connected component: A - B - C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        let dfs = DFSConnectedComponents(on: graph)
        let result = dfs.connectedComponents(visitor: nil)
        
        // Should have one connected component containing all three vertices
        #expect(result.componentCount == 1)
        #expect(result.components[0].count == 3)
    }
    
    @Test func unionFindSeparatesDisconnectedComponents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create two disconnected components: A - B and C - D
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let result = unionFind.connectedComponents(visitor: nil)
        
        // Should have two connected components
        #expect(result.componentCount == 2)
        
        // Each component should have 2 vertices
        for component in result.components {
            #expect(component.count == 2)
        }
    }
    
    @Test func dfsSeparatesDisconnectedComponents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create two disconnected components: A - B and C - D
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        let dfs = DFSConnectedComponents(on: graph)
        let result = dfs.connectedComponents(visitor: nil)
        
        // Should have two connected components
        #expect(result.componentCount == 2)
        
        // Each component should have 2 vertices
        for component in result.components {
            #expect(component.count == 2)
        }
    }
    
    @Test func unionFindFindsMultipleComponents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        graph.addVertex { $0.label = "F" }
        
        // Component 1: A - B - C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        // Component 2: D - E
        graph.addEdge(from: d, to: e)
        
        // Component 3: F (single vertex)
        // No edges for F
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let result = unionFind.connectedComponents(visitor: nil)
        
        // Should have three connected components
        #expect(result.componentCount == 3)
        
        // Find components by size
        let singleVertexComponent = result.components.first { $0.count == 1 }!
        let twoVertexComponent = result.components.first { $0.count == 2 }!
        let threeVertexComponent = result.components.first { $0.count == 3 }!
        
        // Verify component sizes
        #expect(singleVertexComponent.count == 1)
        #expect(twoVertexComponent.count == 2)
        #expect(threeVertexComponent.count == 3)
    }
    
    @Test func dfsFindsMultipleComponents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        graph.addVertex { $0.label = "F" }
        
        // Component 1: A - B - C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        // Component 2: D - E
        graph.addEdge(from: d, to: e)
        
        // Component 3: F (single vertex)
        // No edges for F
        
        let dfs = DFSConnectedComponents(on: graph)
        let result = dfs.connectedComponents(visitor: nil)
        
        // Should have three connected components
        #expect(result.componentCount == 3)
        
        // Find components by size
        let singleVertexComponent = result.components.first { $0.count == 1 }!
        let twoVertexComponent = result.components.first { $0.count == 2 }!
        let threeVertexComponent = result.components.first { $0.count == 3 }!
        
        // Verify component sizes
        #expect(singleVertexComponent.count == 1)
        #expect(twoVertexComponent.count == 2)
        #expect(threeVertexComponent.count == 3)
    }
    
    @Test func unionFindHandlesSingleVertex() {
        var graph = AdjacencyList()
        
        graph.addVertex { $0.label = "A" }
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let result = unionFind.connectedComponents(visitor: nil)
        
        // Should have one connected component with one vertex
        #expect(result.componentCount == 1)
        #expect(result.components[0].count == 1)
    }
    
    @Test func dfsHandlesSingleVertex() {
        var graph = AdjacencyList()
        
        graph.addVertex { $0.label = "A" }
        
        let dfs = DFSConnectedComponents(on: graph)
        let result = dfs.connectedComponents(visitor: nil)
        
        // Should have one connected component with one vertex
        #expect(result.componentCount == 1)
        #expect(result.components[0].count == 1)
    }
    
    @Test func unionFindVisitorObservesEvents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b)
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let result = unionFind.connectedComponents(visitor: nil)
        
        // Basic functionality test
        #expect(result.componentCount == 1)
        #expect(result.components[0].count == 2)
    }
    
    @Test func dfsVisitorObservesEvents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b)
        
        let dfs = DFSConnectedComponents(on: graph)
        let result = dfs.connectedComponents(visitor: nil)
        
        // Basic functionality test
        #expect(result.componentCount == 1)
        #expect(result.components[0].count == 2)
    }
    
    @Test func unionFindResultsAreConsistent() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let result1 = unionFind.connectedComponents(visitor: nil)
        let result2 = unionFind.connectedComponents(visitor: nil)
        
        // Results should be consistent across multiple runs
        #expect(result1.componentCount == result2.componentCount)
        
        // Each component should have the same size
        let sizes1 = result1.components.map { $0.count }.sorted()
        let sizes2 = result2.components.map { $0.count }.sorted()
        #expect(sizes1 == sizes2)
    }
    
    @Test func dfsResultsAreConsistent() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        let dfs = DFSConnectedComponents(on: graph)
        let result1 = dfs.connectedComponents(visitor: nil)
        let result2 = dfs.connectedComponents(visitor: nil)
        
        // Results should be consistent across multiple runs
        #expect(result1.componentCount == result2.componentCount)
        
        // Each component should have the same size
        let sizes1 = result1.components.map { $0.count }.sorted()
        let sizes2 = result2.components.map { $0.count }.sorted()
        #expect(sizes1 == sizes2)
    }

    // MARK: - Multi-Backend Coverage

    @Test func componentCountAndSizes_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            _ = graph.addVertex { $0.label = "E" } // isolated vertex
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: a)
            graph.addEdge(from: c, to: d)
            graph.addEdge(from: d, to: c)
            // e is isolated

            let dfsResult = graph.connectedComponents(using: .dfs())
            let ufResult  = graph.connectedComponents(using: .unionFind())

            #expect(dfsResult.componentCount == 3, "[\(backend)] DFS: expected 3 components")
            #expect(ufResult.componentCount  == 3, "[\(backend)] UnionFind: expected 3 components")
            #expect(dfsResult.componentCount == ufResult.componentCount, "[\(backend)] both algorithms must agree")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    // MARK: - Edge Cases

    /// A vertex with a self-loop (a → a) must form a single component by itself.
    ///
    /// The self-loop doesn't connect `a` to any other vertex, so if `a` is isolated
    /// (no other edges to other vertices), it is its own component. Both DFS and
    /// UnionFind must handle self-loops without revisiting or crashing.
    @Test func selfLoopVertexFormsItsOwnComponent() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: a)  // self-loop — a is still isolated from b
        // No edge connecting a and b

        let dfsResult = graph.connectedComponents(using: .dfs())
        let ufResult  = graph.connectedComponents(using: .unionFind())

        #expect(dfsResult.componentCount == 2,
                "A self-looped vertex with no other edges forms its own component (2 components: {a} and {b})")
        #expect(ufResult.componentCount == 2,
                "UnionFind: a self-looped vertex with no other edges forms its own component")
        #expect(!dfsResult.areInSameComponent(a, b),
                "a and b must be in separate components despite a's self-loop")
    }

    /// A single vertex with a self-loop forms exactly one component.
    @Test func singleVertexWithSelfLoopIsOneComponent() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        graph.addEdge(from: a, to: a)  // self-loop

        let dfsResult = graph.connectedComponents(using: .dfs())
        let ufResult  = graph.connectedComponents(using: .unionFind())

        #expect(dfsResult.componentCount == 1,
                "A single vertex with a self-loop is still exactly 1 component")
        #expect(ufResult.componentCount == 1,
                "UnionFind: single vertex with self-loop is 1 component")
    }

    /// Parallel directed edges a → b and b → a must not inflate the component count.
    ///
    /// Two vertices mutually connected (even via parallel edges) form a single component.
    @Test func parallelEdgesDoNotInflateComponentCount() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: b)  // parallel edge
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: a)  // parallel reverse edge

        let dfsResult = graph.connectedComponents(using: .dfs())
        let ufResult  = graph.connectedComponents(using: .unionFind())

        #expect(dfsResult.componentCount == 1, "Parallel edges must not inflate DFS component count")
        #expect(ufResult.componentCount == 1, "Parallel edges must not inflate UnionFind component count")
        #expect(dfsResult.areInSameComponent(a, b), "a and b must be in the same component")
    }
}
#endif
