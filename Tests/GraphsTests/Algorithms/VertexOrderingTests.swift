@testable import Graphs
import Testing

struct VertexOrderingTests {
    
    // MARK: - Smallest Last Vertex Ordering Tests
    
    @Test func testSmallestLastVertexOrderingSimpleGraph() {
        // Create a simple graph: A-B-C with A-D
        // A -- B -- C
        // |
        // D
        var graph = AdjacencyList()
        
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
        
        let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        
        // Verify all vertices are included
        #expect(ordering.orderedVertices.count == 4)
        #expect(ordering.orderedVertices == [b, a, d, c])
        
        // Verify deterministic ordering: vertices with degree 1 should come first
        // A has degree 2, B has degree 2, C has degree 1, D has degree 1
        // So C and D should be first (in some order), then A and B
        let cPosition = ordering.position(of: c)!
        let dPosition = ordering.position(of: d)!
        let aPosition = ordering.position(of: a)!
        let bPosition = ordering.position(of: b)!
        
        // The algorithm removes vertices with smallest degree first, so they appear last in the final ordering
        // This means degree-1 vertices should appear later in the ordering
        #expect(cPosition > aPosition || cPosition > bPosition)
        #expect(dPosition > aPosition || dPosition > bPosition)
    }
    
    @Test func testSmallestLastVertexOrderingCompleteGraph() {
        // Create a complete graph K4
        var graph = AdjacencyList()
        
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
        
        let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        
        // Verify all vertices are included
        #expect(ordering.orderedVertices.count == 4)
        #expect(ordering.orderedVertices == [d, c, b, a])
    }
    
    @Test func testSmallestLastVertexOrderingPathGraph() {
        // Create a path graph: A-B-C-D
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        
        // Verify all vertices are included
        #expect(ordering.orderedVertices.count == 4)
        #expect(ordering.orderedVertices == [c, b, d, a])
    }
    
    @Test func testSmallestLastVertexOrderingStarGraph() {
        // Create a star graph: center connected to all others
        //   B
        //   |
        // A-C-D
        //   |
        //   E
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        graph.addEdge(from: c, to: e)
        graph.addEdge(from: e, to: c)
        
        let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        
        // Verify all vertices are included
        #expect(ordering.orderedVertices.count == 5)
        #expect(ordering.orderedVertices == [c, e, d, b, a])
    }
    
    // MARK: - Reverse Cuthill-McKee Ordering Tests
    
    @Test func testReverseCuthillMcKeeOrderingSimpleGraph() {
        // Create a simple graph: A-B-C with A-D
        // A -- B -- C
        // |
        // D
        var graph = AdjacencyList()
        
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
        
        let ordering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        
        // Verify all vertices are included
        #expect(ordering.orderedVertices.count == 4)
        #expect(ordering.orderedVertices == [c, b, d, a])
    }
    
    @Test func testReverseCuthillMcKeeOrderingPathGraph() {
        // Create a path graph: A-B-C-D
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let ordering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        
        // Verify all vertices are included
        #expect(ordering.orderedVertices.count == 4)
        #expect(ordering.orderedVertices == [d, c, b, a])
    }
    
    @Test func testReverseCuthillMcKeeOrderingStarGraph() {
        // Create a star graph: center connected to all others
        //   B
        //   |
        // A-C-D
        //   |
        //   E
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        graph.addEdge(from: c, to: e)
        graph.addEdge(from: e, to: c)
        
        let ordering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        
        // Verify all vertices are included
        #expect(ordering.orderedVertices.count == 5)
        #expect(ordering.orderedVertices == [e, d, b, c, a])
    }
    
    @Test func testReverseCuthillMcKeeOrderingCompleteGraph() {
        // Create a complete graph K4
        var graph = AdjacencyList()
        
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
        
        let ordering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        
        // Verify all vertices are included
        #expect(ordering.orderedVertices.count == 4)
        #expect(ordering.orderedVertices == [d, c, b, a])
    }
    
    // MARK: - Edge Cases
    
    @Test func testEmptyGraph() {
        let graph = AdjacencyList()
        
        let smallestLastOrdering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        let rcmOrdering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        
        #expect(smallestLastOrdering.orderedVertices.isEmpty)
        #expect(rcmOrdering.orderedVertices.isEmpty)
    }
    
