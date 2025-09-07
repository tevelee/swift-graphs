struct AStarAlgorithm<
    Graph: IncidenceGraph & VertexListGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable
> where
    Graph.VertexDescriptor: Hashable
{
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    enum Cost {
        case infinite
        case finite(Weight)
    }

    struct Visitor {
        var initializeVertex: ((Vertex) -> Void)?
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
        let gScoreProperty: any VertexProperty<Cost>.Type
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
    }

    private enum GScoreProperty: VertexProperty {
        static var defaultValue: Cost { .infinite }
    }

    private enum PredecessorEdgeProperty: VertexProperty {
        static var defaultValue: Edge? { nil }
    }

    struct PriorityItem {
        typealias Vertex = Graph.VertexDescriptor
        let vertex: Vertex
        let fScore: Cost
    }

    private let graph: Graph
    private let source: Vertex
    private let edgeWeight: CostAlgorithm<Graph, Weight>
    private let heuristic: Heuristic<Graph, Weight>
    private let makePriorityQueue: () -> any QueueProtocol<PriorityItem>

    init(
        on graph: Graph,
        from source: Vertex,
        edgeWeight: CostAlgorithm<Graph, Weight>,
        heuristic: Heuristic<Graph, Weight>,
        makePriorityQueue: @escaping () -> any QueueProtocol<PriorityItem> = {
            PriorityQueue()
        }
    ) {
        self.graph = graph
        self.source = source
        self.edgeWeight = edgeWeight
        self.heuristic = heuristic
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
            heuristic: heuristic,
            visitor: visitor,
            queue: makePriorityQueue()
        )
    }

    struct Iterator {
        private let graph: Graph
        private let source: Vertex
        private let edgeWeight: CostAlgorithm<Graph, Weight>
        private let heuristic: Heuristic<Graph, Weight>
        private let visitor: Visitor?
        private var queue: any QueueProtocol<PriorityItem>
        private var visited: Set<Vertex> = []

        private var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues>
        private let gScoreProperty: any VertexProperty<Cost>.Type = GScoreProperty.self
        private let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty.self

        init(
            graph: Graph,
            source: Vertex,
            edgeWeight: CostAlgorithm<Graph, Weight>,
            heuristic: Heuristic<Graph, Weight>,
            visitor: Visitor?,
            queue: any QueueProtocol<PriorityItem>
        ) {
            self.graph = graph
            self.source = source
            self.edgeWeight = edgeWeight
            self.heuristic = heuristic
            self.visitor = visitor
            self.queue = queue
            self.propertyMap = graph.makeVertexPropertyMap()

            for vertex in graph.vertices() {
                propertyMap[vertex][gScoreProperty] = .infinite
                propertyMap[vertex][predecessorEdgeProperty] = nil
                visitor?.initializeVertex?(vertex)
            }

            propertyMap[source][gScoreProperty] = .finite(.zero)
            let initialF: Cost = .finite(heuristic.evaluate(source, graph))
            self.queue.enqueue(.init(vertex: source, fScore: initialF))
        }

        mutating func next() -> Result? {
            // Find next valid vertex to process
            var current: Vertex?
            while let popped = queue.dequeue() {
                if visited.contains(popped.vertex) { continue }
                let storedG = propertyMap[popped.vertex][gScoreProperty]
                // Recompute f from current best g to ensure consistency
                let currentF = storedG + heuristic.evaluate(popped.vertex, graph)
                if popped.fScore > currentF { continue }
                current = popped.vertex
                break
            }

            guard let current else { return nil }

            visitor?.examineVertex?(current)

            let currentG = propertyMap[current][gScoreProperty]
            for edge in graph.outEdges(of: current) {
                visitor?.examineEdge?(edge)

                guard let neighbor = graph.destination(of: edge) else { continue }
                if visited.contains(neighbor) { continue }

                let weight = edgeWeight.costToExplore(edge, graph)
                let tentativeG = currentG + weight

                let neighborG = propertyMap[neighbor][gScoreProperty]
                if tentativeG < neighborG {
                    propertyMap[neighbor][gScoreProperty] = tentativeG
                    propertyMap[neighbor][predecessorEdgeProperty] = edge
                    let f = tentativeG + heuristic.evaluate(neighbor, graph)
                    queue.enqueue(.init(vertex: neighbor, fScore: f))
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
                gScoreProperty: gScoreProperty,
                predecessorEdgeProperty: predecessorEdgeProperty,
                propertyMap: propertyMap
            )
        }
    }
}

extension AStarAlgorithm.Iterator: IteratorProtocol {}

extension AStarAlgorithm: Sequence {
    func makeIterator() -> Iterator {
        _makeIterator(visitor: nil)
    }
}

extension AStarAlgorithm.Cost: Equatable where Weight: Equatable {}

extension AStarAlgorithm.Cost: Comparable where Weight: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.infinite, _): false
            case (_, .infinite): true
            case (.finite(let lhsValue), .finite(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension AStarAlgorithm.Cost {
    static func + (lhs: Self, rhs: Weight) -> Self {
        switch lhs {
            case .infinite: .infinite
            case .finite(let lhsValue): .finite(lhsValue + rhs)
        }
    }
}

extension AStarAlgorithm.Cost: ExpressibleByIntegerLiteral where Weight == UInt {
    init(integerLiteral value: Weight) {
        self = .finite(value)
    }
}

extension AStarAlgorithm.Cost: ExpressibleByFloatLiteral where Weight == Double {
    init(floatLiteral value: Weight) {
        self = .finite(value)
    }
}

extension AStarAlgorithm.Cost: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self = .infinite
    }
}

extension AStarAlgorithm.PriorityItem: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vertex == rhs.vertex
    }
}

extension AStarAlgorithm.PriorityItem: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.fScore < rhs.fScore
    }
}

extension AStarAlgorithm.Result {
    func currentDistance() -> Weight {
        switch gScore(of: currentVertex) {
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

    func gScore(of vertex: Vertex) -> AStarAlgorithm<Graph, Weight>.Cost {
        propertyMap[vertex][gScoreProperty]
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
        propertyMap[vertex][gScoreProperty] != .infinite
    }
}

struct Heuristic<Graph: Graphs.Graph, HScore> {
    let evaluate: (Graph.VertexDescriptor, Graph) -> HScore
}

extension Heuristic {
    static func constant(value: HScore = 0.0) -> Self {
        .init { _, _ in
            value
        }
    }
    
    static func distance(
        _ distance: DistanceAlgorithm<Graph.VertexDescriptor, HScore>,
        to destination: Graph.VertexDescriptor,
    ) -> Self {
        .init { vertex, _ in
            distance.calculateDistance(vertex, destination)
        }
    }
}
