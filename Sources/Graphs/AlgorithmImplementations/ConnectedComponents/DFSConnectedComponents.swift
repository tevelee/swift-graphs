import Collections

struct DFSConnectedComponents<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    struct Visitor {
        var discoverVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var finishComponent: (([Vertex]) -> Void)?
    }

    private enum Color {
        case white // Undiscovered
        case gray // Discovered but not fully processed
        case black // Fully processed
    }

    private enum ColorProperty: VertexProperty {
        static var defaultValue: Color { .white }
    }

    private let graph: Graph

    init(on graph: Graph) {
        self.graph = graph
    }

    func connectedComponents(visitor: Visitor?) -> [[Vertex]] {
        var propertyMap = graph.makeVertexPropertyMap()
        let colorProperty = ColorProperty.self
        var components: [[Vertex]] = []

        func dfs(_ vertex: Vertex, component: inout [Vertex]) {
            propertyMap[vertex][colorProperty] = .gray
            visitor?.discoverVertex?(vertex)
            component.append(vertex)

            for edge in graph.outgoingEdges(of: vertex) {
                visitor?.examineEdge?(edge)
                guard let destination = graph.destination(of: edge) else { continue }
                
                if propertyMap[destination][colorProperty] == .white {
                    dfs(destination, component: &component)
                }
            }

            propertyMap[vertex][colorProperty] = .black
        }

        // Process all vertices
        for vertex in graph.vertices() {
            if propertyMap[vertex][colorProperty] == .white {
                var component: [Vertex] = []
                dfs(vertex, component: &component)
                visitor?.finishComponent?(component)
                components.append(component)
            }
        }

        return components
    }
}

extension DFSConnectedComponents: ConnectedComponentsAlgorithm {
    func connectedComponents(
        in graph: Graph,
        visitor: Visitor?
    ) -> [[Graph.VertexDescriptor]] {
        connectedComponents(visitor: visitor)
    }
}
