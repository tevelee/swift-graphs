struct UniformCostSearch<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    struct Visitor {
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var edgeRelaxed: ((Edge) -> Void)?
        var edgeNotRelaxed: ((Edge) -> Void)?
        var finishVertex: ((Vertex) -> Void)?
    }

    struct Result {
        typealias Vertex = Graph.VertexDescriptor
        typealias Edge = Graph.EdgeDescriptor
        fileprivate let source: Vertex
        let currentVertex: Vertex
        let distanceProperty: any VertexProperty<Cost<Weight>>.Type
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
    }

    private enum DistanceProperty: VertexProperty {
        static var defaultValue: Cost<Weight> { .infinite }
    }

    private enum PredecessorEdgeProperty: VertexProperty {
        static var defaultValue: Edge? { nil }
    }

    struct PriorityItem {
        typealias Vertex = Graph.VertexDescriptor
        let vertex: Vertex
        let cost: Cost<Weight>
    }

    private let graph: Graph
    private let source: Vertex
    private let edgeWeight: CostDefinition<Graph, Weight>
    private let makePriorityQueue: () -> any QueueProtocol<PriorityItem>

    init(
        on graph: Graph,
        from source: Vertex,
        edgeWeight: CostDefinition<Graph, Weight>,
        makePriorityQueue: @escaping () -> any QueueProtocol<PriorityItem> = {
            PriorityQueue()
        }
    ) {
        self.graph = graph
        self.source = source
        self.edgeWeight = edgeWeight
        self.makePriorityQueue = makePriorityQueue
    }

    func makeIterator(visitor: Visitor?) -> Iterator {
        Iterator(
            graph: graph,
            source: source,
            edgeWeight: edgeWeight,
            visitor: visitor,
            queue: makePriorityQueue()
        )
    }

    struct Iterator {
        private let graph: Graph
        private let source: Vertex
        private let edgeWeight: CostDefinition<Graph, Weight>
        private let visitor: Visitor?
        private var queue: any QueueProtocol<PriorityItem>
        private var visited: Set<Vertex> = []

        private var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues>
        private let distanceProperty: any VertexProperty<Cost>.Type = DistanceProperty.self
        private let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty.self

        init(
            graph: Graph,
            source: Vertex,
            edgeWeight: CostDefinition<Graph, Weight>,
            visitor: Visitor?,
            queue: any QueueProtocol<PriorityItem>
        ) {
            self.graph = graph
            self.source = source
            self.edgeWeight = edgeWeight
            self.visitor = visitor
            self.queue = queue
            self.propertyMap = graph.makeVertexPropertyMap()

            // UCS only initializes the source node, not all nodes
            propertyMap[source][distanceProperty] = .finite(.zero)
            self.queue.enqueue(.init(vertex: source, cost: .finite(.zero)))
        }

        mutating func next() -> Result? {
            var currentVertex: Vertex?
            while let popped = queue.dequeue() {
                if visited.contains(popped.vertex) { continue }
                let stored = propertyMap[popped.vertex][distanceProperty]
                if popped.cost != stored { continue }
                currentVertex = popped.vertex
                break
            }

            guard let currentVertex else { return nil }

            visitor?.examineVertex?(currentVertex)

            let currentCost = propertyMap[currentVertex][distanceProperty]
            for edge in graph.outgoingEdges(of: currentVertex) {
                visitor?.examineEdge?(edge)

                guard let destination = graph.destination(of: edge) else { continue }
                if visited.contains(destination) { continue }

                let weight = edgeWeight.costToExplore(edge, graph)
                let newCost = currentCost + weight

                // UCS: Only add to queue if we haven't seen this vertex before or found a better path
                let destinationCost = propertyMap[destination][distanceProperty]
                if newCost < destinationCost {
                    propertyMap[destination][distanceProperty] = newCost
                    propertyMap[destination][predecessorEdgeProperty] = edge
                    queue.enqueue(.init(vertex: destination, cost: newCost))
                    visitor?.edgeRelaxed?(edge)
                } else {
                    visitor?.edgeNotRelaxed?(edge)
                }
            }

            visited.insert(currentVertex)
            visitor?.finishVertex?(currentVertex)

            return Result(
                source: source,
                currentVertex: currentVertex,
                distanceProperty: distanceProperty,
                predecessorEdgeProperty: predecessorEdgeProperty,
                propertyMap: propertyMap
            )
        }
    }
    
}

extension UniformCostSearch.Iterator: IteratorProtocol {}

extension UniformCostSearch: Sequence {
    func makeIterator() -> Iterator {
        makeIterator(visitor: nil)
    }
}

extension UniformCostSearch.PriorityItem: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vertex == rhs.vertex
    }
}

extension UniformCostSearch.PriorityItem: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.cost < rhs.cost
    }
}

extension UniformCostSearch.Result {
    func currentDistance() -> Weight {
        switch distance(of: currentVertex) {
            case .finite(let value):
                return value
            case .infinite:
                assertionFailure("The currently examined vertex should always be reachable")
                return .zero
        }
    }

    func predecessor(in graph: some IncidenceGraph<Vertex, Edge>) -> Vertex {
        predecessor(of: currentVertex, in: graph).unwrap(
            orReport: "The currently examined vertex should always have a predecessor"
        )
    }

    func predecessorEdge() -> Edge {
        predecessorEdge(of: currentVertex).unwrap(
            orReport: "The currently examined vertex should always have a predecessor edge"
        )
    }

    func vertices(in graph: some IncidenceGraph<Vertex, Edge>) -> [Vertex] {
        vertices(to: currentVertex, in: graph)
    }

    func edges(in graph: some IncidenceGraph<Vertex, Edge>) -> [Edge] {
        edges(to: currentVertex, in: graph)
    }

    func path(in graph: some IncidenceGraph<Vertex, Edge>) -> [(vertex: Vertex, edge: Edge)] {
        path(to: currentVertex, in: graph)
    }

    func distance(of vertex: Vertex) -> Cost<Weight> {
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
        var currentVertex = destination
        var result: [(Vertex, Edge)] = []
        while let predecessorEdge = predecessorEdge(of: currentVertex) {
            result.insert((currentVertex, predecessorEdge), at: 0)
            guard let predecessor = graph.source(of: predecessorEdge) else { break }
            currentVertex = predecessor
        }
        return result
    }

    func hasPath(to vertex: Vertex) -> Bool {
        propertyMap[vertex][distanceProperty] != .infinite
    }
}

extension UniformCostSearch: VisitorSupportingSequence {}
