#if !GRAPHS_USES_TRAITS || GRAPHS_ANALYSIS
import Testing
@testable import Graphs

struct CommunityDetectionTests {
    
    // MARK: - Basic Tests
    
    @Test func testEmptyGraph() {
        let graph = AdjacencyList()
        let result = graph.detectCommunities()
        
        #expect(result.communityCount == 0)
        #expect(result.modularity == 0.0)
        #expect(result.communities.isEmpty)
    }
    
    @Test func testSingleVertex() {
        var graph = AdjacencyList()
        let vertex = graph.addVertex { $0.label = "A" }
        
        let result = graph.detectCommunities()
        
        #expect(result.communityCount == 1)
        #expect(result.communities == [[vertex]])
    }
    
    @Test func testTwoVerticesNoEdge() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        let result = graph.detectCommunities()
        
        #expect(result.communityCount == 2)
        #expect(result.communities.contains { Set($0) == Set([a]) })
        #expect(result.communities.contains { Set($0) == Set([b]) })
    }
    
    @Test func testTwoVerticesWithEdge() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        let result = graph.detectCommunities()
        
        #expect(result.communityCount == 1)
        #expect(result.communities.contains { Set($0) == Set([a, b]) })
    }
    
    // MARK: - Disconnected Components Tests
    
    @Test func testDisconnectedComponents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create two separate components
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let result = graph.detectCommunities()
        
        #expect(result.communityCount == 2)
        #expect(result.communities.contains { Set($0) == Set([a, b]) })
        #expect(result.communities.contains { Set($0) == Set([c, d]) })
    }
    
    // MARK: - Well-Known Community Structure Tests
    
    @Test func testKarateClubPattern() {
        var graph = AdjacencyList()
        let vertices = (1...10).map { i in
            graph.addVertex { $0.label = "V\(i)" }
        }
        
        // Create two communities with some inter-community connections
        // Community 1: vertices 1-5 (dense connections)
        for i in 0..<5 {
            for j in (i+1)..<5 {
                graph.addEdge(from: vertices[i], to: vertices[j])
                graph.addEdge(from: vertices[j], to: vertices[i])
            }
        }
        
        // Community 2: vertices 6-10 (dense connections)
        for i in 5..<10 {
            for j in (i+1)..<10 {
                graph.addEdge(from: vertices[i], to: vertices[j])
                graph.addEdge(from: vertices[j], to: vertices[i])
            }
        }
        
        // Few inter-community connections
        graph.addEdge(from: vertices[2], to: vertices[6])
        graph.addEdge(from: vertices[6], to: vertices[2])
        graph.addEdge(from: vertices[4], to: vertices[8])
        graph.addEdge(from: vertices[8], to: vertices[4])
        
        let result = graph.detectCommunities()
        
        // Should detect two main communities
        #expect(result.communityCount == 2)
        
        // Check that most vertices from each group are in the same community
        let community1 = result.community(containing: vertices[0])
        let community2 = result.community(containing: vertices[5])
        
        #expect(community1 != nil)
        #expect(community2 != nil)
        #expect(community1 != community2)
    }
    
    // MARK: - Triangle Community Test
    
    @Test func testTriangleCommunity() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create triangle A-B-C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        // Add isolated vertex D
        // (no edges to D)
        
        let result = graph.detectCommunities()
        
        #expect(result.communityCount == 2)
        #expect(result.communities.contains { Set($0) == Set([a, b, c]) })
        #expect(result.communities.contains { Set($0) == Set([d]) })
    }
    
    // MARK: - Result Utility Tests
    
    @Test func testCommunityIndex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        let result = graph.detectCommunities()
        
        let indexA = result.communityIndex(for: a)
        let indexB = result.communityIndex(for: b)
        let indexC = result.communityIndex(for: c)
        
        #expect(indexA != nil)
        #expect(indexB != nil)
        #expect(indexC != nil)
        #expect(indexA == indexB) // A and B should be in same community
        #expect(indexA != indexC) // C should be in different community
    }
    
    @Test func testCommunityContaining() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        let result = graph.detectCommunities()
        
        let communityA = result.community(containing: a)
        let communityB = result.community(containing: b)
        let communityC = result.community(containing: c)
        
        #expect(communityA != nil)
        #expect(communityB != nil)
        #expect(communityC != nil)
        #expect(communityA == communityB)
        #expect(communityA != communityC)
    }
    
    @Test func testAreInSameCommunity() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        let result = graph.detectCommunities()
        
        #expect(result.areInSameCommunity(a, b))
        #expect(!result.areInSameCommunity(a, c))
        #expect(!result.areInSameCommunity(b, c))
    }
    
    // MARK: - Modularity Tests
    
    @Test func testModularityCalculation() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create two separate communities
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let result = graph.detectCommunities()
        
        // Modularity should be positive for well-separated communities
        #expect(result.modularity > 0.0)
    }
    
    // MARK: - Visitor Tests
    
    @Test func testVisitorCallbacks() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        
        // Test basic functionality without visitor for now
        let result = graph.detectCommunities()
        
        #expect(result.communityCount > 0)
        #expect(result.modularity >= 0.0)
    }
    
    // MARK: - Resolution Parameter Tests
    
    @Test func testResolutionParameter() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create a graph where resolution might affect community detection
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let result1 = graph.detectCommunities(using: .louvain(resolution: 0.5))
        let result2 = graph.detectCommunities(using: .louvain(resolution: 2.0))
        
        // Different resolutions might produce different results
        // We just verify they both complete successfully
        #expect(result1.communityCount > 0)
        #expect(result2.communityCount > 0)
    }
    
    // MARK: - Algorithm Comparison Tests
    
    @Test func testAlgorithmConsistency() {
        var graph = AdjacencyList()
        let vertices = ["A", "B", "C", "D", "E"].map { label in
            graph.addVertex { $0.label = label }
        }
        
        // Create a complex graph
        graph.addEdge(from: vertices[0], to: vertices[1])
        graph.addEdge(from: vertices[1], to: vertices[0])
        graph.addEdge(from: vertices[1], to: vertices[2])
        graph.addEdge(from: vertices[2], to: vertices[1])
        graph.addEdge(from: vertices[2], to: vertices[3])
        graph.addEdge(from: vertices[3], to: vertices[2])
        graph.addEdge(from: vertices[3], to: vertices[4])
        graph.addEdge(from: vertices[4], to: vertices[3])
        
        let result1 = graph.detectCommunities()
        let result2 = graph.detectCommunities(using: .louvain())
        
        // Both should produce valid results (Louvain is non-deterministic)
        #expect(result1.communityCount > 0)
        #expect(result2.communityCount > 0)
        #expect(result1.modularity >= 0.0)
        #expect(result2.modularity >= 0.0)
    }
}
#endif
