@testable import Graphs
import Testing

struct ArticulationPointsTests {

    @Test func linearChain() {
        // A - B - C (undirected, modeled as bidirectional edges)
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)

        let result = graph.articulationPoints()

        // B is a cut vertex
        #expect(result.cutVertices == [b])
        #expect(result.isArticulationPoint(b))
        #expect(!result.isArticulationPoint(a))
        #expect(!result.isArticulationPoint(c))

        // 2 bridge edges (one per undirected edge, tree edge direction only)
        #expect(result.bridges.count == 2)
    }

    @Test func cycle() {
        // A - B - C - A (triangle, no cut vertices, no bridges)
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

        let result = graph.articulationPoints()

        #expect(result.cutVertices.isEmpty)
        #expect(result.bridges.isEmpty)
    }

    @Test func diamond() {
        // A-B, A-C, B-D, C-D (diamond shape)
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: d, to: b)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)

        let result = graph.articulationPoints()

        #expect(result.cutVertices.isEmpty)
        #expect(result.bridges.isEmpty)
    }

    @Test func twoTrianglesConnectedByBridge() {
        // Triangle 1: A-B-C-A, Triangle 2: D-E-F-D, bridge: C-D
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        let f = graph.addVertex { $0.label = "F" }

        // Triangle 1: A-B-C-A
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: a)
        graph.addEdge(from: a, to: c)

        // Bridge: C-D
        let bridgeCD = graph.addEdge(from: c, to: d)!
        graph.addEdge(from: d, to: c)

        // Triangle 2: D-E-F-D
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: d)
        graph.addEdge(from: e, to: f)
        graph.addEdge(from: f, to: e)
        graph.addEdge(from: f, to: d)
        graph.addEdge(from: d, to: f)

        let result = graph.articulationPoints()

        // C and D are cut vertices (bridge endpoints)
        #expect(result.cutVertices.contains(c))
        #expect(result.cutVertices.contains(d))
        #expect(result.cutVertices.count == 2)

        // The bridge edge C->D (tree edge direction)
        #expect(result.bridges.count == 1)
        #expect(result.isBridge(bridgeCD))
    }

    @Test func singleVertex() {
        var graph = AdjacencyList()
        graph.addVertex { $0.label = "A" }

        let result = graph.articulationPoints()

        #expect(result.cutVertices.isEmpty)
        #expect(result.bridges.isEmpty)
    }

    @Test func twoVerticesOneEdge() {
        // A - B (single undirected edge)
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }

        let edgeAB = graph.addEdge(from: a, to: b)!
        graph.addEdge(from: b, to: a)

        let result = graph.articulationPoints()

        // No cut vertices (removing either leaves one isolated vertex, not a disconnection of multi-vertex components)
        #expect(result.cutVertices.isEmpty)

        // Tree edge direction is a bridge
        #expect(result.bridges.count == 1)
        #expect(result.isBridge(edgeAB))
    }

    @Test func disconnectedComponents() {
        // Component 1: A - B - C (chain)
        // Component 2: D - E (single edge)
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }

        // Component 1: A - B - C
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)

        // Component 2: D - E
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: d)

        let result = graph.articulationPoints()

        // B is a cut vertex in component 1
        #expect(result.cutVertices.contains(b))

        // 3 bridges (tree edges: A->B, B->C, D->E)
        #expect(result.bridges.count == 3)
    }

    @Test func starGraph() {
        // Hub connected to spokes: H-A, H-B, H-C, H-D
        var graph = AdjacencyList()

        let hub = graph.addVertex { $0.label = "H" }
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }

        graph.addEdge(from: hub, to: a)
        graph.addEdge(from: a, to: hub)
        graph.addEdge(from: hub, to: b)
        graph.addEdge(from: b, to: hub)
        graph.addEdge(from: hub, to: c)
        graph.addEdge(from: c, to: hub)
        graph.addEdge(from: hub, to: d)
        graph.addEdge(from: d, to: hub)

        let result = graph.articulationPoints()

        // Hub is the only cut vertex
        #expect(result.cutVertices == [hub])
        #expect(result.isArticulationPoint(hub))

        // 4 bridge edges (tree edges from hub to each spoke)
        #expect(result.bridges.count == 4)
    }

    @Test func defaultAlgorithmAPI() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)

        // Default API
        let result = graph.articulationPoints()
        #expect(result.cutVertices == [b])
    }

    @Test func explicitAlgorithmAPI() {
        var graph = AdjacencyList()

        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }

        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)

        // Explicit algorithm selection
        let result = graph.articulationPoints(using: .tarjan())
        #expect(result.cutVertices == [b])
    }
}
