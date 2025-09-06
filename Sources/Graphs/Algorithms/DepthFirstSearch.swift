import Collections

struct DepthFirstSearchAlgorithm<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    typealias Edge = Graph.EdgeDescriptor

    enum Time {
        case undiscovered
        case discovered(UInt)
        case finished(UInt)
    }

    struct Visitor {
        var initializeVertex: ((Vertex) -> Void)?
        var discoverVertex: ((Vertex) -> Void)?
        var examineVertex: ((Vertex) -> Void)?
        var examineEdge: ((Edge) -> Void)?
        var treeEdge: ((Edge) -> Void)?
        var backEdge: ((Edge) -> Void)?
        var forwardEdge: ((Edge) -> Void)?
        var crossEdge: ((Edge) -> Void)?
        var finishVertex: ((Vertex) -> Void)?
    }

    private enum Color {
        case white // Undiscovered
        case gray // Discovered but not fully processed
        case black // Fully processed
    }

    struct Result {
        typealias Vertex = Graph.VertexDescriptor
        typealias Edge = Graph.EdgeDescriptor
        fileprivate let source: Vertex
        let currentVertex: Vertex
        let discoveryTimeProperty: any VertexProperty<Time>.Type
        let finishTimeProperty: any VertexProperty<Time>.Type
        let predecessorEdgeProperty: any VertexProperty<Edge?>.Type
        let propertyMap: any PropertyMap<Vertex, VertexPropertyValues>
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

    private enum PredecessorEdgeProperty: VertexProperty {
        static var defaultValue: Edge? { nil }
    }

    struct DFSFrame {
        let vertex: Vertex
        let isFirstVisit: Bool
    }

    private let graph: Graph
    private let source: Vertex
    private let makeStack: () -> any StackProtocol<DFSFrame>

    init(
        on graph: Graph,
        from source: Vertex,
        makeStack: @escaping () -> any StackProtocol<DFSFrame> = {
            Array()
        }
    ) {
        self.graph = graph
        self.source = source
        self.makeStack = makeStack
    }

    func makeIterator(visitor: Visitor) -> Iterator {
        _makeIterator(visitor: visitor)
    }

    private func _makeIterator(visitor: Visitor?) -> Iterator {
        Iterator(graph: graph, source: source, visitor: visitor, stack: makeStack())
    }

    struct Iterator {
        private let graph: Graph
        private let source: Vertex
        private let visitor: Visitor?
        private var stack: any StackProtocol<DFSFrame>
        private var time: UInt = 0

        private var propertyMap: any MutablePropertyMap<Vertex, VertexPropertyValues>
        private let colorProperty: any VertexProperty<Color>.Type = ColorProperty.self
        private let discoveryTimeProperty: any VertexProperty<Time>.Type = DiscoveryTimeProperty.self
        private let finishTimeProperty: any VertexProperty<Time>.Type = FinishTimeProperty.self
        private let predecessorEdgeProperty: any VertexProperty<Edge?>.Type = PredecessorEdgeProperty.self

        init(
            graph: Graph,
            source: Vertex,
            visitor: Visitor?,
            stack: any StackProtocol<DFSFrame>
        ) {
            self.graph = graph
            self.source = source
            self.visitor = visitor
            self.stack = stack
            self.propertyMap = graph.makeVertexPropertyMap()

            for vertex in graph.vertices() {
                propertyMap[vertex][colorProperty] = .white
                propertyMap[vertex][discoveryTimeProperty] = .undiscovered
                propertyMap[vertex][finishTimeProperty] = .undiscovered
                propertyMap[vertex][predecessorEdgeProperty] = nil
                visitor?.initializeVertex?(vertex)
            }

            self.stack.push(DFSFrame(vertex: source, isFirstVisit: true))
        }

        mutating func next() -> Result? {
            while !stack.isEmpty {
                guard let frame = stack.pop() else { break }
                let vertex = frame.vertex

                if frame.isFirstVisit {
                    time += 1
                    propertyMap[vertex][colorProperty] = .gray
                    propertyMap[vertex][discoveryTimeProperty] = .discovered(time)

                    visitor?.discoverVertex?(vertex)
                    visitor?.examineVertex?(vertex)

                    stack.push(DFSFrame(vertex: vertex, isFirstVisit: false))

                    let outEdges = Array(graph.outEdges(of: vertex))
                    for edge in outEdges.reversed() {
                        visitor?.examineEdge?(edge)

                        guard let destination = graph.destination(of: edge) else { continue }

                        let destinationColor = propertyMap[destination][colorProperty]

                        switch destinationColor {
                        case .white:
                            propertyMap[destination][predecessorEdgeProperty] = edge
                            visitor?.treeEdge?(edge)
                            stack.push(DFSFrame(vertex: destination, isFirstVisit: true))
                        case .gray:
                            visitor?.backEdge?(edge)
                        case .black:
                            let sourceDiscoveryTime = propertyMap[vertex][discoveryTimeProperty]
                            let destinationDiscoveryTime = propertyMap[destination][discoveryTimeProperty]

                            if case .discovered(let sourceTime) = sourceDiscoveryTime,
                               case .discovered(let destTime) = destinationDiscoveryTime,
                               sourceTime < destTime {
                                visitor?.forwardEdge?(edge)
                            } else {
                                visitor?.crossEdge?(edge)
                            }
                        }
                    }
                } else {
                    time += 1
                    propertyMap[vertex][colorProperty] = .black
                    propertyMap[vertex][finishTimeProperty] = .finished(time)
                    visitor?.finishVertex?(vertex)

                    return Result(
                        source: source,
                        currentVertex: vertex,
                        discoveryTimeProperty: discoveryTimeProperty,
                        finishTimeProperty: finishTimeProperty,
                        predecessorEdgeProperty: predecessorEdgeProperty,
                        propertyMap: propertyMap
                    )
                }
            }

            return nil
        }
    }
}

extension DepthFirstSearchAlgorithm.Iterator: IteratorProtocol {}

extension DepthFirstSearchAlgorithm: Sequence {
    func makeIterator() -> Iterator {
        _makeIterator(visitor: nil)
    }
}

extension DepthFirstSearchAlgorithm.Result {
    func discoveryTime(of vertex: Vertex) -> DepthFirstSearchAlgorithm<Graph>.Time {
        propertyMap[vertex][discoveryTimeProperty]
    }

    func finishTime(of vertex: Vertex) -> DepthFirstSearchAlgorithm<Graph>.Time {
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
        case (_, .undiscovered): false
        case (.undiscovered, _): true
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

extension DepthFirstSearchAlgorithm.Time: ExpressibleByNilLiteral {
    init(nilLiteral: ()) {
        self = .undiscovered
    }
}

struct DFSWithVisitor<Graph: IncidenceGraph & VertexListGraph> where Graph.VertexDescriptor: Hashable {
    typealias Base = DepthFirstSearchAlgorithm<Graph>
    let base: Base
    let makeVisitor: () -> Base.Visitor
}

extension DFSWithVisitor: Sequence {
    func makeIterator() -> Base.Iterator {
        base.makeIterator(visitor: makeVisitor())
    }
}

extension DepthFirstSearchAlgorithm {
    func withVisitor(_ makeVisitor: @escaping () -> Visitor) -> DFSWithVisitor<Graph> {
        .init(base: self, makeVisitor: makeVisitor)
    }
}
