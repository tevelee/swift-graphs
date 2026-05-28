#if !GRAPHS_USES_TRAITS || GRAPHS_PATHFINDING
@testable import Graphs
import Testing

#if canImport(simd)
import simd

struct AStarTests {

    // MARK: - Core Behavior

    @Test func findsShortestPathWithHeuristic() {
        var graph = AdjacencyList()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()

        graph.addEdge(from: a, to: b) { $0.weight = 1 }
        graph.addEdge(from: a, to: c) { $0.weight = 2 }
        graph.addEdge(from: c, to: d) { $0.weight = 1 }
        graph.addEdge(from: b, to: d) { $0.weight = 5 }

        let path = graph.shortestPath(
            from: a,
            to: d,
            using: .aStar(
                weight: .property(\.weight),
                heuristic: .euclideanDistance(of: \.coordinates)
            )
        )
        #expect(path?.vertices == [a, c, d])

        let res = AStar(
            on: graph,
            from: a,
            edgeWeight: .property(\.weight),
            heuristic: .uniform(0),
            calculateTotalCost: +
        ).first { $0.currentVertex == d }
        #expect(res?.vertices(to: d, in: graph) == [a, c, d])
    }

    // MARK: - Multi-Backend Coverage

    @Test func findsShortestPath_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let c = graph.addVertex { $0.label = "C" }
            graph.addEdge(from: a, to: b) { $0.weight = 1 }
            graph.addEdge(from: a, to: c) { $0.weight = 10 }
            graph.addEdge(from: b, to: c) { $0.weight = 1 }
            let path = graph.shortestPath(
                from: a,
                to: c,
                using: .aStar(weight: .property(\.weight), heuristic: .uniform(0))
            )
            #expect(path?.vertices.count == 3, "[\(backend)] expected 3-vertex path A→B→C")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func returnsNilForUnreachableVertex_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex { $0.label = "A" }
            let b = graph.addVertex { $0.label = "B" }
            let path = graph.shortestPath(
                from: a,
                to: b,
                using: .aStar(weight: .property(\.weight), heuristic: .uniform(0))
            )
            #expect(path == nil, "[\(backend)] expected nil for unreachable vertex")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }

    @Test func zeroHeuristicBehavesLikeDijkstra_allBackends() {
        func check<G: TestablePropertyGraph>(_ graph: inout G, _ backend: String)
        where G.VertexProperties == VertexPropertyValues, G.EdgeProperties == EdgePropertyValues,
              G.VertexDescriptor: Hashable {
            let a = graph.addVertex()
            let b = graph.addVertex()
            let c = graph.addVertex()
            graph.addEdge(from: a, to: b) { $0.weight = 2 }
            graph.addEdge(from: a, to: c) { $0.weight = 1 }
            graph.addEdge(from: c, to: b) { $0.weight = 0.5 }

            let astar = graph.shortestPath(
                from: a,
                to: b,
                using: .aStar(weight: .property(\.weight), heuristic: .uniform(0))
            )
            let dijkstra = graph.shortestPath(from: a, to: b, using: .dijkstra(weight: .property(\.weight)))
            #expect(astar?.vertices.count == dijkstra?.vertices.count, "[\(backend)] A* with zero heuristic should match Dijkstra path length")
        }
        var g1 = AdjacencyList();   check(&g1, "default")
        var g4 = AdjacencyMatrix(); check(&g4, "Matrix")
        #if !GRAPHS_USES_TRAITS || GRAPHS_SPECIALIZED_STORAGE
        var g2 = AdjacencyList(edgeStore: CSREdgeStorage().cacheInOutEdges()); check(&g2, "CSR")
        var g3 = AdjacencyList(edgeStore: COOEdgeStorage().cacheInOutEdges()); check(&g3, "COO")
        #endif
    }
}
#endif
#endif
