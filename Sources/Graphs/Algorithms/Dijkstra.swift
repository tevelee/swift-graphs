import Collections

enum DijkstrasAlgorithm<
    Graph: IncidenceGraph & EdgePropertyGraph & VertexListGraph,
    Weight: Numeric
>
where
    Weight.Magnitude == Weight,
    Graph.VertexDescriptor: Hashable
{

    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    struct Visitor {
        var initializeVertex: ((Vertex) -> Void)?
        var examineVertex:    ((Vertex) -> Void)?
        var examineEdge:      ((Edge) -> Void)?
        var edgeRelaxed:      ((Edge) -> Void)?
        var edgeNotRelaxed:   ((Edge) -> Void)?
        var finishVertex:     ((Vertex) -> Void)?
    }

    enum DijkstraWeight: Comparable {
        case infinite
        case finite(Weight)

        static func < (lhs: DijkstraWeight, rhs: DijkstraWeight) -> Bool {
            switch (lhs, rhs) {
            case (_, .infinite): true
            case (.infinite, _): false
            case (.finite(let lhsValue), .finite(let rhsValue)): lhsValue < rhsValue
            }
        }

        static func + (lhs: DijkstraWeight, rhs: Weight) -> DijkstraWeight {
            switch lhs {
            case .infinite: .infinite
            case .finite(let lhsValue): .finite(lhsValue + rhs)
            }
        }
    }

    private struct DistanceProperty: VertexProperty {
        static var defaultValue: DijkstraWeight { .infinite }
    }

    private struct PredecessorProperty: VertexProperty {
        static var defaultValue: Vertex? { nil }
    }

    struct DijkstraResult<Map: PropertyMap<Vertex, VertexPropertyValues>> {
        let distanceProperty: any VertexProperty<DijkstraWeight>.Type
        let predecessorProperty: any VertexProperty<Vertex?>.Type
        let propertyMap: Map

        func distance(of vertex: Vertex) -> DijkstraWeight {
            propertyMap[vertex][distanceProperty]
        }

        func predecessor(of vertex: Vertex) -> Vertex? {
            propertyMap[vertex][predecessorProperty]
        }
    }

    private struct VertexDistance: Comparable {
        let vertex: Vertex
        let distance: DijkstraWeight

        static func < (lhs: VertexDistance, rhs: VertexDistance) -> Bool {
            lhs.distance < rhs.distance
        }

        static func == (lhs: VertexDistance, rhs: VertexDistance) -> Bool {
            lhs.vertex == rhs.vertex
        }
    }

    static func run(
        on graph: Graph,
        from source: Graph.VertexDescriptor,
        edgeWeight: KeyPath<EdgePropertyValues, Weight>,
        visitor: Visitor? = nil
    ) -> DijkstraResult<some PropertyMap<Vertex, VertexPropertyValues>> {
        var visited: Set<Graph.VertexDescriptor> = []
        var queue = Heap<VertexDistance>()

        var propertyMap = graph.makeVertexPropertyMap()

        let distanceProperty: any VertexProperty<DijkstraWeight>.Type = DistanceProperty.self
        let predecessorProperty: any VertexProperty<Vertex?>.Type = PredecessorProperty.self

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
        
        return DijkstraResult(
            distanceProperty: distanceProperty,
            predecessorProperty: predecessorProperty,
            propertyMap: propertyMap
        )
    }
}
