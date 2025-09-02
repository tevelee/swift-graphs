import Collections

enum BreadthFirstSearchAlgorithm {
    enum Distance {
        case unreachable
        case reachable(UInt)
    }
    struct Visitor<Vertex, Edge> {
        var initializeVertex: ((Vertex) -> Void)?
        var discoverVertex: ((Vertex) -> Void)?
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var treeEdge: ((Edge) -> Void)?
        var nonTreeEdge: ((Edge) -> Void)?
        var finishVertex: ((Vertex) -> Void)?

        var discoverVertexAndContinue: ((Vertex) -> Bool)?
        var examineVertexAndContinue: ((Vertex) -> Bool)?
        var examineEdgeAndContinue: ((Edge) -> Bool)?
        var treeEdgeAndContinue: ((Edge) -> Bool)?
        var nonTreeEdgeAndContinue: ((Edge) -> Bool)?
        var finishVertexAndContinue: ((Vertex) -> Bool)?
    }

    private enum Color {
        case white // Undiscovered
        case gray // Discovered but not fully processed
        case black // Fully processed
    }

    struct Result<Vertex, Edge, Map: PropertyMap<Vertex, VertexPropertyValues>> {
        fileprivate let source: Vertex
        let distanceProperty: any VertexProperty<Distance>.Type
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        let propertyMap: Map
    }

    private enum ColorProperty: VertexProperty {
        static var defaultValue: Color { .white }
    }

    private enum DistanceProperty: VertexProperty {
        static var defaultValue: Distance { .unreachable }
    }

    private enum PredecessorEdgeProperty<Edge>: VertexProperty {
        static var defaultValue: Edge? { nil }
    }

    @discardableResult
    static func run<Graph: IncidenceGraph & VertexListGraph>(
        on graph: Graph,
        from source: Graph.VertexDescriptor,
        makeQueue: () -> any QueueProtocol<Graph.VertexDescriptor> = { Deque() },
        visitor: Visitor<Graph.VertexDescriptor, Graph.EdgeDescriptor>? = nil
    ) -> Result<
        Graph.VertexDescriptor,
        Graph.EdgeDescriptor,
        some PropertyMap<Graph.VertexDescriptor, VertexPropertyValues>
    >
    where Graph.VertexDescriptor: Hashable {
        var queue = makeQueue()

        let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        let distanceProperty: any VertexProperty<Distance>.Type = DistanceProperty.self
        let predecessorEdgeProperty: any VertexProperty<Graph.EdgeDescriptor?>.Type = PredecessorEdgeProperty.self
        var propertyMap = graph.makeVertexPropertyMap()

        // Initialize all vertices
        for vertex in graph.vertices() {
            propertyMap[vertex][colorProperty] = .white
            propertyMap[vertex][distanceProperty] = .unreachable
            propertyMap[vertex][predecessorEdgeProperty] = nil
            visitor?.initializeVertex?(vertex)
        }
        
        // Set source as discovered
        propertyMap[source][colorProperty] = .gray
        propertyMap[source][distanceProperty] = .reachable(0)
        queue.enqueue(source)

        main: while !queue.isEmpty {
            guard let current = queue.dequeue() else { break }
            
            visitor?.examineVertex?(current)
            if visitor?.examineVertexAndContinue?(current) == false { break }

            // Examine all outgoing edges
            for edge in graph.outEdges(of: current) {
                visitor?.examineEdge?(edge)
                if visitor?.examineEdgeAndContinue?(edge) == false { break main }

                guard let destination = graph.destination(of: edge) else { continue }
                
                let destinationColor = propertyMap[destination][colorProperty]
                
                if destinationColor == .white {
                    // Tree edge - first time discovering this vertex
                    propertyMap[destination][colorProperty] = .gray
                    propertyMap[destination][distanceProperty] = propertyMap[current][distanceProperty] + 1
                    propertyMap[destination][predecessorEdgeProperty] = edge
                    visitor?.discoverVertex?(destination)
                    if visitor?.discoverVertexAndContinue?(destination) == false { break main }
                    queue.enqueue(destination)
                    visitor?.treeEdge?(edge)
                    if visitor?.treeEdgeAndContinue?(edge) == false { break main }
                } else {
                    // Non-tree edge
                    visitor?.nonTreeEdge?(edge)
                    if visitor?.nonTreeEdgeAndContinue?(edge) == false { break main }
                }
            }
            
            propertyMap[current][colorProperty] = .black
            visitor?.finishVertex?(current)
            if visitor?.finishVertexAndContinue?(current) == false { break }
        }

        return Result(
            source: source,
            distanceProperty: distanceProperty,
            predecessorEdgeProperty: predecessorEdgeProperty,
            propertyMap: propertyMap
        )
    }
}

extension BreadthFirstSearchAlgorithm.Result {
    func distance(of vertex: Vertex) -> BreadthFirstSearchAlgorithm.Distance {
        propertyMap[vertex][distanceProperty]
    }

    func predecessor(of vertex: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex? {
        predecessorEdge(of: vertex).flatMap(graph.source)
    }

    func predecessorEdge(of vertex: Vertex) -> Edge? {
        propertyMap[vertex][predecessorEdgeProperty]
    }

    func vertices(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
        [source] + path(to: destination, in: graph).map(\.vertex)
    }
    
    func edges(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
        path(to: destination, in: graph).map(\.edge)
    }

    func path(to destination: Vertex, in graph: some IncidenceGraph<Vertex, Edge>) -> [(vertex: Vertex, edge: Edge)] {
        var current = destination
        var result: [(Vertex, Edge)] = []
        while let predecessorEdge = predecessorEdge(of: current) {
            result.insert((current, predecessorEdge), at: 0)
            guard let predecessor = graph.source(of: predecessorEdge) else { break }
            current = predecessor
        }
        return result
    }
}

extension BreadthFirstSearchAlgorithm.Distance: Equatable {}

extension BreadthFirstSearchAlgorithm.Distance: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (_, .unreachable): true
        case (.unreachable, _): false
        case (.reachable(let lhsValue), .reachable(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension BreadthFirstSearchAlgorithm.Distance {
    static func + (lhs: Self, rhs: UInt) -> Self {
        switch lhs {
        case .unreachable: .unreachable
        case .reachable(let lhsValue): .reachable(lhsValue + rhs)
        }
    }
}

extension BreadthFirstSearchAlgorithm.Distance: ExpressibleByIntegerLiteral {
    init(integerLiteral value: UInt) {
        self = .reachable(value)
    }
}

extension BreadthFirstSearchAlgorithm.Distance: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self = .unreachable
    }
}
