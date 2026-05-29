#if !GRAPHS_USES_TRAITS || GRAPHS_BIPARTITE_GRAPH
import Testing
@testable import Graphs

struct BipartiteGraphTests {
    
    @Test
    func bipartiteGraphCreation() {
        var graph = BipartiteAdjacencyList()
        
        // Add vertices to different partitions
        let left1 = graph.addVertex(to: .left)
        let left2 = graph.addVertex(to: .left)
        let right1 = graph.addVertex(to: .right)
        let right2 = graph.addVertex(to: .right)
        
        // Verify partitions
        #expect(graph.leftPartition().count == 2)
        #expect(graph.rightPartition().count == 2)
        #expect(graph.leftPartition().contains(left1))
        #expect(graph.leftPartition().contains(left2))
        #expect(graph.rightPartition().contains(right1))
        #expect(graph.rightPartition().contains(right2))
        
        // Verify partition queries
        #expect(graph.partition(of: left1) == .left)
        #expect(graph.partition(of: right1) == .right)
        // Create a non-existent vertex for testing
        let nonExistentVertex = OrderedVertexStorage.Vertex(_id: 999)
        #expect(graph.partition(of: nonExistentVertex) == nil) // Non-existent vertex
    }
    
    @Test
    func bipartiteGraphEdgeAddition() {
        var graph = BipartiteAdjacencyList()
        
        let left1 = graph.addVertex(to: .left)
        let left2 = graph.addVertex(to: .left)
        let right1 = graph.addVertex(to: .right)
        let right2 = graph.addVertex(to: .right)
        
        // Add valid edges (between different partitions)
        let edge1 = graph.addEdge(from: left1, to: right1)
        let edge2 = graph.addEdge(from: left2, to: right2)
        
        #expect(edge1 != nil)
        #expect(edge2 != nil)
        #expect(graph.edgeCount == 2)
        
        // Try to add invalid edge (same partition)
        let invalidEdge = graph.addEdge(from: left1, to: left2)
        #expect(invalidEdge == nil)
        #expect(graph.edgeCount == 2) // Should not increase
    }
    
    @Test
    func bipartiteGraphPartitionQueries() {
        var graph = BipartiteAdjacencyList()
        
        let left1 = graph.addVertex(to: .left)
        let left2 = graph.addVertex(to: .left)
        let right1 = graph.addVertex(to: .right)
        let right2 = graph.addVertex(to: .right)
        
        // Test partition queries directly
        #expect(graph.partition(of: left1) == .left)
        #expect(graph.partition(of: left2) == .left)
        #expect(graph.partition(of: right1) == .right)
        #expect(graph.partition(of: right2) == .right)
    }
    
    @Test
    func bipartiteGraphVertexMovement() {
        var graph = BipartiteAdjacencyList()
        
        let left1 = graph.addVertex(to: .left)
        let right1 = graph.addVertex(to: .right)
        
        // Move vertex from left to right
        graph.move(vertex: left1, to: .right)
        #expect(graph.partition(of: left1) == .right)
        #expect(graph.leftPartition().count == 0)
        #expect(graph.rightPartition().count == 2)
        
        // Move vertex from right to left
        graph.move(vertex: right1, to: .left)
        #expect(graph.partition(of: right1) == .left)
        #expect(graph.leftPartition().count == 1)
        #expect(graph.rightPartition().count == 1)
    }
    
    @Test
    func bipartiteGraphAllVertices() {
        var graph = BipartiteAdjacencyList()
        
        let left1 = graph.addVertex(to: .left)
        let left2 = graph.addVertex(to: .left)
        let right1 = graph.addVertex(to: .right)
        let right2 = graph.addVertex(to: .right)
        
        let allVertices = Set(graph.allVertices())
        let expectedVertices: Set<OrderedVertexStorage.Vertex> = [left1, left2, right1, right2]
        
        #expect(allVertices == expectedVertices)
    }
}

struct BipartiteCheckableTests {
    
    @Test
    func simpleBipartiteGraphIsDetected() {
        // Create a simple bipartite graph using adjacency list
        var graph = AdjacencyList()
        
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        let v3 = graph.addVertex()
        let v4 = graph.addVertex()
        
        // Add edges to create a bipartite graph
        // Partition 1: v1, v3
        // Partition 2: v2, v4
        _ = graph.addEdge(from: v1, to: v2)
        _ = graph.addEdge(from: v1, to: v4)
        _ = graph.addEdge(from: v3, to: v2)
        _ = graph.addEdge(from: v3, to: v4)
        
        // The graph should be bipartite
        #expect(graph.isBipartiteSimple())
        
        if let bipartition = graph.bipartition() {
            #expect(bipartition.left.count + bipartition.right.count == 4)
            #expect(bipartition.left.count == 2)
            #expect(bipartition.right.count == 2)
        } else {
            Issue.record("Graph should be bipartite")
        }
    }
    
    @Test
    func nonBipartiteGraphIsRejected() {
        // Create a non-bipartite graph (triangle)
        var graph = AdjacencyList()
        
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        let v3 = graph.addVertex()
        
        // Create a triangle (odd cycle)
        _ = graph.addEdge(from: v1, to: v2)
        _ = graph.addEdge(from: v2, to: v3)
        _ = graph.addEdge(from: v3, to: v1)
        
        // The graph should not be bipartite
        #expect(!graph.isBipartiteSimple())
        #expect(graph.bipartition() == nil)
    }
    
    @Test
    func disconnectedComponentsWithNonBipartitePartIsRejected() {
        // Create a graph with multiple components, some bipartite, some not
        var graph = AdjacencyList()

        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        let v3 = graph.addVertex()
        let v4 = graph.addVertex()
        let v5 = graph.addVertex()
        let v6 = graph.addVertex()

        // Bipartite component: v1-v2-v3-v4 (path of length 3)
        _ = graph.addEdge(from: v1, to: v2)
        _ = graph.addEdge(from: v2, to: v3)
        _ = graph.addEdge(from: v3, to: v4)

        // Non-bipartite component: v5-v6-v7-v5 (odd cycle)
        let v7 = graph.addVertex()
        _ = graph.addEdge(from: v5, to: v6)
        _ = graph.addEdge(from: v6, to: v7)
        _ = graph.addEdge(from: v7, to: v5)

        // The graph should not be bipartite due to the non-bipartite component
        #expect(!graph.isBipartiteSimple())
        #expect(graph.bipartition() == nil)
    }

    // MARK: - Multi-Backend Coverage

    @Test func bipartitePathDetected_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            // Even-length path a→b→c→d is bipartite (alternating partitions)
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            let d = graph.addVertex { $0.label = "d" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: d)

            #expect(graph.isBipartiteSimple(), "[\(backend)] path a→b→c→d is bipartite")
            let bp = graph.bipartition()
            #expect(bp != nil, "[\(backend)] bipartition should be found")
            if let bp {
                #expect(bp.left.count + bp.right.count == 4, "[\(backend)] all 4 vertices partitioned")
            }
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func nonBipartiteOddCycleRejected_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            // Triangle (odd cycle): not bipartite
            let a = graph.addVertex { $0.label = "a" }
            let b = graph.addVertex { $0.label = "b" }
            let c = graph.addVertex { $0.label = "c" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: a)

            #expect(!graph.isBipartiteSimple(), "[\(backend)] triangle is not bipartite")
            #expect(graph.bipartition() == nil, "[\(backend)] no bipartition for odd cycle")
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
