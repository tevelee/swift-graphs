#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
@testable import Graphs
import Testing

struct StronglyConnectedComponentsTests {

    // MARK: - Core Behavior

    @Test func tarjanFindsStronglyConnectedVertices() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        // Create a cycle: A -> B -> C -> A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        let tarjan = Tarjan(on: graph)
        let result = tarjan.stronglyConnectedComponents(visitor: nil)
        
        // Should have one SCC containing all three vertices
        #expect(result.componentCount == 1)
        #expect(result.components[0].count == 3)
    }
    
    @Test func kosarajuFindsStronglyConnectedVertices() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        // Create a cycle: A -> B -> C -> A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        let kosaraju = Kosaraju(on: graph)
        let result = kosaraju.stronglyConnectedComponents(visitor: nil)
        
        // Should have one SCC containing all three vertices
        #expect(result.componentCount == 1)
        #expect(result.components[0].count == 3)
    }
    
    @Test func tarjanHandlesDisconnectedGraph() {
        var graph = AdjacencyList()
        
        graph.addVertex { $0.label = "A" }
        graph.addVertex { $0.label = "B" }
        graph.addVertex { $0.label = "C" }
        
        // No edges - each vertex is its own SCC
        let tarjan = Tarjan(on: graph)
        let result = tarjan.stronglyConnectedComponents(visitor: nil)
        
        // Each vertex should be its own SCC
        #expect(result.componentCount == 3)
        
        for component in result.components {
            #expect(component.count == 1)
        }
    }
    
    @Test func kosarajuHandlesDisconnectedGraph() {
        var graph = AdjacencyList()
        
        graph.addVertex { $0.label = "A" }
        graph.addVertex { $0.label = "B" }
        graph.addVertex { $0.label = "C" }
        
        // No edges - each vertex is its own SCC
        let kosaraju = Kosaraju(on: graph)
        let result = kosaraju.stronglyConnectedComponents(visitor: nil)
        
        // Each vertex should be its own SCC
        #expect(result.componentCount == 3)
        
        for component in result.components {
            #expect(component.count == 1)
        }
    }
    
    @Test func tarjanFindsMultipleSCCs() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        let f = graph.addVertex { $0.label = "F" }
        
        // First SCC: A -> B -> A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        // Second SCC: C -> D -> E -> C
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: c)
        
        // Third SCC: F (single vertex)
        // No edges for F
        
        // Connect SCCs
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: c, to: f)
        
        let tarjan = Tarjan(on: graph)
        let result = tarjan.stronglyConnectedComponents(visitor: nil)
        
        // Should have three SCCs
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
    
    @Test func kosarajuFindsMultipleSCCs() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        let f = graph.addVertex { $0.label = "F" }
        
        // First SCC: A -> B -> A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        // Second SCC: C -> D -> E -> C
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: c)
        
        // Third SCC: F (single vertex)
        // No edges for F
        
        // Connect SCCs
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: c, to: f)
        
        let kosaraju = Kosaraju(on: graph)
        let result = kosaraju.stronglyConnectedComponents(visitor: nil)
        
        // Should have three SCCs
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

    // MARK: - Algorithm Comparison

    @Test func tarjanAndKosarajuAgreeOnComponentCount_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            // Two SCCs: {A,B,C} cycle and {D} isolated
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            _ = graph.addVertex { $0.label = "D" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: a)

            let tarjanResult   = graph.stronglyConnectedComponents(using: .tarjan())
            let kosarajuResult = graph.stronglyConnectedComponents(using: .kosaraju())

            #expect(tarjanResult.componentCount == 2,   "[\(backend)] Tarjan: 2 SCCs")
            #expect(kosarajuResult.componentCount == 2, "[\(backend)] Kosaraju: 2 SCCs")
            #expect(tarjanResult.componentCount == kosarajuResult.componentCount, "[\(backend)] both must agree")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }
}
#endif
