import Graphs
import Testing

struct AdjacencyListInterfaceTests {
    private enum Name: VertexProperty {
        static let defaultValue = ""
    }

    @Test func adjacencyListIsAConcreteDefaultGraph() {
        var graph: AdjacencyList = .init()

        let source = graph.addVertex()
        let destination = graph.addVertex()
        let edge = graph.addEdge(from: source, to: destination)

        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
        #expect(edge.map(graph.destination) == destination)
    }

    @Test func storageBackedAdjacencyListAcceptsAStorageAdapter() {
        var graph = StorageBackedAdjacencyList(
            edgeStorage: OrderedEdgeStorage<OrderedVertexStorage.Vertex>()
        )

        let source = graph.addVertex()
        let destination = graph.addVertex()

        #expect(graph.addEdge(from: source, to: destination) != nil)
        #expect(graph.edgeCount == 1)
    }

    @Test func propertiesAreConfiguredThroughTheGraph() {
        var graph = AdjacencyList()

        let vertex = graph.addVertex { properties in
            properties[Name.self] = "source"
        }
        graph[vertex][Name.self] = "renamed"

        #expect(graph[vertex][Name.self] == "renamed")
    }

    @Test func lazyGraphMaterializesAsAnAdjacencyList() {
        let lazyGraph = LazyIncidenceGraph { (vertex: Int) in
            vertex == 0 ? [1] : []
        }

        let graph: AdjacencyList = lazyGraph.materialize(from: 0)

        #expect(graph.vertexCount == 2)
        #expect(graph.edgeCount == 1)
    }

    #if !GRAPHS_USES_TRAITS || GRAPHS_GENERATION
        @Test func randomGraphFactoriesReturnTheDefaultGraph() {
            let graph: AdjacencyList = .randomGraph(vertexCount: 4)

            #expect(graph.vertexCount == 4)
        }
    #endif

    #if !GRAPHS_USES_TRAITS || GRAPHS_BIPARTITE_GRAPH
        @Test func bipartiteAdjacencyListIsAConcreteDefaultGraph() {
            var graph = BipartiteAdjacencyList()
            let left = graph.addVertex(to: .left)
            let right = graph.addVertex(to: .right)

            #expect(graph.addEdge(from: left, to: right) != nil)
            #expect(graph.edgeCount == 1)
        }
    #endif
}
