#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
@testable import Graphs
import Testing

struct ShortestPathsForAllPairsTests {
    
    @Test func floydWarshallBasic() {
        var graph = AdjacencyList()
        
        // Create a simple test graph: A -> B -> C
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        let result = graph.shortestPathsForAllPairs(using: .floydWarshall(weight: .property(\.weight)))
        
        // Test some known shortest paths
        #expect(result.distance(from: a, to: c) == 5.0) // A -> B -> C (2 + 3 = 5)
        #expect(result.distance(from: a, to: b) == 2.0) // A -> B
        #expect(result.distance(from: a, to: a) == 0.0) // Self-loop
        #expect(result.distance(from: b, to: c) == 3.0) // B -> C
    }
    
    @Test func floydWarshallComplex() {
        var graph = AdjacencyList()
        
        // Create a more complex graph with multiple paths
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 4 }
        graph.addEdge(from: b, to: c) { $0.weight = 2 }
        graph.addEdge(from: b, to: d) { $0.weight = 7 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        
        let result = graph.shortestPathsForAllPairs(using: .floydWarshall(weight: .property(\.weight)))
        
        // Test shortest paths
        #expect(result.distance(from: a, to: d) == 4.0) // A -> B -> C -> D (1 + 2 + 1 = 4)
        #expect(result.distance(from: a, to: c) == 3.0) // A -> B -> C (1 + 2 = 3)
        #expect(result.distance(from: b, to: d) == 3.0) // B -> C -> D (2 + 1 = 3)
    }
    
    @Test func floydWarshallUnreachable() {
        var graph = AdjacencyList()
        
        // Create disconnected components
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 2 }
        // No connection between A-B and C-D components
        
        let result = graph.shortestPathsForAllPairs(using: .floydWarshall(weight: .property(\.weight)))
        
        // Test unreachable paths
        #expect(result.distance(from: a, to: c) == .infinite)
        #expect(result.distance(from: a, to: d) == .infinite)
        #expect(result.distance(from: b, to: c) == .infinite)
        #expect(result.distance(from: b, to: d) == .infinite)
        
