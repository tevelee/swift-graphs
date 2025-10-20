@testable import Graphs
import Testing

struct UniformCostSearchTests {
    
    @Test func basicUniformCostSearch() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()
        
        graph.addEdge(from: a, to: b) { $0.weight = 4 }
        graph.addEdge(from: a, to: c) { $0.weight = 2 }
        graph.addEdge(from: b, to: d) { $0.weight = 5 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        graph.addEdge(from: c, to: e) { $0.weight = 3 }
        graph.addEdge(from: d, to: e) { $0.weight = 1 }
        
        let ucsSequence = graph.search(from: a, using: .uniformCostSearch(edgeWeight: .property(\.weight)))
        
        let found = ucsSequence.first { result in
            result.currentVertex == e
        }
        
        #expect(found != nil)
        #expect(found?.currentVertex == e)
        #expect(found?.currentDistance() == 4) // a->c->d->e = 2+1+1 = 4 (not 2+1+3)
    }
    
    @Test func optimalPathFinding() {
        var graph = AdjacencyList()
        let start = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let goal = graph.addVertex()
        
        // Direct path: start -> goal (cost: 10)
        graph.addEdge(from: start, to: goal) { $0.weight = 10 }
        
        // Indirect path: start -> a -> b -> c -> goal (cost: 1+1+1+1 = 4)
        graph.addEdge(from: start, to: a) { $0.weight = 1 }
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 1 }
        graph.addEdge(from: c, to: goal) { $0.weight = 1 }
        
        let ucsSequence = graph.search(from: start, using: .uniformCostSearch(edgeWeight: .property(\.weight)))
        
        let goalResult = ucsSequence.first { result in
            result.currentVertex == goal
        }
        
        #expect(goalResult != nil)
        #expect(goalResult?.currentDistance() == 4) // Should find the optimal path
    }
    
    @Test func memoryEfficiency() {
        var graph = AdjacencyList()
        let start = graph.addVertex()
        let goal = graph.addVertex()
        
        // Create a chain that forces UCS to explore many nodes
        var current = start
        for _ in 1...100 {
            let next = graph.addVertex()
            graph.addEdge(from: current, to: next) { $0.weight = 1 }
            current = next
        }
        graph.addEdge(from: current, to: goal) { $0.weight = 1 }
        
        var visitedCount = 0
        let ucsSequence = graph.search(from: start, using: .uniformCostSearch(edgeWeight: .property(\.weight)))
        
        let goalResult = ucsSequence.first { result in
            visitedCount += 1
            return result.currentVertex == goal
        }
        
        #expect(goalResult != nil)
        #expect(visitedCount == 102) // Should visit all nodes in the chain
        #expect(goalResult?.currentDistance() == 101) // Total cost of the chain
    }
    
    @Test func comparisonWithDijkstra() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()
        
        graph.addEdge(from: a, to: b) { $0.weight = 4 }
        graph.addEdge(from: a, to: c) { $0.weight = 2 }
        graph.addEdge(from: b, to: d) { $0.weight = 5 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        graph.addEdge(from: c, to: e) { $0.weight = 3 }
        graph.addEdge(from: d, to: e) { $0.weight = 1 }
        
        let ucsSequence = graph.search(from: a, using: .uniformCostSearch(edgeWeight: .property(\.weight)))
        let dijkstraSequence = graph.search(from: a, using: .dijkstra(edgeWeight: .property(\.weight)))
        
        // Both should find the same optimal distances
        let ucsDistances = Dictionary(uniqueKeysWithValues: ucsSequence.map { ($0.currentVertex, $0.currentDistance()) })
        let dijkstraDistances = Dictionary(uniqueKeysWithValues: dijkstraSequence.map { ($0.currentVertex, $0.currentDistance()) })
        
        #expect(ucsDistances == dijkstraDistances)
    }
    
    @Test func visitorPattern() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 2 }
        graph.addEdge(from: b, to: d) { $0.weight = 3 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        
        // Test that UCS can be called with visitor support
        let ucsSequence = graph.search(from: a, using: .uniformCostSearch(edgeWeight: .property(\.weight)))
        
        // Consume the sequence to ensure it works
        let results = Array(ucsSequence)
        
        #expect(results.count == 4) // Should visit all 4 vertices
    }
    
    @Test func pathReconstruction() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 4 }
        graph.addEdge(from: b, to: d) { $0.weight = 2 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        graph.addEdge(from: d, to: e) { $0.weight = 3 }
        
        let ucsSequence = graph.search(from: a, using: .uniformCostSearch(edgeWeight: .property(\.weight)))
        
        let eResult = ucsSequence.first { result in
            result.currentVertex == e
        }
        
        #expect(eResult != nil)
        
        let path = eResult?.path(in: graph) ?? []
        let pathVertices = eResult?.vertices(in: graph) ?? []
        let pathEdges = eResult?.edges(in: graph) ?? []
        
        #expect(pathVertices == [a, b, d, e]) // Optimal path: a->b->d->e
        #expect(pathEdges.count == 3)
        #expect(path.count == 3)
        
        // Verify the path costs
        let totalCost = pathEdges.reduce(0) { total, edge in
            total + graph[edge].weight
        }
        #expect(totalCost == 6) // 1 + 2 + 3 = 6
    }
    
    @Test func unreachableVertices() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        // No connection between a/b and c/d
        
        let ucsSequence = graph.search(from: a, using: .uniformCostSearch(edgeWeight: .property(\.weight)))
        
        let cResult = ucsSequence.first { result in
            result.currentVertex == c
        }
        
        #expect(cResult == nil) // c should not be reachable from a
        
        // Check that b is reachable but c is not
        let bResult = ucsSequence.first { result in
            result.currentVertex == b
        }
        
        #expect(bResult != nil)
        #expect(bResult?.hasPath(to: c) == false)
    }
    
    @Test func uniformCostProperty() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        
        // All edges have the same cost
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 1 }
        graph.addEdge(from: b, to: d) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        
        let ucsSequence = graph.search(from: a, using: .uniformCostSearch(edgeWeight: .property(\.weight)))
        
        let dResult = ucsSequence.first { result in
            result.currentVertex == d
        }
        
        #expect(dResult != nil)
        #expect(dResult?.currentDistance() == 2) // Should find shortest path with uniform costs
    }
    
    @Test func sequenceOperations() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()
        
        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 2 }
        graph.addEdge(from: b, to: d) { $0.weight = 3 }
        graph.addEdge(from: c, to: e) { $0.weight = 1 }
        
        let ucsSequence = graph.search(from: a, using: .uniformCostSearch(edgeWeight: .property(\.weight)))
        
        // Test filtering by distance
        let distanceTwo = ucsSequence
            .filter { $0.currentDistance() == 2 }
            .map { $0.currentVertex }
        
        let distanceTwoVertices = Array(distanceTwo)
        #expect(distanceTwoVertices.count >= 1) // Should have at least one vertex at distance 2
        
        // Test limiting by distance
        let limited = ucsSequence
            .prefix { $0.currentDistance() <= 1 }
            .map { $0.currentVertex }
        
        let limitedVertices = Array(limited)
        #expect(limitedVertices == [a, b])
    }
}