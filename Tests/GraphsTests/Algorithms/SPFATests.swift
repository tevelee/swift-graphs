#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
@testable import Graphs
import Testing

struct SPFATests {

    // MARK: - Core Algorithm Tests

    @Test func basicShortestPath() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = 3 }

        let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

        #expect(result.distances[a] == .finite(0.0))
        #expect(result.distances[b] == .finite(2.0))
        #expect(result.distances[c] == .finite(5.0))
        #expect(result.hasNegativeCycle == false)
    }

    @Test func negativeWeightEdges() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = -1 }

        let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

        #expect(result.distances[c] == .finite(1.0)) // A -> B -> C (2 + (-1) = 1)
        #expect(result.hasNegativeCycle == false)
    }

    @Test func negativeCycleDetection() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 1 }
        graph.addEdge(from: c, to: a) { $0.weight = -3 } // Creates negative cycle

        let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

        #expect(result.hasNegativeCycle == true)
    }

    @Test func disconnectedGraph() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        // No edges between A and B

        let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

        #expect(result.distances[a] == .finite(0.0))
        #expect(result.distances[b] == .infinite)
        #expect(result.hasNegativeCycle == false)
    }

    @Test func singleVertex() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }

        let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

        #expect(result.distances[a] == .finite(0.0))
        #expect(result.hasNegativeCycle == false)
    }

    // MARK: - Path Reconstruction Tests

    @Test func pathReconstruction() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b) { $0.weight = 2 }
        graph.addEdge(from: b, to: c) { $0.weight = 3 }

        let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))
        let path = result.path(from: a, to: c, in: graph)

        #expect(path != nil)
        #expect(path?.source == a)
        #expect(path?.destination == c)
        #expect(path?.vertices.count == 3)
        #expect(path?.edges.count == 2)
    }

    @Test func pathReconstructionWithNegativeWeights() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = -2 }
        graph.addEdge(from: a, to: c) { $0.weight = 3 }

        let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))
        let path = result.path(from: a, to: c, in: graph)

        #expect(path != nil)
        #expect(path?.vertices.count == 3) // A -> B -> C is shorter than A -> C
    }

    @Test func pathReconstructionReturnsNilForNegativeCycle() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 1 }
        graph.addEdge(from: c, to: a) { $0.weight = -3 }

        let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))
        let path = result.path(from: a, to: c, in: graph)

        #expect(result.hasNegativeCycle == true)
        #expect(path == nil)
    }

    @Test func multiplePathsPicksOptimal() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }

        // Path 1: A -> B -> D (cost 10)
        graph.addEdge(from: a, to: b) { $0.weight = 3 }
        graph.addEdge(from: b, to: d) { $0.weight = 7 }

        // Path 2: A -> C -> D (cost 5)
        graph.addEdge(from: a, to: c) { $0.weight = 1 }
        graph.addEdge(from: c, to: d) { $0.weight = 4 }

        let result = graph.shortestPaths(from: a, using: .spfa(weight: .property(\.weight)))

        #expect(result.distances[d] == .finite(5.0)) // Picks the shorter A -> C -> D path
    }

    // MARK: - Visitor Tests

    @Test func visitorCallbacks() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }

        graph.addEdge(from: a, to: b) { $0.weight = 2 }

        var examinedVertices: [String] = []
        var relaxedEdgeCount = 0

        let spfa = SPFA(on: graph, edgeWeight: .property(\.weight))
        _ = spfa.shortestPathsFromSource(a, visitor: .init(
            examineVertex: { vertex in
                examinedVertices.append(graph[vertex].label)
            },
            edgeRelaxed: { _ in
                relaxedEdgeCount += 1
            }
        ))

        #expect(examinedVertices.contains("A"))
        #expect(examinedVertices.contains("B"))
        #expect(relaxedEdgeCount == 1)
    }

    @Test func negativeCycleVisitorCallback() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: b, to: c) { $0.weight = 1 }
        graph.addEdge(from: c, to: a) { $0.weight = -3 }

        var negativeCycleDetected = false

        let spfa = SPFA(on: graph, edgeWeight: .property(\.weight))
        let result = spfa.shortestPathsFromSource(a, visitor: .init(
            detectNegativeCycle: { _ in
                negativeCycleDetected = true
            }
        ))

        #expect(result.hasNegativeCycle == true)
        #expect(negativeCycleDetected == true)
    }
}
#endif
