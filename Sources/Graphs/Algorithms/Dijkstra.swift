struct Dijkstra<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable,
    Weight.Magnitude == Weight
{
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    enum Cost {
        case infinite
        case finite(Weight)
    }

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
        let distanceProperty: any VertexProperty<Cost>.Type
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
    }

    private enum DistanceProperty: VertexProperty {
        static var defaultValue: Cost { .infinite }
    }

    private enum PredecessorEdgeProperty: VertexProperty {
        static var defaultValue: Edge? { nil }
    }

    struct PriorityItem {
        typealias Vertex = Graph.VertexDescriptor
        let vertex: Vertex
        let cost: Cost
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

    func makeIterator(visitor: Visitor) -> Iterator {
        _makeIterator(visitor: visitor)
    }

    private func _makeIterator(visitor: Visitor?) -> Iterator {
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

            propertyMap[source][distanceProperty] = .finite(.zero)
            self.queue.enqueue(.init(vertex: source, cost: .finite(.zero)))
        }

        mutating func next() -> Result? {
            // Find next valid vertex to process
            var current: Vertex?
            while let popped = queue.dequeue() {
                if visited.contains(popped.vertex) { continue }
                let stored = propertyMap[popped.vertex][distanceProperty]
                if popped.cost != stored { continue }
                current = popped.vertex
                break
            }

            guard let current else { return nil }

            visitor?.examineVertex?(current)

            let currentCost = propertyMap[current][distanceProperty]
            for edge in graph.outgoingEdges(of: current) {
                visitor?.examineEdge?(edge)

                guard let destination = graph.destination(of: edge) else { continue }
                if visited.contains(destination) { continue }

                let weight = edgeWeight.costToExplore(edge, graph)
                let newCost = currentCost + weight

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

            visited.insert(current)
            visitor?.finishVertex?(current)

            return Result(
                source: source,
                currentVertex: current,
                distanceProperty: distanceProperty,
                predecessorEdgeProperty: predecessorEdgeProperty,
                propertyMap: propertyMap
            )
        }
    }
}

extension Dijkstra.Iterator: IteratorProtocol {}

extension Dijkstra: Sequence {
    func makeIterator() -> Iterator {
        _makeIterator(visitor: nil)
    }
}

extension Dijkstra.Cost: Equatable where Weight: Equatable {}

extension Dijkstra.Cost: Comparable where Weight: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.infinite, _): false
            case (_, .infinite): true
            case (.finite(let lhsValue), .finite(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension Dijkstra.Cost where Weight: Numeric {
    static func + (lhs: Self, rhs: Weight) -> Self {
        switch lhs {
            case .infinite:
                assertionFailure(".infinite means unreachable, but if it's being examined it should be reachable")
                return .infinite
            case .finite(let lhsValue):
                return .finite(lhsValue + rhs)
        }
    }
}

extension Dijkstra.Cost: ExpressibleByIntegerLiteral where Weight == UInt {
    init(integerLiteral value: Weight) {
        self = .finite(value)
    }
}

extension Dijkstra.Cost: ExpressibleByFloatLiteral where Weight == Double {
    init(floatLiteral value: Weight) {
        self = .finite(value)
    }
}

extension Dijkstra.Cost: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self = .infinite
    }
}

extension Dijkstra.PriorityItem: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vertex == rhs.vertex
    }
}

extension Dijkstra.PriorityItem: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.cost < rhs.cost
    }
}

extension Dijkstra.Result {
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

    func distance(of vertex: Vertex) -> Dijkstra<Graph, Weight>.Cost {
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

    func hasPath(to vertex: Vertex) -> Bool {
        propertyMap[vertex][distanceProperty] != .infinite
    }
}

struct DijkstraWithVisitor<Graph: IncidenceGraph & EdgePropertyGraph, Weight: Numeric & Comparable>
where Graph.VertexDescriptor: Hashable, Weight.Magnitude == Weight {
    typealias Base = Dijkstra<Graph, Weight>
    let base: Base
    let makeVisitor: () -> Base.Visitor
}

extension DijkstraWithVisitor: Sequence {
    func makeIterator() -> Base.Iterator {
        base.makeIterator(visitor: makeVisitor())
    }
}

extension Dijkstra {
    func withVisitor(_ makeVisitor: @escaping () -> Visitor) -> DijkstraWithVisitor<Graph, Weight> {
        .init(base: self, makeVisitor: makeVisitor)
    }
}
