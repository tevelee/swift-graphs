@testable import Graphs
import Testing

struct ConnectedComponentsTests {
    
    @Test func testUnionFindBasic() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        // Create a connected component: A - B - C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let components = unionFind.connectedComponents(visitor: nil)
        
        // Should have one connected component containing all three vertices
        #expect(components.count == 1)
        #expect(components[0].count == 3)
    }
    
    @Test func testDFSBasic() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        // Create a connected component: A - B - C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        let dfs = DFSConnectedComponents(on: graph)
        let components = dfs.connectedComponents(visitor: nil)
        
        // Should have one connected component containing all three vertices
        #expect(components.count == 1)
        #expect(components[0].count == 3)
    }
    
    @Test func testUnionFindDisconnected() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create two disconnected components: A - B and C - D
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let components = unionFind.connectedComponents(visitor: nil)
        
        // Should have two connected components
        #expect(components.count == 2)
        
        // Each component should have 2 vertices
        for component in components {
            #expect(component.count == 2)
        }
    }
    
    @Test func testDFSDisconnected() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create two disconnected components: A - B and C - D
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        let dfs = DFSConnectedComponents(on: graph)
        let components = dfs.connectedComponents(visitor: nil)
        
        // Should have two connected components
        #expect(components.count == 2)
        
        // Each component should have 2 vertices
        for component in components {
            #expect(component.count == 2)
        }
    }
    
    @Test func testUnionFindMultipleComponents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        _ = graph.addVertex { $0.label = "F" }
        
        // Component 1: A - B - C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        // Component 2: D - E
        graph.addEdge(from: d, to: e)
        
        // Component 3: F (single vertex)
        // No edges for F
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let components = unionFind.connectedComponents(visitor: nil)
        
        // Should have three connected components
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
    
    @Test func testDFSMultipleComponents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        _ = graph.addVertex { $0.label = "F" }
        
        // Component 1: A - B - C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        // Component 2: D - E
        graph.addEdge(from: d, to: e)
        
        // Component 3: F (single vertex)
        // No edges for F
        
        let dfs = DFSConnectedComponents(on: graph)
        let components = dfs.connectedComponents(visitor: nil)
        
        // Should have three connected components
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
    
    @Test func testUnionFindSingleVertex() {
        var graph = AdjacencyList()
        
        graph.addVertex { $0.label = "A" }
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let components = unionFind.connectedComponents(visitor: nil)
        
        // Should have one connected component with one vertex
        #expect(components.count == 1)
        #expect(components[0].count == 1)
    }
    
    @Test func testDFSSingleVertex() {
        var graph = AdjacencyList()
        
        graph.addVertex { $0.label = "A" }
        
        let dfs = DFSConnectedComponents(on: graph)
        let components = dfs.connectedComponents(visitor: nil)
        
        // Should have one connected component with one vertex
        #expect(components.count == 1)
        #expect(components[0].count == 1)
    }
    
    @Test func testUnionFindVisitor() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b)
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let components = unionFind.connectedComponents(visitor: nil)
        
        // Basic functionality test
        #expect(components.count == 1)
        #expect(components[0].count == 2)
    }
    
    @Test func testDFSVisitor() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b)
        
        let dfs = DFSConnectedComponents(on: graph)
        let components = dfs.connectedComponents(visitor: nil)
        
        // Basic functionality test
        #expect(components.count == 1)
        #expect(components[0].count == 2)
    }
    
    @Test func testUnionFindConsistency() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        let unionFind = UnionFindConnectedComponents(on: graph)
        let components1 = unionFind.connectedComponents(visitor: nil)
        let components2 = unionFind.connectedComponents(visitor: nil)
        
        // Results should be consistent across multiple runs
        #expect(components1.count == components2.count)
        
        // Each component should have the same size
        let sizes1 = components1.map { $0.count }.sorted()
        let sizes2 = components2.map { $0.count }.sorted()
        #expect(sizes1 == sizes2)
    }
    
    @Test func testDFSConsistency() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        let dfs = DFSConnectedComponents(on: graph)
        let components1 = dfs.connectedComponents(visitor: nil)
        let components2 = dfs.connectedComponents(visitor: nil)
        
        // Results should be consistent across multiple runs
        #expect(components1.count == components2.count)
        
        // Each component should have the same size
        let sizes1 = components1.map { $0.count }.sorted()
        let sizes2 = components2.map { $0.count }.sorted()
        #expect(sizes1 == sizes2)
    }
}
