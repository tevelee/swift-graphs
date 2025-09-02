enum DijkstrasAlgorithm {
    struct Visitor<Vertex, Edge> {
        var initializeVertex: ((Vertex) -> Void)?
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var edgeRelaxed: ((Edge) -> Void)?
        var edgeNotRelaxed: ((Edge) -> Void)?
        var finishVertex: ((Vertex) -> Void)?

        var examineVertexAndContinue: ((Vertex) -> Bool)?
        var examineEdgeAndContinue: ((Edge) -> Bool)?
        var edgeRelaxedAndContinue: ((Edge) -> Bool)?
        var edgeNotRelaxedAndContinue: ((Edge) -> Bool)?
        var finishVertexAndContinue: ((Vertex) -> Bool)?
    }

    enum Distance<Weight> {
        case infinite
        case finite(Weight)
    }

    struct Result<Vertex, Edge, Weight, Map: PropertyMap<Vertex, VertexPropertyValues>> {
        fileprivate let source: Vertex
        let distanceProperty: any VertexProperty<Distance<Weight>>.Type
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        let propertyMap: Map
    }

    private enum DistanceProperty<Weight>: VertexProperty {
        static var defaultValue: Distance<Weight> { .infinite }
    }

    private enum PredecessorEdgeProperty<Edge>: VertexProperty {
        static var defaultValue: Edge? { nil }
    }

    struct VertexDistance<Vertex, Weight> {
        let vertex: Vertex
        let distance: Weight
    }

    @discardableResult
    static func run<
        Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph,
        Weight: Numeric
    >(
        on graph: Graph,
        from source: Graph.VertexDescriptor,
        edgeWeight: (EdgePropertyValues) -> Weight,
        makeQueue: () -> any QueueProtocol<VertexDistance<Graph.VertexDescriptor, Distance<Weight>>> = { PriorityQueue() },
        visitor: Visitor<Graph.VertexDescriptor, Graph.EdgeDescriptor>? = nil
    ) -> Result<
        Graph.VertexDescriptor,
        Graph.EdgeDescriptor,
        Weight,
        some PropertyMap<Graph.VertexDescriptor, VertexPropertyValues>
    >
    where
        Weight.Magnitude == Weight,
        Graph.VertexDescriptor: Hashable
    {
        var visited: Set<Graph.VertexDescriptor> = []
        var queue = makeQueue()

        let distanceProperty: any VertexProperty<Distance<Weight>>.Type = DistanceProperty.self
        let predecessorEdgeProperty: any VertexProperty<Graph.EdgeDescriptor?>.Type = PredecessorEdgeProperty.self
        var propertyMap = graph.makeVertexPropertyMap()

        // Initialize all vertices
        for vertex in graph.vertices() {
            propertyMap[vertex][distanceProperty] = .infinite
            propertyMap[vertex][predecessorEdgeProperty] = nil
            visitor?.initializeVertex?(vertex)
        }
        
        // Set source distance to zero
        propertyMap[source][distanceProperty] = .finite(.zero)
        queue.enqueue(VertexDistance(vertex: source, distance: .finite(.zero)))

        main: while !queue.isEmpty {
            guard let currentVertexDistance = queue.dequeue() else { break }
            let current = currentVertexDistance.vertex
            
            // Skip if we've already processed this vertex or if the distance in queue is outdated
            let currentDistance = propertyMap[current][distanceProperty]
            if visited.contains(current) || currentVertexDistance.distance > currentDistance {
                continue
            }
            
            // Mark vertex as visited
            visited.insert(current)

            visitor?.examineVertex?(current)
            if visitor?.examineVertexAndContinue?(current) == false { break }

            // Examine all outgoing edges
            for edge in graph.outEdges(of: current) {
                visitor?.examineEdge?(edge)
                if visitor?.examineEdgeAndContinue?(edge) == false { break main }

                guard let destination = graph.destination(of: edge) else { continue }
                
                // Skip if destination is already visited
                if visited.contains(destination) {
                    continue
                }
                
                let edgeWeightValue = edgeWeight(graph[edge])
                let newDistance = currentDistance + edgeWeightValue

                let destinationDistance = propertyMap[destination][distanceProperty]
                if newDistance < destinationDistance {
                    propertyMap[destination][distanceProperty] = newDistance
                    propertyMap[destination][predecessorEdgeProperty] = edge
                    queue.enqueue(VertexDistance(vertex: destination, distance: newDistance))
                    visitor?.edgeRelaxed?(edge)
                    if visitor?.edgeRelaxedAndContinue?(edge) == false { break main }
                } else {
                    visitor?.edgeNotRelaxed?(edge)
                    if visitor?.edgeNotRelaxedAndContinue?(edge) == false { break main }
                }
            }
            
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

extension DijkstrasAlgorithm.Distance: Equatable where Weight: Equatable {}

extension DijkstrasAlgorithm.Distance: Comparable where Weight: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (_, .infinite): true
        case (.infinite, _): false
        case (.finite(let lhsValue), .finite(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension DijkstrasAlgorithm.Distance where Weight: Numeric {
    static func + (lhs: Self, rhs: Weight) -> Self {
        switch lhs {
        case .infinite: .infinite
        case .finite(let lhsValue): .finite(lhsValue + rhs)
        }
    }
}

extension DijkstrasAlgorithm.Distance: ExpressibleByIntegerLiteral where Weight == Int {
    init(integerLiteral value: Weight) {
        self = .finite(value)
    }
}

extension DijkstrasAlgorithm.Distance: ExpressibleByFloatLiteral where Weight == Double {
    init(floatLiteral value: Weight) {
        self = .finite(value)
    }
}

extension DijkstrasAlgorithm.Distance: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self = .infinite
    }
}

extension DijkstrasAlgorithm.VertexDistance: Equatable where Vertex: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vertex == rhs.vertex
    }
}

extension DijkstrasAlgorithm.VertexDistance: Comparable where Weight: Comparable, Vertex: Equatable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.distance < rhs.distance
    }
}

extension DijkstrasAlgorithm.Result {
    func distance(of vertex: Vertex) -> DijkstrasAlgorithm.Distance<Weight> {
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
