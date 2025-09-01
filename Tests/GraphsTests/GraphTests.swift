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

        let result = DijkstrasAlgorithm.run(on: graph, from: a, edgeWeight: \.weight)
        #expect(result.distance(of: b) == 2.0)
        #expect(result.vertices(to: b, in: graph) == [a, b])
        #expect(graph.shortestPath(from: a, to: b, cost: \.weight, using: .dijkstra())?.vertices == [a, b])
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
