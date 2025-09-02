@testable import Graphs
import Testing

struct GraphTests {
    @Test func initial() {
        var graph = AdjacencyList()

        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let x = graph.addVertex()

        graph.addEdge(from: root, to: a)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: root, to: x)

        #expect(graph.vertices().count == 6)
        #expect(graph.edges().count == 5)
        #expect(graph.adjacentVertices(of: a) == [b, c, d, root])
        #expect(graph.outEdges(of: a).map(graph.destination) == [b, c, d])
        #expect(graph.inEdges(of: a).map(graph.source) == [root])
        #expect(graph.inEdges(of: root).isEmpty)
    }

    @Test func propertyMap() {
        var graph = AdjacencyList()

        let a = graph.addVertex {
            $0.weight = 2
        }
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b)
        graph[b].weight = 3

        enum Label: VertexProperty {
            static let defaultValue = ""
        }
        var map = graph.makeVertexPropertyMap()
        map[a][Label.self] = "a"

        #expect(Array(graph.vertices { $0.weight == 2 }) == [a])
    }

    @Test func dijkstra() {
        var graph = AdjacencyList()

        let a = graph.addVertex()
        let b = graph.addVertex()
        graph.addEdge(from: a, to: b) {
            $0.weight = 2
        }

        #expect(graph.shortestPath(from: a, to: b, using: .dijkstra(weight: \.weight))?.vertices == [a, b])

        let result = DijkstrasAlgorithm.run(on: graph, from: a, edgeWeight: \.weight)
        #expect(result.distance(of: b) == 2.0)
        #expect(result.vertices(to: b, in: graph) == [a, b])
    }

    @Test func bfs() {
        var graph = AdjacencyList()

        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()

        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: c)
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: c, to: d)

        let result = BreadthFirstSearchAlgorithm.run(on: graph, from: root)

        #expect(result.distance(of: root) == 0)
        #expect(result.distance(of: a) == 1)
        #expect(result.distance(of: c) == 1)
        #expect(result.distance(of: b) == 2)
        #expect(result.distance(of: d) == 2)

        #expect(result.vertices(to: a, in: graph) == [root, a])
        #expect(result.vertices(to: b, in: graph) == [root, a, b])
        #expect(result.vertices(to: c, in: graph) == [root, c])
        #expect(result.vertices(to: d, in: graph) == [root, c, d])
    }

    @Test func bfsTraversalOrder() {
        var graph = AdjacencyList()

        let root = graph.addVertex()
        let a = graph.addVertex()
        let b = graph.addVertex()
        let c = graph.addVertex()
        let d = graph.addVertex()
        let e = graph.addVertex()
        let f = graph.addVertex()
        let g = graph.addVertex()

        graph.addEdge(from: root, to: a)
        graph.addEdge(from: root, to: b)
        graph.addEdge(from: a, to: c)
        graph.addEdge(from: a, to: d)
        graph.addEdge(from: b, to: d)
        graph.addEdge(from: b, to: e)
        graph.addEdge(from: c, to: f)
        graph.addEdge(from: d, to: f)
        graph.addEdge(from: d, to: g)
        graph.addEdge(from: e, to: g)

        var discoveredVertices = graph.makeVertexCollection { Array() }
        var examinedVertices = graph.makeVertexCollection { Array() }

        BreadthFirstSearchAlgorithm.run(
            on: graph,
            from: root,
            visitor: .init(
                discoverVertex: { vertex in
                    discoveredVertices.append(vertex)
                },
                examineVertex: { vertex in
                    examinedVertices.append(vertex)
                }
            )
        )

        #expect(discoveredVertices == [a, b, c, d, e, f, g])
        #expect(examinedVertices == [root, a, b, c, d, e, f, g])
    }
}

private enum Weight: VertexProperty, EdgeProperty {
    static let defaultValue = 1.0
}

extension VertexPropertyValues {
    var weight: Double {
        get { self[Weight.self] }
        set { self[Weight.self] = newValue }
    }
}

extension EdgePropertyValues {
    var weight: Double {
        get { self[Weight.self] }
        set { self[Weight.self] = newValue }
    }
}
