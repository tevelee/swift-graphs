#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
@testable import Graphs
import Testing

struct TopologicalSortTests {
    
    // MARK: - Core Behavior (Kahn)
    
    @Test func kahnSortsLinearChain() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()        
        // Create a DAG: A -> B -> C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        let result = graph.topologicalSort(using: .kahn())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices == [a, b, c])
    }
    
    @Test func kahnSortsComplexDAG() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()        
        // Create a complex DAG
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: e)
        
        let result = graph.topologicalSort(using: .kahn())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices.count == 5)
        
        // A should come before B and C
        let aIndex = result.sortedVertices.firstIndex(of: a)!
        let bIndex = result.sortedVertices.firstIndex(of: b)!
        let cIndex = result.sortedVertices.firstIndex(of: c)!
        #expect(aIndex < bIndex)
        #expect(aIndex < cIndex)
        
        // B and C should come before D
        let dIndex = result.sortedVertices.firstIndex(of: d)!
        #expect(bIndex < dIndex)
        #expect(cIndex < dIndex)
        
        // D should come before E
        let eIndex = result.sortedVertices.firstIndex(of: e)!
        #expect(dIndex < eIndex)
    }
    
    @Test func kahnDetectsCycle() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()        
        // Create a cycle: A -> B -> C -> A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        let result = graph.topologicalSort(using: .kahn())
        
        #expect(!result.isValid)
        #expect(result.hasCycle)
        #expect(result.sortedVertices.count < 3) // Not all vertices processed
        #expect(result.cycleVertices.count > 0)
    }
    
    @Test func kahnHandlesEmptyGraph() {
        let graph = AdjacencyList()
        
        let result = graph.topologicalSort(using: .kahn())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices.isEmpty)
    }
    
    @Test func kahnHandlesSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let result = graph.topologicalSort(using: .kahn())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices == [a])
    }
    
    @Test func kahnHandlesDisconnectedComponents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()        
        // Two disconnected DAGs
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        let result = graph.topologicalSort(using: .kahn())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices == [a, c, b, d])
    }
    
    // MARK: - Core Behavior (DFS)
    
    @Test func dfsSortsLinearChain() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()        
        // Create a DAG: A -> B -> C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        let result = graph.topologicalSort(using: .dfs())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices == [a, b, c])
    }
    
    @Test func dfsSortsComplexDAG() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()        
        // Create a complex DAG
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: e)
        
        let result = graph.topologicalSort(using: .dfs())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices.count == 5)
        
        // A should come before B and C
        let aIndex = result.sortedVertices.firstIndex(of: a)!
        let bIndex = result.sortedVertices.firstIndex(of: b)!
        let cIndex = result.sortedVertices.firstIndex(of: c)!
        #expect(aIndex < bIndex)
        #expect(aIndex < cIndex)
        
        // B and C should come before D
        let dIndex = result.sortedVertices.firstIndex(of: d)!
        #expect(bIndex < dIndex)
        #expect(cIndex < dIndex)
        
        // D should come before E
        let eIndex = result.sortedVertices.firstIndex(of: e)!
        #expect(dIndex < eIndex)
    }
    
    @Test func dfsDetectsCycle() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()        
        // Create a cycle: A -> B -> C -> A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        let result = graph.topologicalSort(using: .dfs())
        
        #expect(!result.isValid)
        #expect(result.hasCycle)
        #expect(result.cycleVertices.count > 0)
    }
    
    @Test func dfsHandlesEmptyGraph() {
        let graph = AdjacencyList()
        
        let result = graph.topologicalSort(using: .dfs())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices.isEmpty)
    }
    
    @Test func dfsHandlesSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let result = graph.topologicalSort(using: .dfs())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices == [a])
    }
    
    @Test func dfsHandlesDisconnectedComponents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()        
        // Two disconnected DAGs
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)
        
        let result = graph.topologicalSort(using: .dfs())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices == [c, d, a, b])
    }
    
    // MARK: - Algorithm Comparison
    
    @Test func kahnAndDFSProduceSameVertexSet() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()        
        // Create a complex DAG
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: e)
        
        let kahn = Kahn<DefaultAdjacencyList>()
        let kahnResult = kahn.topologicalSort(in: graph, visitor: nil)
        
        let dfs = DFSTopologicalSort<DefaultAdjacencyList>()
        let dfsResult = dfs.topologicalSort(in: graph, visitor: nil)
        
        // Both should be valid
        #expect(kahnResult.isValid)
        #expect(dfsResult.isValid)
        
        // Both should have the same number of vertices
        #expect(kahnResult.sortedVertices.count == dfsResult.sortedVertices.count)
        
        // Both should contain all vertices
        #expect(Set(kahnResult.sortedVertices) == Set(dfsResult.sortedVertices))
        
        // Both should have the same validity
        #expect(kahnResult.hasCycle == dfsResult.hasCycle)
    }
    
    // MARK: - API Convenience
    
    @Test func graphExtensionUsesKahn() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        let result = graph.topologicalSort(using: .kahn())
        
        #expect(result.isValid)
        #expect(result.sortedVertices == [a, b, c])
    }
    
    @Test func graphExtensionUsesDFS() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        let result = graph.topologicalSort(using: .dfs())
        
        #expect(result.isValid)
        #expect(result.sortedVertices == [a, b, c])
    }
    
    // MARK: - Visitor Support
    
    @Test func kahnVisitorObservesEvents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        var discoveredVertices: [String] = []
        var examinedEdges: Int = 0
        var finishedVertices: [String] = []
        
        var visitor = Kahn<DefaultAdjacencyList>.Visitor()
        visitor.discoverVertex = { vertex in
            discoveredVertices.append(graph[vertex].label)
        }
        visitor.examineEdge = { _ in
            examinedEdges += 1
        }
        visitor.finishVertex = { vertex in
            finishedVertices.append(graph[vertex].label)
        }
        
        let result = graph.topologicalSort(using: .kahn().withVisitor(visitor))
        
        #expect(result.isValid)
        #expect(discoveredVertices.count == 3)
        #expect(examinedEdges >= 2)
        #expect(finishedVertices.count == 3)
    }
    
    @Test func dfsVisitorObservesEvents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        var discoveredVertices: [String] = []
        var examinedEdges: Int = 0
        var treeEdges: Int = 0
        var finishedVertices: [String] = []
        
        var visitor = DFSTopologicalSort<DefaultAdjacencyList>.Visitor()
        visitor.discoverVertex = { vertex in
            discoveredVertices.append(graph[vertex].label)
        }
        visitor.examineEdge = { _ in
            examinedEdges += 1
        }
        visitor.treeEdge = { _ in
            treeEdges += 1
        }
        visitor.finishVertex = { vertex in
            finishedVertices.append(graph[vertex].label)
        }
        
        let result = graph.topologicalSort(using: .dfs().withVisitor(visitor))
        
        #expect(result.isValid)
        #expect(discoveredVertices.count == 3)
        #expect(examinedEdges == 2)
        #expect(treeEdges == 2)
        #expect(finishedVertices.count == 3) // DFS finishes in reverse order
    }
    
    @Test func cycleDetectionVisitorReportsCycle() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()        
        // Create a cycle
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)
        
        var cycleDetected = false
        var cycleVertices: [String] = []
        
        var kahnVisitor = Kahn<DefaultAdjacencyList>.Visitor()
        kahnVisitor.detectCycle = { vertices in
            cycleDetected = true
            cycleVertices = vertices.map { graph[$0].label }
        }
        
        let result = graph.topologicalSort(using: .kahn().withVisitor(kahnVisitor))
        
        #expect(!result.isValid)
        #expect(result.hasCycle)
        #expect(cycleDetected)
        #expect(!cycleVertices.isEmpty)
    }
    
    // MARK: - Visitor Support

    /// Exercises all four Kahn visitor events through a composed visitor pair.
    ///
    /// Graph: a→b→c (chain DAG).
    /// - `discoverVertex` fires once per vertex when dequeued (3 times).
    /// - `examineEdge` fires **twice** per edge: once during the in-degree computation pass
    ///   and once when the source vertex is dequeued and its neighbors are updated.
    ///   For 2 edges that is 4 total.
    /// - `finishVertex` fires once per vertex in topological order (3 times).
    /// - `detectCycle` is absent because the graph is acyclic.
    @Test func composedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        var discovered1 = 0;  var discovered2 = 0
        var examEdge1 = 0;    var examEdge2 = 0
        var finished1 = 0;    var finished2 = 0

        var visitor1 = Kahn<DefaultAdjacencyList>.Visitor()
        visitor1.discoverVertex = { _ in discovered1 += 1 }
        visitor1.examineEdge    = { _ in examEdge1 += 1 }
        visitor1.finishVertex   = { _ in finished1 += 1 }

        var visitor2 = Kahn<DefaultAdjacencyList>.Visitor()
        visitor2.discoverVertex = { _ in discovered2 += 1 }
        visitor2.examineEdge    = { _ in examEdge2 += 1 }
        visitor2.finishVertex   = { _ in finished2 += 1 }

        let combinedVisitor = visitor1.combined(with: visitor2)
        let result = graph.topologicalSort(using: .kahn().withVisitor(combinedVisitor))

        #expect(result.isValid,    "a→b→c is a valid DAG with a unique topological order")
        #expect(discovered1 == 3,  "discoverVertex fires for all 3 vertices")
        #expect(discovered2 == 3)
        // Kahn visits each edge twice: once in the initial in-degree scan and once
        // when the edge's source vertex is dequeued and neighbors' degrees are decremented.
        #expect(examEdge1 == 4,    "examineEdge fires 4 times (2 edges × 2 passes)")
        #expect(examEdge2 == 4)
        #expect(finished1 == 3,    "finishVertex fires for all 3 vertices")
        #expect(finished2 == 3)
        // Both composed visitors must see identical event counts
        #expect(discovered1 == discovered2)
        #expect(examEdge1 == examEdge2)
        #expect(finished1 == finished2)
    }

    /// Exercises all eight DFSTopologicalSort visitor events through a composed visitor pair.
    ///
    /// Graph: two disconnected components.
    /// - Component 1: a→b (tree), b→a (back — creates cycle, b→a where a is gray ancestor).
    ///   DFS visits this component first; a and b both finish (go BLACK) before component 2 starts.
    /// - Component 2: c→b (cross — b is already BLACK), c→d (tree).
    ///
    /// Implementation note: DFSTopologicalSort does not track discovery times. It classifies
    /// edges as `treeEdge` (WHITE destination), `backEdge` (GRAY destination), or `crossEdge`
    /// (BLACK destination). There is no `forwardEdge` call in the implementation — both what
    /// would classically be "forward edges" and "cross edges" produce a `crossEdge` event.
    ///
    /// Expected events:
    /// - `discoverVertex` fires for a, b, c, d (4 times).
    /// - `examineEdge` fires for all 4 edges.
    /// - `treeEdge` fires for a→b and c→d (2 times).
    /// - `backEdge` fires for b→a (a is GRAY ancestor of b, cycle detected).
    /// - `forwardEdge` never fires — dead code in this implementation.
    /// - `crossEdge` fires for c→b (b is already BLACK when component 2 starts).
    /// - `finishVertex` fires for b, a, d, c (4 times).
    /// - `detectCycle` fires once after the full traversal (cycle from b→a).
    @Test func dfsComposedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        // Component 1: cycle a↔b so backEdge fires
        graph.addEdge(from: a, to: b) // tree edge
        graph.addEdge(from: b, to: a) // back edge (a is gray ancestor of b)
        // Component 2: c and d, with c→b pointing to already-BLACK b (crossEdge)
        graph.addEdge(from: c, to: b) // cross edge: b is BLACK when component 2 is visited
        graph.addEdge(from: c, to: d) // tree edge

        var discovered1 = 0; var discovered2 = 0
        var examEdge1 = 0;   var examEdge2 = 0
        var tree1 = 0;       var tree2 = 0
        var back1 = 0;       var back2 = 0
        var forward1 = 0;    var forward2 = 0
        var cross1 = 0;      var cross2 = 0
        var finished1 = 0;   var finished2 = 0
        var cycle1 = 0;      var cycle2 = 0

        var v1 = DFSTopologicalSort<DefaultAdjacencyList>.Visitor()
        v1.discoverVertex = { _ in discovered1 += 1 }
        v1.examineEdge    = { _ in examEdge1 += 1 }
        v1.treeEdge       = { _ in tree1 += 1 }
        v1.backEdge       = { _ in back1 += 1 }
        v1.forwardEdge    = { _ in forward1 += 1 }
        v1.crossEdge      = { _ in cross1 += 1 }
        v1.finishVertex   = { _ in finished1 += 1 }
        v1.detectCycle    = { _ in cycle1 += 1 }

        var v2 = DFSTopologicalSort<DefaultAdjacencyList>.Visitor()
        v2.discoverVertex = { _ in discovered2 += 1 }
        v2.examineEdge    = { _ in examEdge2 += 1 }
        v2.treeEdge       = { _ in tree2 += 1 }
        v2.backEdge       = { _ in back2 += 1 }
        v2.forwardEdge    = { _ in forward2 += 1 }
        v2.crossEdge      = { _ in cross2 += 1 }
        v2.finishVertex   = { _ in finished2 += 1 }
        v2.detectCycle    = { _ in cycle2 += 1 }

        let combined = v1.combined(with: v2)
        _ = graph.topologicalSort(using: .dfs().withVisitor(combined))

        #expect(discovered1 == 4,  "discoverVertex fires for a, b, c, d")
        #expect(discovered2 == 4)
        #expect(examEdge1 == 4,    "examineEdge fires for all 4 edges")
        #expect(examEdge2 == 4)
        #expect(tree1 == 2,        "treeEdge fires for a→b and c→d")
        #expect(tree2 == 2)
        #expect(back1 >= 1,        "backEdge fires for b→a (a is gray ancestor of b)")
        #expect(back2 >= 1)
        // DFSTopologicalSort does not distinguish forward vs cross edges — it maps ALL
        // BLACK-destination edges to crossEdge. The forwardEdge hook is defined but never
        // called by this implementation.
        #expect(forward1 == 0,     "forwardEdge is never fired by DFSTopologicalSort")
        #expect(forward2 == 0)
        #expect(cross1 >= 1,       "crossEdge fires for c→b (b is BLACK when c is processed)")
        #expect(cross2 >= 1)
        #expect(finished1 == 4,    "finishVertex fires for b, a, d, c")
        #expect(finished2 == 4)
        #expect(cycle1 == 1,       "detectCycle fires once after the traversal (cycle b→a)")
        #expect(cycle2 == 1)
        // Both composed visitors must see identical event counts
        #expect(discovered1 == discovered2)
        #expect(examEdge1 == examEdge2)
        #expect(tree1 == tree2)
        #expect(back1 == back2)
        #expect(forward1 == forward2)
        #expect(cross1 == cross2)
        #expect(finished1 == finished2)
        #expect(cycle1 == cycle2)
    }

    // MARK: - Multi-Backend Coverage

    @Test func kahnAndDFSProduceValidOrder_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            // DAG: a → b, a → c, b → d, c → d
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            let d = graph.addVertex { $0.label = "D" }
            graph.addEdge(from: a, to: b); graph.addEdge(from: a, to: c)
            graph.addEdge(from: b, to: d); graph.addEdge(from: c, to: d)

            let kahnResult = graph.topologicalSort(using: .kahn())
            let dfsResult  = graph.topologicalSort(using: .dfs())

            #expect(kahnResult.isValid, "[\(backend)] Kahn must produce a valid order")
            #expect(!kahnResult.hasCycle, "[\(backend)] Kahn must not report cycle in a DAG")
            #expect(kahnResult.sortedVertices.count == 4, "[\(backend)] Kahn must include all 4 vertices")

            #expect(dfsResult.isValid, "[\(backend)] DFS must produce a valid order")
            #expect(!dfsResult.hasCycle, "[\(backend)] DFS must not report cycle in a DAG")
            #expect(dfsResult.sortedVertices.count == 4, "[\(backend)] DFS must include all 4 vertices")

            // a must precede its direct successors in both orderings
            let ki = { (v: G.VertexDescriptor) in kahnResult.sortedVertices.firstIndex(of: v)! }
            let di = { (v: G.VertexDescriptor) in dfsResult.sortedVertices.firstIndex(of: v)! }
            #expect(ki(a) < ki(b) && ki(a) < ki(c), "[\(backend)] Kahn: a before its successors")
            #expect(ki(b) < ki(d) && ki(c) < ki(d), "[\(backend)] Kahn: b and c before d")
            #expect(di(a) < di(b) && di(a) < di(c), "[\(backend)] DFS: a before its successors")
            #expect(di(b) < di(d) && di(c) < di(d), "[\(backend)] DFS: b and c before d")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func cycleDetection_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            // Cycle: a → b → c → a
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b)
            graph.addEdge(from: b, to: c)
            graph.addEdge(from: c, to: a) // back edge creates cycle

            let kahnResult = graph.topologicalSort(using: .kahn())
            let dfsResult  = graph.topologicalSort(using: .dfs())

            #expect(kahnResult.hasCycle, "[\(backend)] Kahn must detect the cycle")
            #expect(!kahnResult.isValid, "[\(backend)] Kahn result must be invalid with a cycle")
            #expect(dfsResult.hasCycle,  "[\(backend)] DFS must detect the cycle")
            #expect(!dfsResult.isValid,  "[\(backend)] DFS result must be invalid with a cycle")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    // MARK: - Edge Cases

    /// A self-loop (a → a) creates a cycle, so topological sort must report `hasCycle`.
    ///
    /// A self-loop is definitionally a cycle of length 1. Neither Kahn nor DFS can produce
    /// a valid topological order when a self-loop is present.
    @Test func selfLoopCausesHasCycle() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: a)  // self-loop

        let kahnResult = graph.topologicalSort(using: .kahn())
        let dfsResult  = graph.topologicalSort(using: .dfs())

        #expect(kahnResult.hasCycle, "Kahn must detect the self-loop as a cycle")
        #expect(!kahnResult.isValid, "Kahn result must be invalid when a self-loop exists")
        #expect(dfsResult.hasCycle, "DFS must detect the self-loop as a cycle")
        #expect(!dfsResult.isValid, "DFS result must be invalid when a self-loop exists")
    }

    /// Topological sort on a DAG with parallel edges must still produce a valid ordering.
    ///
    /// Parallel edges don't create cycles — they just add redundant edges. Both Kahn
    /// and DFS must handle them without reporting false cycles or crashing.
    @Test func parallelEdgesInDAGProduceValidOrder() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: b)  // parallel edge
        graph.addEdge(from: b, to: c)

        let kahnResult = graph.topologicalSort(using: .kahn())
        let dfsResult  = graph.topologicalSort(using: .dfs())

        #expect(kahnResult.isValid, "Kahn must produce a valid sort for a DAG with parallel edges")
        #expect(!kahnResult.hasCycle)

        #expect(dfsResult.isValid, "DFS must produce a valid sort for a DAG with parallel edges")
        #expect(!dfsResult.hasCycle)

        // Both must contain all 3 vertices
        #expect(Set(kahnResult.sortedVertices) == Set([a, b, c]))
        #expect(Set(dfsResult.sortedVertices) == Set([a, b, c]))

        // a must come before b, and b before c
        let kahnIdx = { kahnResult.sortedVertices.firstIndex(of: $0)! }
        #expect(kahnIdx(a) < kahnIdx(b))
        #expect(kahnIdx(b) < kahnIdx(c))
    }

    // MARK: - Result API Coverage

    /// `topologicalSort()` no-argument convenience should use the default algorithm (DFS).
    @Test func noArgConvenienceUsesDefaultAlgorithm() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)

        let result = graph.topologicalSort()  // exercises the no-arg default
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices.count == 3)
        let aIdx = result.sortedVertices.firstIndex(of: a)!
        let bIdx = result.sortedVertices.firstIndex(of: b)!
        let cIdx = result.sortedVertices.firstIndex(of: c)!
        #expect(aIdx < bIdx && bIdx < cIdx)
    }

    /// `cycleVertices` is populated when a cycle is detected.
    @Test func cycleVerticesReportedOnCyclicGraph() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: a)  // back-edge

        let result = graph.topologicalSort(using: .dfs())
        #expect(result.hasCycle)
        #expect(!result.cycleVertices.isEmpty, "cycleVertices must be non-empty when a cycle is detected")
    }

    /// `TopologicalSortResult` is `Equatable` — two identical sorts on the same graph are equal.
    @Test func resultEquatableConformance() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)

        let r1 = graph.topologicalSort(using: .kahn())
        let r2 = graph.topologicalSort(using: .kahn())
        #expect(r1 == r2, "Two Kahn runs on the same graph must produce equal results")
    }

    /// `TopologicalSortResult` is `Hashable` — can be used as a dictionary key or in a `Set`.
    @Test func resultHashableConformance() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)

        let result = graph.topologicalSort(using: .kahn())
        var seen: Set<TopologicalSortResult<DefaultAdjacencyList.VertexDescriptor>> = []
        seen.insert(result)
        seen.insert(result)
        #expect(seen.count == 1, "Inserting the same result twice must yield a set of size 1")
    }
}
#endif
