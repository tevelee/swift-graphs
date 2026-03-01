#if !GRAPHS_USES_TRAITS || GRAPHS_CONNECTIVITY
@testable import Graphs
import Testing

struct TopologicalSortTests {
    
    // MARK: - Kahn's Algorithm Tests
    
    @Test func testKahnBasic() {
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
    
    @Test func testKahnComplexDAG() {
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
    
    @Test func testKahnWithCycle() {
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
    
    @Test func testKahnEmptyGraph() {
        let graph = AdjacencyList()
        
        let result = graph.topologicalSort(using: .kahn())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices.isEmpty)
    }
    
    @Test func testKahnSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let result = graph.topologicalSort(using: .kahn())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices == [a])
    }
    
    @Test func testKahnDisconnectedComponents() {
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
    
    // MARK: - DFS Topological Sort Tests
    
    @Test func testDFSBasic() {
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
    
    @Test func testDFSComplexDAG() {
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
    
    @Test func testDFSWithCycle() {
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
    
    @Test func testDFSEmptyGraph() {
        let graph = AdjacencyList()
        
        let result = graph.topologicalSort(using: .dfs())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices.isEmpty)
    }
    
    @Test func testDFSSingleVertex() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let result = graph.topologicalSort(using: .dfs())
        
        #expect(result.isValid)
        #expect(!result.hasCycle)
        #expect(result.sortedVertices == [a])
    }
    
    @Test func testDFSDisconnectedComponents() {
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
    
    // MARK: - Algorithm Comparison Tests
    
    @Test func testKahnVsDFS() {
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
    
    // MARK: - Graph Extension Tests
    
    @Test func testGraphExtensionKahn() {
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
    
    @Test func testGraphExtensionDFS() {
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
    
    // MARK: - Visitor Tests
    
    @Test func testKahnVisitor() {
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
    
    @Test func testDFSVisitor() {
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
    
    @Test func testCycleDetectionVisitor() {
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
    
    // MARK: - Visitor Composition Tests
    
    @Test func testVisitorComposition() {
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
}
#endif
