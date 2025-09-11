import Collections
struct GridGraph: Graph {
    struct Vertex: Hashable {
        let x: Int
        let y: Int
    }

    struct Edge: Hashable {
        let source: Vertex
        let destination: Vertex
    }

    typealias VertexDescriptor = Vertex
    typealias EdgeDescriptor = Edge

    let width: Int
    let height: Int
    let allowedDirections: OrderedSet<GridDirection>

    init(width: Int, height: Int, allowedDirections: OrderedSet<GridDirection> = .orthogonal) {
        self.width = width
        self.height = height
        self.allowedDirections = allowedDirections
    }
}

extension GridGraph: VertexListGraph {
    struct Vertices: Sequence {
        let width: Int
        let height: Int
        func makeIterator() -> Iterator {
            Iterator(width: width, height: height)
        }

        struct Iterator: IteratorProtocol {
            let width: Int
            let height: Int
            var currentX: Int = 0
            var currentY: Int = 0
            
            mutating func next() -> GridGraph.Vertex? {
                guard currentY < height else { return nil }
                let vertex = GridGraph.Vertex(x: currentX, y: currentY)
                currentX += 1
                if currentX >= width { 
                    currentX = 0
                    currentY += 1 
                }
                return vertex
            }
        }
    }

    func vertices() -> Vertices { .init(width: width, height: height) }
    var vertexCount: Int { width * height }
}

extension GridGraph: IncidenceGraph {
    struct OutgoingEdges: Sequence {
        let vertex: GridGraph.Vertex
        let width: Int
        let height: Int
        let directions: OrderedSet<GridDirection>
        func makeIterator() -> Iterator {
            Iterator(vertex: vertex, width: width, height: height, directions: directions)
        }

        struct Iterator: IteratorProtocol {
            let vertex: GridGraph.Vertex
            let width: Int
            let height: Int
            let directions: OrderedSet<GridDirection>
            var currentIndex: Int = 0
            
            mutating func next() -> GridGraph.Edge? {
                while currentIndex < directions.count {
                    defer { currentIndex += 1 }
                    let direction = directions[directions.index(directions.startIndex, offsetBy: currentIndex)]
                    let (deltaX, deltaY) = GridGraph.delta(for: direction)
                    let nextX = vertex.x + deltaX
                    let nextY = vertex.y + deltaY
                    if nextX >= 0 && nextX < width && nextY >= 0 && nextY < height {
                        return GridGraph.Edge(source: vertex, destination: .init(x: nextX, y: nextY))
                    }
                }
                return nil
            }
        }
    }

    func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        .init(vertex: vertex, width: width, height: height, directions: allowedDirections)
    }

    func source(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.source }
    func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.destination }
    func outDegree(of vertex: VertexDescriptor) -> Int {
        var degree = 0
        for direction in allowedDirections {
            let (deltaX, deltaY) = GridGraph.delta(for: direction)
            let nextX = vertex.x + deltaX
            let nextY = vertex.y + deltaY
            if nextX >= 0 && nextX < width && nextY >= 0 && nextY < height { 
                degree += 1 
            }
        }
        return degree
    }
}

extension GridGraph: BidirectionalGraph {
    struct IncomingEdges: Sequence {
        let vertex: GridGraph.Vertex
        let width: Int
        let height: Int
        let directions: OrderedSet<GridDirection>
        func makeIterator() -> Iterator { Iterator(vertex: vertex, width: width, height: height, directions: directions) }

        struct Iterator: IteratorProtocol {
            let vertex: GridGraph.Vertex
            let width: Int
            let height: Int
            let directions: OrderedSet<GridDirection>
            var currentIndex: Int = 0
            
