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
    
    @Test func composedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: c)
        
        var discoveredVertices1: [String] = []
        var discoveredVertices2: [String] = []
        var finishedVertices1: [String] = []
        var finishedVertices2: [String] = []
        
        var visitor1 = Kahn<DefaultAdjacencyList>.Visitor()
        visitor1.discoverVertex = { vertex in
            discoveredVertices1.append(graph[vertex].label)
        }
        visitor1.finishVertex = { vertex in
            finishedVertices1.append(graph[vertex].label)
        }
        
        var visitor2 = Kahn<DefaultAdjacencyList>.Visitor()
        visitor2.discoverVertex = { vertex in
            discoveredVertices2.append(graph[vertex].label)
        }
        visitor2.finishVertex = { vertex in
            finishedVertices2.append(graph[vertex].label)
        }
        
        let combinedVisitor = visitor1.combined(with: visitor2)
        let result = graph.topologicalSort(using: .kahn().withVisitor(combinedVisitor))
        
        #expect(result.isValid)
        #expect(discoveredVertices1.count == 3)
        #expect(discoveredVertices2.count == 3)
        #expect(finishedVertices1.count == 3)
        #expect(finishedVertices2.count == 3)
        #expect(discoveredVertices1 == discoveredVertices2)
        #expect(finishedVertices1 == finishedVertices2)
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
}
#endif
