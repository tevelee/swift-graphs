#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
@testable import Graphs
import Testing

struct MinimumCutAlgorithmTests {

    // MARK: - Two Vertices

    @Test func testTwoVerticesSingleEdge() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }

        graph.addEdge(from: a, to: b) { $0.weight = 3.0 }
        graph.addEdge(from: b, to: a) { $0.weight = 3.0 }

        let result = graph.minimumCut(using: .stoerWagner(weight: .property(\.weight)))

        #expect(result != nil)
        #expect(result!.cutWeight == 6.0)
        #expect(result!.partitionA.count == 1)
        #expect(result!.partitionB.count == 1)
        #expect(result!.cutEdges.count == 2)
    }

    // MARK: - Triangle

    @Test func testTriangleWithDifferentWeights() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        // A --1-- B --2-- C --10-- A
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 2.0 }
        graph.addEdge(from: c, to: b) { $0.weight = 2.0 }
        graph.addEdge(from: a, to: c) { $0.weight = 10.0 }
        graph.addEdge(from: c, to: a) { $0.weight = 10.0 }

        let result = graph.minimumCut(using: .stoerWagner(weight: .property(\.weight)))

        #expect(result != nil)
        // Minimum cut isolates B: edges A-B (1+1) + B-C (2+2) = 6
        // vs isolating A: edges A-B (1+1) + A-C (10+10) = 22
        // vs isolating C: edges B-C (2+2) + A-C (10+10) = 24
        #expect(result!.cutWeight == 6.0)
    }

    // MARK: - Two Cliques Connected by Weak Edge

    @Test func testTwoCliquesConnectedByWeakEdge() {
        var graph = AdjacencyList()

        // Clique 1: A, B, C (all connected with weight 10)
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        // Clique 2: D, E, F (all connected with weight 10)
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        let f = graph.addVertex { $0.label = "F" }

        // Clique 1 edges (bidirectional)
        for (u, v) in [(a, b), (b, c), (a, c)] {
            graph.addEdge(from: u, to: v) { $0.weight = 10.0 }
            graph.addEdge(from: v, to: u) { $0.weight = 10.0 }
        }

        // Clique 2 edges (bidirectional)
        for (u, v) in [(d, e), (e, f), (d, f)] {
            graph.addEdge(from: u, to: v) { $0.weight = 10.0 }
            graph.addEdge(from: v, to: u) { $0.weight = 10.0 }
        }

        // Weak bridge: C -- D with weight 1
        graph.addEdge(from: c, to: d) { $0.weight = 1.0 }
        graph.addEdge(from: d, to: c) { $0.weight = 1.0 }

        let result = graph.minimumCut(using: .stoerWagner(weight: .property(\.weight)))

        #expect(result != nil)
        // The minimum cut should be the weak bridge (weight 1 + 1 = 2)
        #expect(result!.cutWeight == 2.0)
        #expect(result!.cutEdges.count == 2)

        // One partition should be {A, B, C} and the other {D, E, F}
        let clique1: Set = [a, b, c]
        let clique2: Set = [d, e, f]
        #expect(
            (result!.partitionA == clique1 && result!.partitionB == clique2)
                || (result!.partitionA == clique2 && result!.partitionB == clique1)
        )
    }

    // MARK: - Single Vertex

    @Test func testSingleVertex() {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "A" }

        let result = graph.minimumCut(using: .stoerWagner(weight: .property(\.weight)))

        #expect(result == nil)
    }

    // MARK: - Partition Correctness

    @Test func testPartitionCorrectness() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }

        // A --1-- B --1-- C --1-- D, A--10--D
        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
        graph.addEdge(from: c, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: c, to: d) { $0.weight = 1.0 }
        graph.addEdge(from: d, to: c) { $0.weight = 1.0 }
        graph.addEdge(from: a, to: d) { $0.weight = 10.0 }
        graph.addEdge(from: d, to: a) { $0.weight = 10.0 }

        let result = graph.minimumCut(using: .stoerWagner(weight: .property(\.weight)))

        #expect(result != nil)

        // Verify A ∪ B = all vertices
        let allVertices: Set = [a, b, c, d]
        #expect(result!.partitionA.union(result!.partitionB) == allVertices)

        // Verify A ∩ B = ∅
        #expect(result!.partitionA.intersection(result!.partitionB).isEmpty)

        // Verify both partitions are non-empty
        #expect(!result!.partitionA.isEmpty)
        #expect(!result!.partitionB.isEmpty)

        // Verify cut edges cross between partitions
        for edge in result!.cutEdges {
            let source = graph.source(of: edge)!
            let destination = graph.destination(of: edge)!
            let crossesPartition =
                (result!.partitionA.contains(source) && result!.partitionB.contains(destination))
                || (result!.partitionB.contains(source) && result!.partitionA.contains(destination))
            #expect(crossesPartition)
        }
    }

    // MARK: - Convenience API

    @Test func testConvenienceAPI() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }

        graph.addEdge(from: a, to: b) { $0.weight = 5.0 }
        graph.addEdge(from: b, to: a) { $0.weight = 5.0 }

        // Test the convenience method that defaults to Stoer-Wagner
        let result = graph.minimumCut(weight: .property(\.weight))

        #expect(result != nil)
        #expect(result!.cutWeight == 10.0)
    }

    // MARK: - isCutEdge

    @Test func testIsCutEdge() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: a) { $0.weight = 1.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
        graph.addEdge(from: c, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: a, to: c) { $0.weight = 100.0 }
        graph.addEdge(from: c, to: a) { $0.weight = 100.0 }

        let result = graph.minimumCut(using: .stoerWagner(weight: .property(\.weight)))

        #expect(result != nil)

        // The minimum cut isolates B (weight 4) rather than cutting the heavy edges
        #expect(result!.cutWeight == 4.0)

        // All cut edges should be reported as cut edges via isCutEdge
        for edge in result!.cutEdges {
            #expect(result!.isCutEdge(edge))
        }

        // Edges not in cutEdges should not be cut edges
        let allEdges = Array(graph.edges())
        let nonCutEdges = allEdges.filter { !result!.isCutEdge($0) }
        for edge in nonCutEdges {
            #expect(!result!.cutEdges.contains(edge))
        }
    }

    // MARK: - Path Graph

    @Test func testPathGraph() {
        var graph = AdjacencyList()

        // A --3-- B --1-- C --5-- D
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }

        graph.addEdge(from: a, to: b) { $0.weight = 3.0 }
        graph.addEdge(from: b, to: a) { $0.weight = 3.0 }
        graph.addEdge(from: b, to: c) { $0.weight = 1.0 }
        graph.addEdge(from: c, to: b) { $0.weight = 1.0 }
        graph.addEdge(from: c, to: d) { $0.weight = 5.0 }
        graph.addEdge(from: d, to: c) { $0.weight = 5.0 }

        let result = graph.minimumCut(using: .stoerWagner(weight: .property(\.weight)))

        #expect(result != nil)
        // The weakest link is B--C with weight 2 (1+1 bidirectional)
        #expect(result!.cutWeight == 2.0)
    }
}
#endif