            mutating func next() -> GridGraph.Edge? {
                while currentIndex < directions.count {
                    defer { currentIndex += 1 }
                    let direction = directions[directions.index(directions.startIndex, offsetBy: currentIndex)]
                    let (deltaX, deltaY) = GridGraph.delta(for: direction)
                    let previousX = vertex.x - deltaX
                    let previousY = vertex.y - deltaY
                    if previousX >= 0 && previousX < width && previousY >= 0 && previousY < height {
                        return GridGraph.Edge(source: .init(x: previousX, y: previousY), destination: vertex)
                    }
                }
                return nil
            }
        }
    }

    func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges {
        .init(vertex: vertex, width: width, height: height, directions: allowedDirections)
    }

    func inDegree(of vertex: VertexDescriptor) -> Int {
        var degree = 0
        for direction in allowedDirections {
            let (deltaX, deltaY) = GridGraph.delta(for: direction)
            let previousX = vertex.x - deltaX
            let previousY = vertex.y - deltaY
            if previousX >= 0 && previousX < width && previousY >= 0 && previousY < height { 
                degree += 1 
            }
        }
        return degree
    }
}

extension GridGraph: EdgeListGraph {
    struct Edges: Sequence {
        let width: Int
        let height: Int
        let directions: OrderedSet<GridDirection>
        func makeIterator() -> Iterator { Iterator(width: width, height: height, directions: directions) }

        struct Iterator: IteratorProtocol {
            let width: Int
            let height: Int
            let directions: OrderedSet<GridDirection>
            var currentX: Int = 0
            var currentY: Int = 0
            var edgeIterator: GridGraph.OutgoingEdges.Iterator? = nil

            mutating func next() -> GridGraph.Edge? {
                while true {
                    if var iterator = edgeIterator {
                        if let edge = iterator.next() {
                            edgeIterator = iterator
                            return edge
                        } else {
                            edgeIterator = nil
                        }
                    }
                    guard currentY < height else { return nil }
                    let vertex = GridGraph.Vertex(x: currentX, y: currentY)
                    edgeIterator = GridGraph.OutgoingEdges(vertex: vertex, width: width, height: height, directions: directions).makeIterator()
                    currentX += 1
                    if currentX >= width { 
                        currentX = 0
                        currentY += 1 
                    }
                }
            }
        }
    }

    func edges() -> Edges { .init(width: width, height: height, directions: allowedDirections) }

    var edgeCount: Int {
        var totalEdges = 0
        for vertex in vertices() {
            totalEdges += outDegree(of: vertex)
        }
        return totalEdges
    }
}

extension GridGraph: EdgeLookupGraph {
    func edge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        let deltaX = destination.x - source.x
        let deltaY = destination.y - source.y
        var isAllowed = false
        for direction in allowedDirections {
            let (allowedDeltaX, allowedDeltaY) = GridGraph.delta(for: direction)
            if allowedDeltaX == deltaX && allowedDeltaY == deltaY { 
                isAllowed = true
                break 
            }
        }
        if !isAllowed { return nil }
        if destination.x < 0 || destination.x >= width { return nil }
        if destination.y < 0 || destination.y >= height { return nil }
        return Edge(source: source, destination: destination)
    }
}

private extension GridGraph {
    static func delta(for direction: GridDirection) -> (Int, Int) {
        switch direction {
        case .up: return (0, -1)
        case .right: return (1, 0)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        case .upRight: return (1, -1)
        case .downRight: return (1, 1)
        case .downLeft: return (-1, 1)
        case .upLeft: return (-1, -1)
        }
    }
}

enum GridDirection: CaseIterable, Hashable, Sendable {
    case up, right, down, left
    case upRight, downRight, downLeft, upLeft
}

extension OrderedSet<GridDirection> {
    static let horizontal: Self = [.left, .right]
    static let vertical: Self = [.up, .down]
    static let orthogonal: Self = horizontal + vertical
    static let diagonal: Self = [.upRight, .downRight, .downLeft, .upLeft]
    static let all: Self = orthogonal + diagonal

    static func + (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        lhs.subtracting(rhs)
    }
}

