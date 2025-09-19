import Collections

struct Tarjan<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    struct Visitor {
        var discoverVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var backEdge: ((Edge) -> Void)?
        var crossEdge: ((Edge) -> Void)?
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

    private enum IndexProperty: VertexProperty {
        static var defaultValue: UInt? { nil }
    }

    private enum LowLinkProperty: VertexProperty {
        static var defaultValue: UInt? { nil }
    }

    private enum OnStackProperty: VertexProperty {
        static var defaultValue: Bool { false }
    }

    private let graph: Graph

    init(on graph: Graph) {
        self.graph = graph
    }

    func stronglyConnectedComponents(visitor: Visitor?) -> [[Vertex]] {
        var propertyMap = graph.makeVertexPropertyMap()
        let colorProperty = ColorProperty.self
        let indexProperty = IndexProperty.self
        let lowLinkProperty = LowLinkProperty.self
        let onStackProperty = OnStackProperty.self

        var index: UInt = 0
        var stack: [Vertex] = []
        var components: [[Vertex]] = []

        func strongConnect(_ vertex: Vertex) {
            index += 1
            propertyMap[vertex][indexProperty] = index
            propertyMap[vertex][lowLinkProperty] = index
            propertyMap[vertex][colorProperty] = .gray
            propertyMap[vertex][onStackProperty] = true
            stack.append(vertex)

            visitor?.discoverVertex?(vertex)

            for edge in graph.outgoingEdges(of: vertex) {
                visitor?.examineEdge?(edge)

                guard let destination = graph.destination(of: edge) else { continue }

                let destinationColor = propertyMap[destination][colorProperty]

                switch destinationColor {
                case .white:
                    // Tree edge
                    strongConnect(destination)
                    let vertexLowLink = propertyMap[vertex][lowLinkProperty] ?? 0
                    let destinationLowLink = propertyMap[destination][lowLinkProperty] ?? 0
                    propertyMap[vertex][lowLinkProperty] = min(vertexLowLink, destinationLowLink)

                case .gray:
                    // Back edge
                    visitor?.backEdge?(edge)
                    if propertyMap[destination][onStackProperty] == true {
                        let vertexLowLink = propertyMap[vertex][lowLinkProperty] ?? 0
                        let destinationIndex = propertyMap[destination][indexProperty] ?? 0
                        propertyMap[vertex][lowLinkProperty] = min(vertexLowLink, destinationIndex)
                    }

                case .black:
                    // Cross edge
                    visitor?.crossEdge?(edge)
                }
            }

            propertyMap[vertex][colorProperty] = .black
            visitor?.finishVertex?(vertex)

            // If vertex is a root node, pop the stack and create an SCC
            let vertexIndex = propertyMap[vertex][indexProperty] ?? 0
            let vertexLowLink = propertyMap[vertex][lowLinkProperty] ?? 0

            if vertexIndex == vertexLowLink {
                var component: [Vertex] = []
                var w: Vertex
                repeat {
                    w = stack.removeLast()
                    propertyMap[w][onStackProperty] = false
                    component.append(w)
                } while w != vertex

                visitor?.startComponent?(vertex)
                visitor?.finishComponent?(component)
                components.append(component)
            }
        }

        // Process all vertices
        for vertex in graph.vertices() {
            if propertyMap[vertex][colorProperty] == .white {
                strongConnect(vertex)
            }
        }

        return components
    }
}

