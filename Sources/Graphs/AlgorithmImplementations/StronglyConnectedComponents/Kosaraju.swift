import Collections

struct Kosaraju<Graph: BidirectionalGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    struct Visitor {
        var discoverVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var finishVertex: ((Vertex) -> Void)?
        var startComponent: ((Vertex) -> Void)?
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

    func stronglyConnectedComponents(visitor: Visitor?) -> [[Vertex]] {
        var propertyMap = graph.makeVertexPropertyMap()
        let colorProperty = ColorProperty.self

        // Step 1: Perform DFS on the original graph to get finish times
        var finishOrder: [Vertex] = []
        
        func dfs1(_ vertex: Vertex) {
            propertyMap[vertex][colorProperty] = .gray
            visitor?.discoverVertex?(vertex)

            for edge in graph.outgoingEdges(of: vertex) {
                visitor?.examineEdge?(edge)
                guard let destination = graph.destination(of: edge) else { continue }
                
                if propertyMap[destination][colorProperty] == .white {
                    dfs1(destination)
                }
            }

            propertyMap[vertex][colorProperty] = .black
            visitor?.finishVertex?(vertex)
            finishOrder.append(vertex)
        }

        // First pass: DFS on original graph
        for vertex in graph.vertices() {
            if propertyMap[vertex][colorProperty] == .white {
                dfs1(vertex)
            }
        }

        // Step 2: Reset colors and perform DFS on the transpose graph
        for vertex in graph.vertices() {
            propertyMap[vertex][colorProperty] = .white
        }

        var components: [[Vertex]] = []

        func dfs2(_ vertex: Vertex, component: inout [Vertex]) {
            propertyMap[vertex][colorProperty] = .gray
            visitor?.discoverVertex?(vertex)
            component.append(vertex)

            // For Kosaraju's algorithm, we need to traverse the transpose graph
            // We use incoming edges to simulate the transpose
            for edge in graph.incomingEdges(of: vertex) {
                visitor?.examineEdge?(edge)
                guard let source = graph.source(of: edge) else { continue }
                
                if propertyMap[source][colorProperty] == .white {
                    dfs2(source, component: &component)
                }
            }

            propertyMap[vertex][colorProperty] = .black
            visitor?.finishVertex?(vertex)
        }

        // Second pass: DFS on transpose graph in reverse finish order
        for vertex in finishOrder.reversed() {
            if propertyMap[vertex][colorProperty] == .white {
                var component: [Vertex] = []
                visitor?.startComponent?(vertex)
                dfs2(vertex, component: &component)
                visitor?.finishComponent?(component)
                components.append(component)
            }
        }

        return components
    }
}

