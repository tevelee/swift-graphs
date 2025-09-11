struct AStar<
    Graph: IncidenceGraph & EdgePropertyGraph,
    Weight: Numeric & Comparable,
    HScore: Numeric,
    FScore: Comparable
> where
    Graph.VertexDescriptor: Hashable,
    HScore.Magnitude == HScore
{
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    enum GScore {
        case infinite
        case finite(Weight)
    }
    
    enum Cost {
        case infinite
        case finite(FScore)
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
        typealias GScore = AStar.GScore
        fileprivate let source: Vertex
        let currentVertex: Vertex
        let gScoreProperty: any VertexProperty<GScore>.Type
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
    }

    private enum GScoreProperty: VertexProperty {
        static var defaultValue: GScore { .infinite }
    }

    private enum PredecessorEdgeProperty: VertexProperty {
        static var defaultValue: Edge? { nil }
    }

    struct PriorityItem {
        typealias Vertex = Graph.VertexDescriptor
        let vertex: Vertex
        let totalCost: FScore
    }

    private let graph: Graph
    private let source: Vertex
    private let edgeWeight: CostDefinition<Graph, Weight>
    private let heuristic: Heuristic<Graph, HScore>
    private let calculateTotalCost: (GScore, HScore) -> FScore
    private let makePriorityQueue: () -> any QueueProtocol<PriorityItem>

    init(
        on graph: Graph,
        from source: Vertex,
        edgeWeight: CostDefinition<Graph, Weight>,
        heuristic: Heuristic<Graph, HScore>,
        calculateTotalCost: @escaping (Weight, HScore) -> FScore,
        makePriorityQueue: @escaping () -> any QueueProtocol<PriorityItem> = {
            PriorityQueue()
        }
    ) {
        self.graph = graph
        self.source = source
        self.edgeWeight = edgeWeight
        self.heuristic = heuristic
        self.calculateTotalCost = { gScore, hScore in
            switch gScore {
                case .infinite:
                    assertionFailure(".infinite means unreachable, but if it's being examined it should be reachable")
                    return calculateTotalCost(.zero, hScore)
                case .finite(let weight):
                    return calculateTotalCost(weight, hScore)
            }
        }
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
            calculateTotalCost: calculateTotalCost,
            visitor: visitor,
            queue: makePriorityQueue()
        )
    }

    struct Iterator {
        private let graph: Graph
        private let source: Vertex
        private let edgeWeight: CostDefinition<Graph, Weight>
        private let heuristic: Heuristic<Graph, HScore>
        private let calculateTotalCost: (GScore, HScore) -> FScore
        private let visitor: Visitor?
        private var queue: any QueueProtocol<PriorityItem>
        private var visited: Set<Vertex> = []

        private var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues>
        private let gScoreProperty: any VertexProperty<GScore>.Type = GScoreProperty.self
        private let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty.self

        init(
            graph: Graph,
            source: Vertex,
            edgeWeight: CostDefinition<Graph, Weight>,
            heuristic: Heuristic<Graph, HScore>,
            calculateTotalCost: @escaping (GScore, HScore) -> FScore,
            visitor: Visitor?,
            queue: any QueueProtocol<PriorityItem>
        ) {
            self.graph = graph
            self.source = source
            self.edgeWeight = edgeWeight
            self.heuristic = heuristic
            self.calculateTotalCost = calculateTotalCost
            self.visitor = visitor
            self.queue = queue
            self.propertyMap = graph.makeVertexPropertyMap()

            let gScore: GScore = .finite(.zero)
            propertyMap[source][gScoreProperty] = gScore
            let hScore: HScore = heuristic.estimatedCost(source, graph)
            let fScore: FScore = calculateTotalCost(gScore, hScore)
            self.queue.enqueue(.init(vertex: source, totalCost: fScore))
        }

        mutating func next() -> Result? {
            // Find next valid vertex to process
            var current: Vertex?
            while let popped = queue.dequeue() {
                if visited.contains(popped.vertex) { continue }
                let storedG = propertyMap[popped.vertex][gScoreProperty]
                // Recompute f from current best g to ensure consistency
                let currentF = calculateTotalCost(storedG, heuristic.estimatedCost(popped.vertex, graph))
                if popped.totalCost > currentF { continue }
                current = popped.vertex
                break
            }

            guard let current else { return nil }

            visitor?.examineVertex?(current)

            let currentG = propertyMap[current][gScoreProperty]
            for edge in graph.outgoingEdges(of: current) {
                visitor?.examineEdge?(edge)

                guard let neighbor = graph.destination(of: edge) else { continue }
                if visited.contains(neighbor) { continue }

                let weight = edgeWeight.costToExplore(edge, graph)
                let tentativeG = currentG + weight

                let neighborG = propertyMap[neighbor][gScoreProperty]
                if tentativeG < neighborG {
                    propertyMap[neighbor][gScoreProperty] = tentativeG
                    propertyMap[neighbor][predecessorEdgeProperty] = edge
                    let fScore = calculateTotalCost(tentativeG, heuristic.estimatedCost(neighbor, graph))
                    queue.enqueue(.init(vertex: neighbor, totalCost: fScore))
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

extension AStar.Iterator: IteratorProtocol {}

extension AStar: Sequence {
    func makeIterator() -> Iterator {
        _makeIterator(visitor: nil)
    }
}

struct AStarWithVisitor<Graph: IncidenceGraph & EdgePropertyGraph, Weight: Numeric & Comparable, HScore: Numeric, FScore: Comparable> where Graph.VertexDescriptor: Hashable, HScore.Magnitude == HScore {
    typealias Base = AStar<Graph, Weight, HScore, FScore>
    let base: Base
    let makeVisitor: () -> Base.Visitor
}

extension AStarWithVisitor: Sequence {
    func makeIterator() -> AStar<Graph, Weight, HScore, FScore>.Iterator {
        base.makeIterator(visitor: makeVisitor())
    }
}

extension AStar {
    func withVisitor(_ makeVisitor: @escaping () -> Visitor) -> AStarWithVisitor<Graph, Weight, HScore, FScore> {
        .init(base: self, makeVisitor: makeVisitor)
    }
}

extension AStar.Cost: Equatable where FScore: Equatable {}

extension AStar.Cost: Comparable where FScore: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.infinite, _): false
            case (_, .infinite): true
            case (.finite(let lhsValue), .finite(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension AStar.GScore: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
            case (.infinite, _): false
            case (_, .infinite): true
            case (.finite(let lhsValue), .finite(let rhsValue)): lhsValue < rhsValue
        }
    }
}

extension AStar.GScore {
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

extension AStar.Cost: ExpressibleByIntegerLiteral where FScore == UInt {
    init(integerLiteral value: FScore) {
        self = .finite(value)
    }
}

extension AStar.Cost: ExpressibleByFloatLiteral where FScore == Double {
    init(floatLiteral value: FScore) {
        self = .finite(value)
    }
}

extension AStar.Cost: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self = .infinite
    }
}

extension AStar.PriorityItem: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.vertex == rhs.vertex
    }
}

