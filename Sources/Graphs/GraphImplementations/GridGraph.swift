import Collections

/// A grid graph implementation where vertices are arranged in a rectangular grid.
///
/// Grid graphs are useful for pathfinding in 2D environments like game maps,
/// image processing, or any scenario where movement is constrained to a grid.
/// Each vertex represents a grid cell, and edges connect adjacent cells.
public struct GridGraph: Graph {
    /// A vertex in the grid graph representing a grid cell.
    public struct Vertex: Hashable {
        /// The x-coordinate of the grid cell.
        public let x: Int
        
        /// The y-coordinate of the grid cell.
        public let y: Int
        
        /// Creates a new grid vertex.
        ///
        /// - Parameters:
        ///   - x: The x-coordinate
        ///   - y: The y-coordinate
        @inlinable
        public init(x: Int, y: Int) {
            self.x = x
            self.y = y
        }
    }

    /// An edge in the grid graph connecting two adjacent grid cells.
    public struct Edge: Hashable {
        /// The source vertex of the edge.
        public let source: Vertex
        
        /// The destination vertex of the edge.
        public let destination: Vertex
        
        /// Creates a new grid edge.
        ///
        /// - Parameters:
        ///   - source: The source vertex
        ///   - destination: The destination vertex
        @inlinable
        public init(source: Vertex, destination: Vertex) {
            self.source = source
            self.destination = destination
        }
    }

    public typealias VertexDescriptor = Vertex
    public typealias EdgeDescriptor = Edge

    /// The width of the grid (number of columns).
    public let width: Int
    
    /// The height of the grid (number of rows).
    public let height: Int
    
    /// The allowed movement directions in the grid.
    public let allowedDirections: OrderedSet<GridDirection>

    /// Creates a new grid graph.
    ///
    /// - Parameters:
    ///   - width: The width of the grid
    ///   - height: The height of the grid
    ///   - allowedDirections: The allowed movement directions (defaults to orthogonal)
    @inlinable
    public init(width: Int, height: Int, allowedDirections: OrderedSet<GridDirection> = .orthogonal) {
        self.width = width
        self.height = height
        self.allowedDirections = allowedDirections
    }
}

extension GridGraph: VertexListGraph {
    /// A collection of vertices in the grid graph.
    public struct Vertices: Sequence {
        @usableFromInline
        let width: Int
        @usableFromInline
        let height: Int
        
        @inlinable
        public init(width: Int, height: Int) {
            self.width = width
            self.height = height
        }
        
        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(width: width, height: height)
        }

        public struct Iterator: IteratorProtocol {
            @usableFromInline
            let width: Int
            @usableFromInline
            let height: Int
            @usableFromInline
            var currentX: Int = 0
            @usableFromInline
            var currentY: Int = 0
            
            @inlinable
            public init(width: Int, height: Int) {
                self.width = width
                self.height = height
            }
            
            @inlinable
            public mutating func next() -> GridGraph.Vertex? {
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

    @inlinable
    public func vertices() -> Vertices { .init(width: width, height: height) }
    
    @inlinable
    public var vertexCount: Int { width * height }
}

extension GridGraph: IncidenceGraph {
    /// A collection of outgoing edges from a vertex in the grid graph.
    public struct OutgoingEdges: Sequence {
        @usableFromInline
        let vertex: GridGraph.Vertex
        @usableFromInline
        let width: Int
        @usableFromInline
        let height: Int
        @usableFromInline
        let directions: OrderedSet<GridDirection>
        
        @inlinable
        public init(vertex: GridGraph.Vertex, width: Int, height: Int, directions: OrderedSet<GridDirection>) {
            self.vertex = vertex
            self.width = width
            self.height = height
            self.directions = directions
        }
        
        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(vertex: vertex, width: width, height: height, directions: directions)
        }

        public struct Iterator: IteratorProtocol {
            @usableFromInline
            let vertex: GridGraph.Vertex
            @usableFromInline
            let width: Int
            @usableFromInline
            let height: Int
            @usableFromInline
            let directions: OrderedSet<GridDirection>
            @usableFromInline
            var currentIndex: Int = 0
            
            @inlinable
            public init(vertex: GridGraph.Vertex, width: Int, height: Int, directions: OrderedSet<GridDirection>) {
                self.vertex = vertex
                self.width = width
                self.height = height
                self.directions = directions
            }
            