    @Test func testSingleVertexGraph() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        
        let smallestLastOrdering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        let rcmOrdering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        
        #expect(smallestLastOrdering.orderedVertices == [a])
        #expect(rcmOrdering.orderedVertices == [a])
    }
    
    @Test func testTwoVertexGraph() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        let smallestLastOrdering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        let rcmOrdering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        
        #expect(smallestLastOrdering.orderedVertices.count == 2)
        #expect(smallestLastOrdering.orderedVertices == [b, a])
        
        #expect(rcmOrdering.orderedVertices.count == 2)
        #expect(rcmOrdering.orderedVertices == [b, a])
    }
    
    @Test func testDisconnectedGraph() {
        // Create two disconnected components: A-B and C-D
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let smallestLastOrdering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        let rcmOrdering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        
        // Verify all vertices are included
        #expect(smallestLastOrdering.orderedVertices.count == 4)
        #expect(smallestLastOrdering.orderedVertices == [d, c, b, a])
        
        #expect(rcmOrdering.orderedVertices.count == 4)
        #expect(rcmOrdering.orderedVertices == [d, c, b, a])
    }
    
    // MARK: - Deterministic Ordering Tests
    
    @Test func testDeterministicOrdering() {
        // Test that multiple runs produce the same result
        var graph = AdjacencyList()
        
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
        
        // Run multiple times and verify deterministic results
        let ordering1 = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        let ordering2 = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        let ordering3 = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        
        #expect(ordering1.orderedVertices == ordering2.orderedVertices)
        #expect(ordering2.orderedVertices == ordering3.orderedVertices)
        
        let rcm1 = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        let rcm2 = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        let rcm3 = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        
        #expect(rcm1.orderedVertices == rcm2.orderedVertices)
        #expect(rcm2.orderedVertices == rcm3.orderedVertices)
    }
    
    @Test func testOrderingConsistency() {
        // Test that the ordering is consistent with vertex positions
        var graph = AdjacencyList()
        
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
        
        let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        
        // Verify that position lookups are consistent
        for (index, vertex) in ordering.orderedVertices.enumerated() {
            #expect(ordering.position(of: vertex) == index)
            #expect(ordering.vertex(at: index) == vertex)
        }
        
        // Verify that all vertices have valid positions
        for vertex in [a, b, c, d] {
            let position = ordering.position(of: vertex)
            #expect(position != nil)
            #expect(position! >= 0)
            #expect(position! < ordering.orderedVertices.count)
        }
    }
    
    // MARK: - Complex Graph Tests
    
    @Test func testComplexGraphSmallestLast() {
        // Create a more complex graph with varying degrees
        //     B
        //    /|\
        //   A C D
        //    \|/
        //     E
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        // A connects to B and E
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: a, to: e)
        graph.addEdge(from: e, to: a)
        
        // B connects to A, C, D
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: d, to: b)
        
        // C connects to B and E
        graph.addEdge(from: c, to: e)
        graph.addEdge(from: e, to: c)
        
        // D connects to B and E
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: d)
        
        let ordering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        
        // Verify all vertices are included
        #expect(ordering.orderedVertices.count == 5)
        #expect(ordering.orderedVertices == [e, d, b, c, a])
    }
    
    @Test func testComplexGraphReverseCuthillMcKee() {
        // Create the same complex graph
        //     B
        //    /|\
        //   A C D
        //    \|/
        //     E
        var graph = AdjacencyList()
        
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        // A connects to B and E
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: a, to: e)
        graph.addEdge(from: e, to: a)
        
        // B connects to A, C, D
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: d, to: b)
        
        // C connects to B and E
        graph.addEdge(from: c, to: e)
        graph.addEdge(from: e, to: c)
        
        // D connects to B and E
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: d)
        
        let ordering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        
        // Verify all vertices are included
        #expect(ordering.orderedVertices.count == 5)
        #expect(ordering.orderedVertices == [d, c, e, b, a])
    }
    
    // MARK: - Algorithm Comparison Tests
    
    @Test func testAlgorithmComparison() {
        // Test that both algorithms produce valid orderings for the same graph
        var graph = AdjacencyList()
        
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
        
        let smallestLastOrdering = graph.orderVertices(using: SmallestLastVertexOrderingAlgorithm())
        let rcmOrdering = graph.orderVertices(using: ReverseCuthillMcKeeOrderingAlgorithm())
        
        // Both should include all vertices
        #expect(smallestLastOrdering.orderedVertices.count == 4)
        #expect(rcmOrdering.orderedVertices.count == 4)
        
        // Both should include the same set of vertices
        #expect(smallestLastOrdering.orderedVertices == [b, a, d, c])
        #expect(rcmOrdering.orderedVertices == [c, b, d, a])
        
        // The orderings may be different, but both should be valid
        #expect(smallestLastOrdering.orderedVertices != rcmOrdering.orderedVertices)
    }
}
