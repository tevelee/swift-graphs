#if !GRAPHS_USES_TRAITS || GRAPHS_ADVANCED
import Testing
@testable import Graphs

struct CliqueDetectionTests {
    
    // MARK: - Core Behavior
    
    @Test func emptyGraph() {
        let graph = AdjacencyList()
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 0)
        #expect(result.maximalCliqueSize == 0)
        #expect(result.cliques.isEmpty)
    }
    
    @Test func singleVertex() {
        var graph = AdjacencyList()
        let vertex = graph.addVertex { $0.label = "A" }
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 1)
        #expect(result.cliques == [[vertex]])
    }
    
    @Test func twoVerticesNoEdge() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 2)
        #expect(result.maximalCliqueSize == 1)
        #expect(result.cliques.contains { Set($0) == Set([a]) })
        #expect(result.cliques.contains { Set($0) == Set([b]) })
    }
    
    @Test func twoVerticesWithEdge() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 2)
        #expect(result.cliques.contains { Set($0) == Set([a, b]) })
    }
    
    // MARK: - Triangle Graph
    
    @Test func triangle() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        // Create triangle: A-B-C-A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 3)
        #expect(result.cliques.contains { Set($0) == Set([a, b, c]) })
    }
    
    // MARK: - Complete Graph
    
    @Test func completeK4() {
        var graph = AdjacencyList()
        let vertices = ["A", "B", "C", "D"].map { label in
            graph.addVertex { $0.label = label }
        }
        
        // Create complete graph K4
        for i in 0..<vertices.count {
            for j in 0..<vertices.count {
                if i != j {
                    graph.addEdge(from: vertices[i], to: vertices[j])
                }
            }
        }
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 4)
        #expect(result.cliques.contains { Set($0) == Set(vertices) })
    }
    
    @Test func completeK5() {
        var graph = AdjacencyList()
        let vertices = ["A", "B", "C", "D", "E"].map { label in
            graph.addVertex { $0.label = label }
        }
        
        // Create complete graph K5
        for i in 0..<vertices.count {
            for j in 0..<vertices.count {
                if i != j {
                    graph.addEdge(from: vertices[i], to: vertices[j])
                }
            }
        }
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 5)
        #expect(result.cliques.contains { Set($0) == Set(vertices) })
    }
    
    // MARK: - Complex Graph
    
    @Test func graphWithMultipleCliques() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        // Create two triangles connected by one edge
        // Triangle 1: A-B-C-A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        // Triangle 2: C-D-E-C
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: d)
        graph.addEdge(from: e, to: c)
        graph.addEdge(from: c, to: e)
        
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 2)
        #expect(result.maximalCliqueSize == 3)
        #expect(result.cliques.contains { Set($0) == Set([a, b, c]) })
        #expect(result.cliques.contains { Set($0) == Set([c, d, e]) })
    }
    
    // MARK: - Result Utilities
    
    @Test func cliquesOfSize() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create two triangles
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let result = graph.findCliques()
        
        let size3Cliques = result.cliques(ofSize: 3)
        #expect(size3Cliques.count == 1)
        #expect(size3Cliques.contains { Set($0) == Set([a, b, c]) })
        
        let size2Cliques = result.cliques(ofSize: 2)
        #expect(size2Cliques.count == 1)
        #expect(size2Cliques.contains { Set($0) == Set([c, d]) })
    }
    
    @Test func isClique() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        let result = graph.findCliques()
        
        #expect(result.isClique(Set([a, b, c])))
        #expect(!result.isClique(Set([a, b])))
        #expect(!result.isClique(Set([a, c])))
    }
    
    @Test func cliquesContaining() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        
        // Create two triangles sharing vertex C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        
        let result = graph.findCliques()
        
        let cliquesWithC = result.cliques(containing: c)
        #expect(cliquesWithC.count == 2)
        #expect(cliquesWithC.contains { Set($0) == Set([a, b, c]) })
        #expect(cliquesWithC.contains { Set($0) == Set([c, d]) })
    }
    
    // MARK: - Visitor Support
    
    @Test func visitorCallbacks() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)
        
        // Test basic functionality without visitor for now
        let result = graph.findCliques()
        
        #expect(result.cliqueCount == 1)
        #expect(result.maximalCliqueSize == 3)
        #expect(result.cliques.contains { Set($0) == Set([a, b, c]) })
    }
    
    // MARK: - Algorithm Comparison
    
    @Test func algorithmConsistency() {
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
        
        let result1 = graph.findCliques()
        let result2 = graph.findCliques(using: .bronKerbosch())

        #expect(result1.cliqueCount == result2.cliqueCount)
        #expect(result1.maximalCliqueSize == result2.maximalCliqueSize)
    }

    // MARK: - Visitor Support

    /// Exercises all four BronKerbosch visitor events through a composed visitor pair.
    ///
    /// Graph: undirected triangle A−B−C (6 bidirectional directed edges). This graph has exactly
    /// one maximal clique: {A, B, C}.
    /// - `foundClique` fires once when the single maximal clique is reported.
    /// - `exploreClique` fires when the algorithm enters a recursive call with a growing candidate set.
    /// - `choosePivot` fires at least once when the pivot is selected to prune the search.
    /// - `backtrack` fires when the algorithm removes a vertex from the current candidate clique.
    @Test func composedVisitorsReceiveAllEvents() {
        var graph = AdjacencyList()
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        // Undirected triangle: 6 directed edges
        graph.addEdge(from: a, to: b); graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c); graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a); graph.addEdge(from: a, to: c)

        var explore1 = 0;  var explore2 = 0
        var found1 = 0;    var found2 = 0
        var pivot1 = 0;    var pivot2 = 0
        var back1 = 0;     var back2 = 0

        var v1 = BronKerboschCliqueDetection<DefaultAdjacencyList>.Visitor()
        v1.exploreClique = { _ in explore1 += 1 }
        v1.foundClique   = { _ in found1 += 1 }
        v1.choosePivot   = { _ in pivot1 += 1 }
        v1.backtrack     = { _ in back1 += 1 }

        var v2 = BronKerboschCliqueDetection<DefaultAdjacencyList>.Visitor()
        v2.exploreClique = { _ in explore2 += 1 }
        v2.foundClique   = { _ in found2 += 1 }
        v2.choosePivot   = { _ in pivot2 += 1 }
        v2.backtrack     = { _ in back2 += 1 }

        let combined = v1.combined(with: v2)
        _ = BronKerboschCliqueDetection<DefaultAdjacencyList>(on: graph).findCliques(visitor: combined)

        #expect(found1 == 1,    "foundClique fires exactly once for the triangle {A,B,C}")
        #expect(found2 == 1)
        #expect(explore1 >= 1,  "exploreClique fires as the algorithm recurses into candidate sets")
        #expect(explore2 >= 1)
        #expect(pivot1 >= 1,    "choosePivot fires at least once per recursive call")
        #expect(pivot2 >= 1)
        #expect(back1 >= 1,     "backtrack fires when removing a vertex from the current clique")
        #expect(back2 >= 1)
        // Both composed visitors must see identical event counts
        #expect(found1 == found2)
        #expect(explore1 == explore2)
        #expect(pivot1 == pivot2)
        #expect(back1 == back2)
    }
}
#endif
