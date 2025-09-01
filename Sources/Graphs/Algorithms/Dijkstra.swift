import Collections

enum DijkstrasAlgorithm {
    struct Visitor<Vertex, Edge> {
        var initializeVertex: ((Vertex) -> Void)?
        var examineVertex:    ((Vertex) -> Void)?
        var examineEdge:      ((Edge) -> Void)?
        var edgeRelaxed:      ((Edge) -> Void)?
        var edgeNotRelaxed:   ((Edge) -> Void)?
        var finishVertex:     ((Vertex) -> Void)?
    }

    enum Distance<Weight> {
        case infinite
        case finite(Weight)
    }

    struct Result<Vertex, Weight, Map: PropertyMap<Vertex, VertexPropertyValues>> {
        let source: Vertex
        let distanceProperty: any VertexProperty<Distance<Weight>>.Type
        let predecessorProperty: any VertexProperty<Vertex?>.Type
        let propertyMap: Map
    }

    private enum DistanceProperty<Weight>: VertexProperty {
        static var defaultValue: Distance<Weight> { .infinite }
    }

    private enum PredecessorProperty<Vertex>: VertexProperty {
        static var defaultValue: Vertex? { nil }
    }

    fileprivate struct VertexDistance<Vertex, Weight> {
        let vertex: Vertex
        let distance: Weight
    }

    static func run<
        Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph,
        Weight: Numeric
    >(
        on graph: Graph,
        from source: Graph.VertexDescriptor,
        edgeWeight: KeyPath<EdgePropertyValues, Weight>,
        visitor: Visitor<Graph.VertexDescriptor, Graph.EdgeDescriptor>? = nil
    ) -> Result<Graph.VertexDescriptor, Weight, some PropertyMap<Graph.VertexDescriptor, VertexPropertyValues>>
    where
        Weight.Magnitude == Weight,
        Graph.VertexDescriptor: Hashable
    {
        var visited: Set<Graph.VertexDescriptor> = []
        var queue = Heap<VertexDistance<Graph.VertexDescriptor, Distance<Weight>>>()

        let distanceProperty: any VertexProperty<Distance<Weight>>.Type = DistanceProperty.self
        let predecessorProperty: any VertexProperty<Graph.VertexDescriptor?>.Type = PredecessorProperty.self
        var propertyMap = graph.makeVertexPropertyMap()

        // Initialize all vertices
        for vertex in graph.vertices() {
            propertyMap[vertex][distanceProperty] = .infinite
            propertyMap[vertex][predecessorProperty] = nil
            visitor?.initializeVertex?(vertex)
        }
        
        // Set source distance to zero
        propertyMap[source][distanceProperty] = .finite(.zero)
        queue.insert(VertexDistance(vertex: source, distance: .finite(.zero)))
        
        while !queue.isEmpty {
            guard let currentVertexDistance = queue.popMin() else { break }
            let current = currentVertexDistance.vertex
            
            // Skip if we've already processed this vertex or if the distance in queue is outdated
            let currentDistance = propertyMap[current][distanceProperty]
            if visited.contains(current) || currentVertexDistance.distance > currentDistance {
                continue
            }
            
            // Mark vertex as visited
            visited.insert(current)

            visitor?.examineVertex?(current)

            // Examine all outgoing edges
            for edge in graph.outEdges(of: current) {
                visitor?.examineEdge?(edge)

                guard let destination = graph.destination(of: edge) else { continue }
                
                // Skip if destination is already visited
                if visited.contains(destination) {
                    continue
                }
                
                let edgeWeightValue = graph[edge][keyPath: edgeWeight]
                let newDistance = currentDistance + edgeWeightValue

                let destinationDistance = propertyMap[destination][distanceProperty]
                if newDistance < destinationDistance {
                    propertyMap[destination][distanceProperty] = newDistance
                    propertyMap[destination][predecessorProperty] = current
                    queue.insert(VertexDistance(vertex: destination, distance: newDistance))
                    visitor?.edgeRelaxed?(edge)
                } else {
                    visitor?.edgeNotRelaxed?(edge)
                }
            }
            
            visitor?.finishVertex?(current)
        }

        return Result(
            source: source,
            distanceProperty: distanceProperty,
            predecessorProperty: predecessorProperty,
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

    func predecessor(of vertex: Vertex) -> Vertex? {
        propertyMap[vertex][predecessorProperty]
    }

    func path(to destination: Vertex) -> some Sequence<Vertex> {
        var current = destination
        var result = [current]
        while let predecessor = predecessor(of: current) {
            result.insert(predecessor, at: 0)
            current = predecessor
        }
        return result
    }
}