            @inlinable
            public mutating func next() -> GridGraph.Edge? {
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

    @inlinable
    public func outgoingEdges(of vertex: VertexDescriptor) -> OutgoingEdges {
        .init(vertex: vertex, width: width, height: height, directions: allowedDirections)
    }

    @inlinable
    public func source(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.source }
    
    @inlinable
    public func destination(of edge: EdgeDescriptor) -> VertexDescriptor? { edge.destination }
    
    @inlinable
    public func outDegree(of vertex: VertexDescriptor) -> Int {
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
    /// A collection of incoming edges to a vertex in the grid graph.
    public struct IncomingEdges: Sequence {
        @usableFromInline
        let vertex: GridGraph.Vertex
        @usableFromInline
        let width: Int
        @usableFromInline
        let height: Int
        @usableFromInline
        let directions: OrderedSet<GridDirection>
        
        @inlinable
        public init(vertex: GridGraph.Vertex, width: Int, height: Int, directions: OrderedSet<GridDirection>) {
            self.vertex = vertex
            self.width = width
            self.height = height
            self.directions = directions
        }
        
        @inlinable
        public func makeIterator() -> Iterator { Iterator(vertex: vertex, width: width, height: height, directions: directions) }

        public struct Iterator: IteratorProtocol {
            @usableFromInline
            let vertex: GridGraph.Vertex
            @usableFromInline
            let width: Int
            @usableFromInline
            let height: Int
            @usableFromInline
            let directions: OrderedSet<GridDirection>
            @usableFromInline
            var currentIndex: Int = 0
            
            @inlinable
            public init(vertex: GridGraph.Vertex, width: Int, height: Int, directions: OrderedSet<GridDirection>) {
                self.vertex = vertex
                self.width = width
                self.height = height
                self.directions = directions
            }
            
            @inlinable
            public mutating func next() -> GridGraph.Edge? {
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

    @inlinable
    public func incomingEdges(of vertex: VertexDescriptor) -> IncomingEdges {
        .init(vertex: vertex, width: width, height: height, directions: allowedDirections)
    }

    @inlinable
    public func inDegree(of vertex: VertexDescriptor) -> Int {
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
    /// A collection of all edges in the grid graph.
    public struct Edges: Sequence {
        @usableFromInline
        let width: Int
        @usableFromInline
        let height: Int
        @usableFromInline
        let directions: OrderedSet<GridDirection>
        
        @inlinable
        public init(width: Int, height: Int, directions: OrderedSet<GridDirection>) {
            self.width = width
            self.height = height
            self.directions = directions
        }
        
        @inlinable
        public func makeIterator() -> Iterator { Iterator(width: width, height: height, directions: directions) }

        public struct Iterator: IteratorProtocol {
            @usableFromInline
            let width: Int
            @usableFromInline
            let height: Int
            @usableFromInline
            let directions: OrderedSet<GridDirection>
            @usableFromInline
            var currentX: Int = 0
            @usableFromInline
            var currentY: Int = 0
            @usableFromInline
            var edgeIterator: GridGraph.OutgoingEdges.Iterator? = nil

            @inlinable
            public init(width: Int, height: Int, directions: OrderedSet<GridDirection>) {
                self.width = width
                self.height = height
                self.directions = directions
            }

            @inlinable
            public mutating func next() -> GridGraph.Edge? {
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

    @inlinable
    public func edges() -> Edges { .init(width: width, height: height, directions: allowedDirections) }

    @inlinable
    public var edgeCount: Int {
        var totalEdges = 0
        for vertex in vertices() {
            totalEdges += outDegree(of: vertex)
        }
        return totalEdges
    }
}

extension GridGraph: EdgeLookupGraph {
    @inlinable
    public func edge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
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

extension GridGraph {
    @inlinable
    public static func delta(for direction: GridDirection) -> (Int, Int) {
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

/// Represents the possible movement directions in a grid graph.
public enum GridDirection: CaseIterable, Hashable, Sendable {
    case up, right, down, left
    case upRight, downRight, downLeft, upLeft
}

extension OrderedSet<GridDirection> {
    /// Horizontal movement directions (left and right).
    public static let horizontal: Self = [.left, .right]
    
    /// Vertical movement directions (up and down).
    public static let vertical: Self = [.up, .down]
    
    /// Orthogonal movement directions (horizontal + vertical).
    public static let orthogonal: Self = horizontal + vertical
    
    /// Diagonal movement directions.
    public static let diagonal: Self = [.upRight, .downRight, .downLeft, .upLeft]
    
    /// All possible movement directions.
    public static let all: Self = orthogonal + diagonal

    static func + (lhs: Self, rhs: Self) -> Self {
        lhs.union(rhs)
    }

    static func - (lhs: Self, rhs: Self) -> Self {
        lhs.subtracting(rhs)
    }
}

