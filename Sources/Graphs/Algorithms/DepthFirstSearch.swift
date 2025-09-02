import Collections

enum DepthFirstSearchAlgorithm {
    enum Time {
        case undiscovered
        case discovered(UInt)
        case finished(UInt)
    }
    
    struct Visitor<Vertex, Edge> {
        var initializeVertex: ((Vertex) -> Void)?
        var discoverVertex: ((Vertex) -> Void)?
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var treeEdge: ((Edge) -> Void)?
        var backEdge: ((Edge) -> Void)?
        var forwardEdge: ((Edge) -> Void)?
        var crossEdge: ((Edge) -> Void)?
        var finishVertex: ((Vertex) -> Void)?

        var discoverVertexAndContinue: ((Vertex) -> Bool)?
        var examineVertexAndContinue: ((Vertex) -> Bool)?
        var examineEdgeAndContinue: ((Edge) -> Bool)?
        var treeEdgeAndContinue: ((Edge) -> Bool)?
        var backEdgeAndContinue: ((Edge) -> Bool)?
        var forwardEdgeAndContinue: ((Edge) -> Bool)?
        var crossEdgeAndContinue: ((Edge) -> Bool)?
        var finishVertexAndContinue: ((Vertex) -> Bool)?
    }

    private enum Color {
        case white // Undiscovered
        case gray // Discovered but not fully processed
        case black // Fully processed
    }

    struct Result<Vertex, Edge, Map: PropertyMap<Vertex, VertexPropertyValues>> {
        fileprivate let source: Vertex
        let discoveryTimeProperty: any VertexProperty<Time>.Type
        let finishTimeProperty: any VertexProperty<Time>.Type
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        let propertyMap: Map
    }

    private enum ColorProperty: VertexProperty {
        static var defaultValue: Color { .white }
    }

    private enum DiscoveryTimeProperty: VertexProperty {
        static var defaultValue: Time { .undiscovered }
    }

    private enum FinishTimeProperty: VertexProperty {
        static var defaultValue: Time { .undiscovered }
    }

    private enum PredecessorEdgeProperty<Edge>: VertexProperty {
        static var defaultValue: Edge? { nil }
    }

    @discardableResult
    static func run<Graph: IncidenceGraph & VertexListGraph>(
        on graph: Graph,
        from source: Graph.VertexDescriptor,
        visitor: Visitor<Graph.VertexDescriptor, Graph.EdgeDescriptor>? = nil
    ) -> Result<
        Graph.VertexDescriptor,
        Graph.EdgeDescriptor,
        some PropertyMap<Graph.VertexDescriptor, VertexPropertyValues>
    >
    where Graph.VertexDescriptor: Hashable {
        let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        let discoveryTimeProperty: any VertexProperty<Time>.Type = DiscoveryTimeProperty.self
        let finishTimeProperty: any VertexProperty<Time>.Type = FinishTimeProperty.self
        let predecessorEdgeProperty: any VertexProperty<Graph.EdgeDescriptor?>.Type = PredecessorEdgeProperty.self
        var propertyMap = graph.makeVertexPropertyMap()
        
        var time: UInt = 0

        // Initialize all vertices
        for vertex in graph.vertices() {
            propertyMap[vertex][colorProperty] = .white
            propertyMap[vertex][discoveryTimeProperty] = .undiscovered
            propertyMap[vertex][finishTimeProperty] = .undiscovered
            propertyMap[vertex][predecessorEdgeProperty] = nil
            visitor?.initializeVertex?(vertex)
        }

        func dfsVisit(_ vertex: Graph.VertexDescriptor) {
            time += 1
            propertyMap[vertex][colorProperty] = .gray
            propertyMap[vertex][discoveryTimeProperty] = .discovered(time)
            
            visitor?.discoverVertex?(vertex)
            if visitor?.discoverVertexAndContinue?(vertex) == false { return }
            
            visitor?.examineVertex?(vertex)
            if visitor?.examineVertexAndContinue?(vertex) == false { return }

            // Examine all outgoing edges
            for edge in graph.outEdges(of: vertex) {
                visitor?.examineEdge?(edge)
                if visitor?.examineEdgeAndContinue?(edge) == false { return }

                guard let destination = graph.destination(of: edge) else { continue }
                
                let destinationColor = propertyMap[destination][colorProperty]
                
                switch destinationColor {
                case .white:
                    // Tree edge - first time discovering this vertex
                    propertyMap[destination][predecessorEdgeProperty] = edge
                    visitor?.treeEdge?(edge)
                    if visitor?.treeEdgeAndContinue?(edge) == false { return }
                    dfsVisit(destination)
                case .gray:
                    // Back edge - creates a cycle
                    visitor?.backEdge?(edge)
                    if visitor?.backEdgeAndContinue?(edge) == false { return }
                case .black:
                    // Forward or cross edge
                    let sourceDiscoveryTime = propertyMap[vertex][discoveryTimeProperty]
                    let destinationDiscoveryTime = propertyMap[destination][discoveryTimeProperty]
                    
                    if case .discovered(let sourceTime) = sourceDiscoveryTime,
                       case .discovered(let destTime) = destinationDiscoveryTime,
                       sourceTime < destTime {
                        // Forward edge
                        visitor?.forwardEdge?(edge)
                        if visitor?.forwardEdgeAndContinue?(edge) == false { return }
                    } else {
                        // Cross edge
                        visitor?.crossEdge?(edge)
                        if visitor?.crossEdgeAndContinue?(edge) == false { return }
                    }
                }
            }
            
            time += 1
            propertyMap[vertex][colorProperty] = .black
            propertyMap[vertex][finishTimeProperty] = .finished(time)
            visitor?.finishVertex?(vertex)
            if visitor?.finishVertexAndContinue?(vertex) == false { return }
        }

        // Start DFS from source
        dfsVisit(source)

        return Result(
            source: source,
            discoveryTimeProperty: discoveryTimeProperty,
            finishTimeProperty: finishTimeProperty,
            predecessorEdgeProperty: predecessorEdgeProperty,
            propertyMap: propertyMap
        )
    }
}

extension DepthFirstSearchAlgorithm.Result {
    func discoveryTime(of vertex: Vertex) -> DepthFirstSearchAlgorithm.Time {
        propertyMap[vertex][discoveryTimeProperty]
    }
    
    func finishTime(of vertex: Vertex) -> DepthFirstSearchAlgorithm.Time {
        propertyMap[vertex][finishTimeProperty]
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

extension DepthFirstSearchAlgorithm.Time: Equatable {}

extension DepthFirstSearchAlgorithm.Time: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.undiscovered, _): true
        case (_, .undiscovered): false
        case (.discovered(let lhsValue), .discovered(let rhsValue)): lhsValue < rhsValue
        case (.finished(let lhsValue), .finished(let rhsValue)): lhsValue < rhsValue
        case (.discovered(let lhsValue), .finished(let rhsValue)): lhsValue < rhsValue
        case (.finished(let lhsValue), .discovered(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension DepthFirstSearchAlgorithm.Time: ExpressibleByIntegerLiteral {
    typealias IntegerLiteralType = UInt
    
    init(integerLiteral value: UInt) {
        self = .discovered(value)
    }
}
