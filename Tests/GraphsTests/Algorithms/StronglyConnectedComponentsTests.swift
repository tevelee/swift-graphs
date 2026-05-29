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

    // MARK: - Visitor Support

    /// Exercises all seven Tarjan visitor events through a composed visitor pair.
    ///
    /// Graph: a→c, c→d, d→c, a→b, b→c — three SCCs: {c,d}, {b}, {a}.
    /// - `discoverVertex` fires for each of the 4 vertices.
    /// - `examineEdge` fires for each of the 5 edges.
    /// - `backEdge` fires for d→c (c is a DFS ancestor of d still on the stack).
    /// - `crossEdge` fires for b→c (c's SCC is already complete when b is processed).
    /// - `finishVertex` fires for each of the 4 vertices.
    /// - `startComponent` fires once per SCC (3 times).
    /// - `finishComponent` fires once per SCC (3 times).
    @Test func tarjanComposedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        // c↔d form one SCC; b and a are isolated SCCs; b→c and a→b are cross/tree edges
        graph.addEdge(from: a, to: c)   // tree edge into c's SCC
        graph.addEdge(from: c, to: d)   // within the c↔d SCC
        graph.addEdge(from: d, to: c)   // back edge (creates c↔d cycle)
        graph.addEdge(from: a, to: b)   // tree edge into b
        graph.addEdge(from: b, to: c)   // cross edge (c's SCC already done)

        var discovered1 = 0; var discovered2 = 0
        var examEdge1 = 0;   var examEdge2 = 0
        var back1 = 0;       var back2 = 0
        var cross1 = 0;      var cross2 = 0
        var finished1 = 0;   var finished2 = 0
        var started1 = 0;    var started2 = 0
        var completed1 = 0;  var completed2 = 0

        var v1 = Tarjan<DefaultAdjacencyList>.Visitor()
        v1.discoverVertex  = { _ in discovered1 += 1 }
        v1.examineEdge     = { _ in examEdge1 += 1 }
        v1.backEdge        = { _ in back1 += 1 }
        v1.crossEdge       = { _ in cross1 += 1 }
        v1.finishVertex    = { _ in finished1 += 1 }
        v1.startComponent  = { _ in started1 += 1 }
        v1.finishComponent = { _ in completed1 += 1 }

        var v2 = Tarjan<DefaultAdjacencyList>.Visitor()
        v2.discoverVertex  = { _ in discovered2 += 1 }
        v2.examineEdge     = { _ in examEdge2 += 1 }
        v2.backEdge        = { _ in back2 += 1 }
        v2.crossEdge       = { _ in cross2 += 1 }
        v2.finishVertex    = { _ in finished2 += 1 }
        v2.startComponent  = { _ in started2 += 1 }
        v2.finishComponent = { _ in completed2 += 1 }

        let combined = v1.combined(with: v2)
        _ = Tarjan(on: graph).stronglyConnectedComponents(visitor: combined)

        #expect(discovered1 == 4,  "discoverVertex fires for all 4 vertices")
        #expect(discovered2 == 4)
        #expect(examEdge1 == 5,    "examineEdge fires for all 5 edges")
        #expect(examEdge2 == 5)
        #expect(back1 >= 1,        "d→c is a back edge within the c↔d cycle")
        #expect(back2 >= 1)
        #expect(cross1 >= 1,       "b→c is a cross edge (c already in finished SCC)")
        #expect(cross2 >= 1)
        #expect(finished1 == 4,    "finishVertex fires for all 4 vertices")
        #expect(finished2 == 4)
        #expect(started1 == 3,     "startComponent fires once per SCC: {c,d}, {b}, {a}")
        #expect(started2 == 3)
        #expect(completed1 == 3,   "finishComponent fires once per SCC")
        #expect(completed2 == 3)
        // Both composed visitors must see identical event counts
        #expect(discovered1 == discovered2)
        #expect(examEdge1 == examEdge2)
        #expect(back1 == back2)
        #expect(cross1 == cross2)
        #expect(finished1 == finished2)
        #expect(started1 == started2)
        #expect(completed1 == completed2)
    }

    /// Exercises all five Kosaraju visitor events through a composed visitor pair.
    ///
    /// Graph: a→b→c→a (one 3-vertex SCC).
    /// - `discoverVertex` fires once per vertex per DFS pass (3 vertices × 2 passes = 6).
    /// - `examineEdge` fires for each edge traversal across both passes.
    /// - `finishVertex` fires for each vertex in each DFS pass.
    /// - `startComponent` fires once (one SCC).
    /// - `finishComponent` fires once (one SCC).
    @Test func kosarajuComposedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a) // cycle: one SCC {a,b,c}

        var discovered1 = 0; var discovered2 = 0
        var examEdge1 = 0;   var examEdge2 = 0
        var finished1 = 0;   var finished2 = 0
        var started1 = 0;    var started2 = 0
        var completed1 = 0;  var completed2 = 0

        var v1 = Kosaraju<DefaultAdjacencyList>.Visitor()
        v1.discoverVertex  = { _ in discovered1 += 1 }
        v1.examineEdge     = { _ in examEdge1 += 1 }
        v1.finishVertex    = { _ in finished1 += 1 }
        v1.startComponent  = { _ in started1 += 1 }
        v1.finishComponent = { _ in completed1 += 1 }

        var v2 = Kosaraju<DefaultAdjacencyList>.Visitor()
        v2.discoverVertex  = { _ in discovered2 += 1 }
        v2.examineEdge     = { _ in examEdge2 += 1 }
        v2.finishVertex    = { _ in finished2 += 1 }
        v2.startComponent  = { _ in started2 += 1 }
        v2.finishComponent = { _ in completed2 += 1 }

        let combined = v1.combined(with: v2)
        _ = Kosaraju(on: graph).stronglyConnectedComponents(visitor: combined)

        // Kosaraju resets vertex colors between its two DFS passes, so discoverVertex
        // fires once per vertex in pass 1 and once more per vertex in pass 2 → 3+3=6
        #expect(discovered1 == 6,  "discoverVertex fires 3 times per DFS pass × 2 passes")
        #expect(discovered2 == 6)
        #expect(examEdge1 >= 3,    "examineEdge fires for at least all 3 edges")
        #expect(examEdge2 >= 3)
        #expect(finished1 >= 3,    "finishVertex fires for all vertices in DFS pass")
        #expect(finished2 >= 3)
        #expect(started1 == 1,     "startComponent fires once for the single SCC {a,b,c}")
        #expect(started2 == 1)
        #expect(completed1 == 1,   "finishComponent fires once for the single SCC")
        #expect(completed2 == 1)
        // Both composed visitors must see identical event counts
        #expect(discovered1 == discovered2)
        #expect(examEdge1 == examEdge2)
        #expect(finished1 == finished2)
        #expect(started1 == started2)
        #expect(completed1 == completed2)
    }

    // MARK: - Result API Coverage

    /// `areInSameComponent` returns true iff two vertices belong to the same SCC.
    @Test func areInSameComponentAPI() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        // Cycle a→b→c→a (one SCC) plus isolated d
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        let d = graph.addVertex { $0.label = "D" }

        let result = graph.stronglyConnectedComponents(using: .tarjan())
        #expect(result.areInSameComponent(a, b), "a and b share the cycle SCC")
        #expect(result.areInSameComponent(b, c), "b and c share the cycle SCC")
        #expect(!result.areInSameComponent(a, d), "d is isolated from the cycle SCC")
    }

    /// `componentIndex(for:)` returns the correct index for each vertex.
    @Test func componentIndexForVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        // c is isolated

        let result = graph.stronglyConnectedComponents(using: .tarjan())
        let idxA = result.componentIndex(for: a)
        let idxB = result.componentIndex(for: b)
        let idxC = result.componentIndex(for: c)

        #expect(idxA != nil && idxB != nil && idxC != nil)
        #expect(idxA == idxB, "a and b form one SCC")
        #expect(idxA != idxC, "c is in a separate SCC")
    }

    /// `component(containing:)` returns the full SCC for the given vertex.
    @Test func componentContainingVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)  // {a,b} form one SCC
        // c is isolated

        let result = graph.stronglyConnectedComponents(using: .tarjan())
        let compA = result.component(containing: a)
        let compC = result.component(containing: c)

        #expect(compA != nil)
        #expect(compA?.count == 2, "{a,b} SCC has 2 vertices")
        #expect(compA?.contains(a) == true && compA?.contains(b) == true)
        #expect(compC?.count == 1, "c is its own SCC")
    }

    /// `stronglyConnectedComponents()` no-argument convenience uses Kosaraju by default.
    @Test func noArgConvenienceUsesDefaultAlgorithm() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)

        let result = graph.stronglyConnectedComponents()  // exercises the no-arg default
        #expect(result.componentCount == 1, "a and b form one mutual SCC")
        #expect(result.areInSameComponent(a, b))
    }

    // MARK: - Result API guard-failure branches and conformances

    /// `component(containing:)` returns `nil` when the vertex is not in the result.
    /// `areInSameComponent` returns `false` when one vertex has no recorded component.
    @Test func resultAPIGuardFailureBranches() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)

        let result = graph.stronglyConnectedComponents(using: .tarjan())

        // Add a third vertex to the ORIGINAL graph after computing the SCC —
        // its id (2) is not in the result which only knows about vertices 0 and 1.
        let x = graph.addVertex()  // id=2, added after SCC was computed

        // component(containing:) guard-failure → nil
        #expect(result.component(containing: x) == nil,
                "vertex not in the SCC result must return nil from component(containing:)")

        // areInSameComponent guard-failure → false
        #expect(!result.areInSameComponent(a, x),
                "unknown vertex must return false from areInSameComponent")
    }

    /// `StronglyConnectedComponentsResult` has `Equatable` and `Hashable` conformances.
    /// Using `==` and storing in a `Set` exercises those code paths.
    @Test func resultEquatableAndHashable() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)

        let r1 = graph.stronglyConnectedComponents(using: .tarjan())
        let r2 = graph.stronglyConnectedComponents(using: .tarjan())

        // Equatable: same graph, same algorithm → equal results
        #expect(r1 == r2, "identical SCC results must be equal")

        // Hashable: can be stored in a Set
        let set: Set = [r1, r2]
        #expect(set.count == 1, "two equal SCC results hash to the same bucket")
    }
}
#endif
