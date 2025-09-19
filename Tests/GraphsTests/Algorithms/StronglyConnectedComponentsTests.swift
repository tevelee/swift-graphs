@testable import Graphs
import Testing

struct StronglyConnectedComponentsTests {
    
    @Test func testTarjanBasic() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        // Create a cycle: A -> B -> C -> A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        let tarjan = Tarjan(on: graph)
        let components = tarjan.stronglyConnectedComponents(visitor: nil)
        
        // Should have one SCC containing all three vertices
        #expect(components.count == 1)
        #expect(components[0].count == 3)
    }
    
    @Test func testKosarajuBasic() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        // Create a cycle: A -> B -> C -> A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        let kosaraju = Kosaraju(on: graph)
        let components = kosaraju.stronglyConnectedComponents(visitor: nil)
        
        // Should have one SCC containing all three vertices
        #expect(components.count == 1)
        #expect(components[0].count == 3)
    }
    
    @Test func testTarjanDisconnected() {
        var graph = AdjacencyList()
        
        _ = graph.addVertex { $0.label = "A" }
        _ = graph.addVertex { $0.label = "B" }
        _ = graph.addVertex { $0.label = "C" }
        
        // No edges - each vertex is its own SCC
        let tarjan = Tarjan(on: graph)
        let components = tarjan.stronglyConnectedComponents(visitor: nil)
        
        // Each vertex should be its own SCC
        #expect(components.count == 3)
        
        for component in components {
            #expect(component.count == 1)
        }
    }
    
    @Test func testKosarajuDisconnected() {
        var graph = AdjacencyList()
        
        _ = graph.addVertex { $0.label = "A" }
        _ = graph.addVertex { $0.label = "B" }
        _ = graph.addVertex { $0.label = "C" }
        
        // No edges - each vertex is its own SCC
        let kosaraju = Kosaraju(on: graph)
        let components = kosaraju.stronglyConnectedComponents(visitor: nil)
        
        // Each vertex should be its own SCC
        #expect(components.count == 3)
        
        for component in components {
            #expect(component.count == 1)
        }
    }
    
    @Test func testTarjanMultipleSCCs() {
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
        let components = tarjan.stronglyConnectedComponents(visitor: nil)
        
        // Should have three SCCs
        #expect(components.count == 3)
        
        // Find components by size
        let singleVertexComponent = components.first { $0.count == 1 }!
        let twoVertexComponent = components.first { $0.count == 2 }!
        let threeVertexComponent = components.first { $0.count == 3 }!
        
        // Verify component sizes
        #expect(singleVertexComponent.count == 1)
        #expect(twoVertexComponent.count == 2)
        #expect(threeVertexComponent.count == 3)
    }
    
    @Test func testKosarajuMultipleSCCs() {
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
        let components = kosaraju.stronglyConnectedComponents(visitor: nil)
        
        // Should have three SCCs
        #expect(components.count == 3)
        
        // Find components by size
        let singleVertexComponent = components.first { $0.count == 1 }!
        let twoVertexComponent = components.first { $0.count == 2 }!
        let threeVertexComponent = components.first { $0.count == 3 }!
        
        // Verify component sizes
        #expect(singleVertexComponent.count == 1)
        #expect(twoVertexComponent.count == 2)
        #expect(threeVertexComponent.count == 3)
    }
}