        // Test reachable paths
        #expect(result.distance(from: a, to: b) == 1.0)
        #expect(result.distance(from: c, to: d) == 2.0)
    }
    
    @Test func floydWarshallSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        
        let result = graph.shortestPathsForAllPairs(using: .floydWarshall(weight: .property(\.weight)))
        
        #expect(result.distance(from: a, to: a) == 0.0)
    }
    
    @Test func floydWarshallEmptyGraph() {
        let graph = AdjacencyList()
        
        let result = graph.shortestPathsForAllPairs(using: .floydWarshall(weight: .property(\.weight)))
        
        #expect(result.distances.isEmpty)
    }
    
    // MARK: - Core Behavior (Johnson's)
    
    @Test func johnsonBasic() {
        var graph = AdjacencyList()
        
        // Create a simple test graph: A -> B -> C
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = 3 }
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        // Test some known shortest paths
        #expect(result.distance(from: a, to: c) == 5.0) // A -> B -> C (2 + 3 = 5)
        #expect(result.distance(from: a, to: b) == 2.0) // A -> B
        #expect(result.distance(from: a, to: a) == 0.0) // Self-loop
        #expect(result.distance(from: b, to: c) == 3.0) // B -> C
    }
    
    @Test func johnsonHandlesNegativeWeights() {
        var graph = AdjacencyList()
        
        // Create a graph with negative weights: A -> B -> C with negative edge
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = -2 }
        graph.addEdge(from: a, to: c) { $0.weight = 3 }
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        // Test shortest paths with negative weights
        #expect(result.distance(from: a, to: c) == -1.0) // A -> B -> C (1 + (-2) = -1)
        #expect(result.distance(from: a, to: b) == 1.0) // A -> B
        #expect(result.distance(from: b, to: c) == -2.0) // B -> C
    }
    
    @Test func johnsonComplex() {
        var graph = AdjacencyList()
        
        // Create a more complex graph with multiple paths and negative weights
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 4 }
        graph.addEdge(from: b, to: c) { $0.weight = -2 }
        graph.addEdge(from: b, to: d) { $0.weight = 7 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        // Test shortest paths
        #expect(result.distance(from: a, to: d) == 0.0) // A -> B -> C -> D (1 + (-2) + 1 = 0)
        #expect(result.distance(from: a, to: c) == -1.0) // A -> B -> C (1 + (-2) = -1)
        #expect(result.distance(from: b, to: d) == -1.0) // B -> C -> D (-2 + 1 = -1)
    }
    
    @Test func johnsonHandlesUnreachableVertex() {
        var graph = AdjacencyList()
        
        // Create disconnected components
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 2 }
        // No connection between A-B and C-D components
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        // Test unreachable paths
        #expect(result.distance(from: a, to: c) == .infinite)
        #expect(result.distance(from: a, to: d) == .infinite)
        #expect(result.distance(from: b, to: c) == .infinite)
        #expect(result.distance(from: b, to: d) == .infinite)
        
        // Test reachable paths
        #expect(result.distance(from: a, to: b) == 1.0)
        #expect(result.distance(from: c, to: d) == 2.0)
    }
    
    @Test func johnsonHandlesSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        #expect(result.distance(from: a, to: a) == 0.0)
    }
    
    @Test func johnsonHandlesEmptyGraph() {
        let graph = AdjacencyList()
        
        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))
        
        #expect(result.distances.isEmpty)
    }
    
    @Test func johnsonDetectsNegativeCycle() {
        var graph = AdjacencyList()

        // Create a graph with a negative cycle: A -> B -> C -> A
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 1 }
        graph.addEdge(from: c, to: a) { $0.weight = -3 } // Creates negative cycle

        let result = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))

        // Johnson's algorithm should detect the negative cycle and return empty result
        #expect(result.distances.isEmpty)
    }

    // MARK: - Result API Coverage

    @Test func hasPaths() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 2 }
        // No edge c→a, so c cannot reach a

        let result = graph.shortestPathsForAllPairs(using: .floydWarshall(weight: .property(\.weight)))

        #expect(result.hasPath(from: a, to: b), "a can reach b directly")
        #expect(result.hasPath(from: a, to: c), "a can reach c via b")
        #expect(!result.hasPath(from: c, to: a), "c cannot reach a — no return edges")
        #expect(!result.hasPath(from: c, to: b), "c cannot reach b either")
    }

    @Test func reconstructsPathFromPredecessors() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 2 }

        let result = graph.shortestPathsForAllPairs(using: .floydWarshall(weight: .property(\.weight)))
        let path = result.path(from: a, to: c, in: graph)

        #expect(path != nil, "path(from:to:in:) must return non-nil when a path exists")
        #expect(path?.source == a)
        #expect(path?.destination == c)
        #expect(path?.vertices.count == 3, "path a→b→c visits 3 vertices")
        #expect(path?.edges.count == 2, "path uses 2 edges")

        // Unreachable pair returns nil
        let noPath = result.path(from: c, to: a, in: graph)
        #expect(noPath == nil, "path(from:to:in:) must return nil when c cannot reach a")
    }

    @Test func defaultWeightConvenienceUsesFloydWarshall() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b) { $0.weight = 5 }

        // shortestPathsForAllPairs(weight:) is the no-algorithm default — exercises the convenience API
        let result = graph.shortestPathsForAllPairs(weight: .property(\.weight))
        #expect(result.distance(from: a, to: b) == 5.0, "default convenience should find a→b with cost 5")
        #expect(result.distance(from: a, to: a) == 0.0, "self-distance is always 0")
    }

    // MARK: - Multi-Backend Coverage

    @Test func floydWarshallAndJohnsonAgree_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: b, to: c) { $0.weight = 3 }
            graph.addEdge(from: a, to: c) { $0.weight = 10 } // longer direct path

            let fw = graph.shortestPathsForAllPairs(using: .floydWarshall(weight: .property(\.weight)))
            let jn = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)))

            #expect(fw.distance(from: a, to: b) == 2.0,  "[\(backend)] FW: a→b = 2")
            #expect(fw.distance(from: a, to: c) == 5.0,  "[\(backend)] FW: a→b→c (5) beats a→c (10)")
            #expect(jn.distance(from: a, to: b) == 2.0,  "[\(backend)] Johnson: a→b = 2")
            #expect(jn.distance(from: a, to: c) == 5.0,  "[\(backend)] Johnson: a→b→c (5) beats a→c (10)")
            #expect(fw.distance(from: a, to: b) == jn.distance(from: a, to: b),
                    "[\(backend)] FW and Johnson must agree on a→b")
            #expect(fw.distance(from: a, to: c) == jn.distance(from: a, to: c),
                    "[\(backend)] FW and Johnson must agree on a→c")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    // MARK: - Visitor Support

    /// Floyd-Warshall's `completeIntermediateVertex` fires once per intermediate vertex (one per
    /// vertex in the graph). Two composed visitors must each receive the same events.
    @Test func floydWarshallComposedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 1.0 }

        var completed1 = 0; var completed2 = 0
        var examined1 = 0;  var examined2 = 0

        var v1 = FloydWarshall<DefaultAdjacencyList, Double>.Visitor()
        v1.completeIntermediateVertex = { _ in completed1 += 1 }
        v1.examineVertex              = { _ in examined1 += 1 }

        var v2 = FloydWarshall<DefaultAdjacencyList, Double>.Visitor()
        v2.completeIntermediateVertex = { _ in completed2 += 1 }
        v2.examineVertex              = { _ in examined2 += 1 }

        let combined = v1.combined(with: v2)
        _ = graph.shortestPathsForAllPairs(using: .floydWarshall(weight: .property(\.weight)).withVisitor(combined))

        // Floyd-Warshall iterates over each vertex as an intermediate: 3 vertices → 3 completions
        #expect(completed1 == 3, "completeIntermediateVertex must fire once per vertex (3 vertices)")
        #expect(completed2 == 3)
        #expect(examined1 >= 1, "examineVertex must fire at least once")
        #expect(examined2 >= 1)
        #expect(completed1 == completed2, "both composed visitors must see identical completeIntermediateVertex events")
        #expect(examined1 == examined2, "both composed visitors must see identical examineVertex events")
    }

    /// Johnson's `startDijkstraFromSource` fires once per source vertex —
    /// it's the unique high-level event that marks each Dijkstra invocation.
    /// Two composed visitors must each receive the same events.
    @Test func johnsonComposedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 1.0 }

        var started1 = 0; var started2 = 0
        var completed1 = 0; var completed2 = 0

        var v1 = Johnson<DefaultAdjacencyList, Double>.Visitor()
        v1.startDijkstraFromSource    = { _ in started1 += 1 }
        v1.completeDijkstraFromSource = { _ in completed1 += 1 }

        var v2 = Johnson<DefaultAdjacencyList, Double>.Visitor()
        v2.startDijkstraFromSource    = { _ in started2 += 1 }
        v2.completeDijkstraFromSource = { _ in completed2 += 1 }

        let combined = v1.combined(with: v2)
        _ = graph.shortestPathsForAllPairs(using: .johnson(edgeWeight: .property(\.weight)).withVisitor(combined))

        // Johnson runs Dijkstra from each of the 3 vertices → start/complete each fire 3 times
        #expect(started1 == 3, "startDijkstraFromSource must fire once per vertex (3 vertices)")
        #expect(started2 == 3)
        #expect(completed1 == 3, "completeDijkstraFromSource must fire once per vertex (3 vertices)")
        #expect(completed2 == 3)
        #expect(started1 == started2, "both composed visitors must see identical start events")
        #expect(completed1 == completed2, "both composed visitors must see identical complete events")
    }
}
#endif