extension AStar.PriorityItem: Comparable {
    static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.totalCost < rhs.totalCost
    }
}

extension AStar.Result {
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

    func gScore(of vertex: Vertex) -> GScore {
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

struct Heuristic<Graph: Graphs.Graph, EstimatedCost> {
    let estimatedCost: (Graph.VertexDescriptor, Graph) -> EstimatedCost
}

extension Heuristic {
    static func uniform(_ value: EstimatedCost) -> Self {
        .init { _, _ in
            value
        }
    }
    
    static func distance(
        to destination: Graph.VertexDescriptor,
        using distance: DistanceAlgorithm<Graph.VertexDescriptor, EstimatedCost>
    ) -> Self {
        .init { vertex, _ in
            distance.calculateDistance(vertex, destination)
        }
    }
}

extension Heuristic where Graph: PropertyGraph {
    static func euclideanDistance<Coordinate: SIMD>(
        to destination: Graph.VertexDescriptor,
        of coordinates: @escaping (VertexProperties) -> Coordinate
    ) -> Self where EstimatedCost == Coordinate.Scalar, Coordinate.Scalar: FloatingPoint {
        .init { vertex, graph in
            DistanceAlgorithm.euclidean { coordinates(graph[$0]) }.calculateDistance(vertex, destination)
        }
    }
    
    static func manhattanDistance<Coordinate: SIMD>(
        to destination: Graph.VertexDescriptor,
        of coordinates: @escaping (VertexProperties) -> Coordinate
    ) -> Self where EstimatedCost == Coordinate.Scalar, Coordinate.Scalar: FloatingPoint {
        .init { vertex, graph in
            DistanceAlgorithm.manhattan { coordinates(graph[$0]) }.calculateDistance(vertex, destination)
        }
    }
}
