/// Union-Find-based algorithm for checking if a graph is cyclic.
public struct UnionFindCyclicPropertyAlgorithm<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Visitor = UnionFindCyclicProperty<Graph>.Visitor
    
    /// Creates a new Union-Find-based cyclic property algorithm.
    @inlinable
    public init() {}
    
    /// Checks if the graph is cyclic using Union-Find.
    ///
    /// - Parameters:
    ///   - graph: The graph to check
    ///   - visitor: An optional visitor to observe the algorithm progress
    /// - Returns: `true` if the graph is cyclic, `false` otherwise
    @inlinable
    public func isCyclic(
        in graph: Graph,
        visitor: Visitor?
    ) -> Bool {
        // Handle empty graphs and single vertex graphs
        guard graph.vertexCount > 1 else {
            return false
        }
        
        // Union-Find only works for undirected graphs
        // For directed graphs, we need to convert to undirected first
        // by treating each directed edge as an undirected edge
        
        var parent = [Graph.VertexDescriptor: Graph.VertexDescriptor]()
        var rank = [Graph.VertexDescriptor: Int]()
        
        // Initialize each vertex as its own parent
        for vertex in graph.vertices() {
            parent[vertex] = vertex
            rank[vertex] = 0
        }
        
        // Find root with path compression
        func findRoot(_ vertex: Graph.VertexDescriptor) -> Graph.VertexDescriptor {
            if parent[vertex] != vertex {
                parent[vertex] = findRoot(parent[vertex]!)
            }
            return parent[vertex]!
        }
        
        // Union two sets by rank
        func union(_ x: Graph.VertexDescriptor, _ y: Graph.VertexDescriptor) {
            let rootX = findRoot(x)
            let rootY = findRoot(y)
            
            if rootX == rootY {
                return // Already in the same set
            }
            
            // Union by rank
            if rank[rootX]! < rank[rootY]! {
                parent[rootX] = rootY
            } else if rank[rootX]! > rank[rootY]! {
                parent[rootY] = rootX
            } else {
                parent[rootY] = rootX
                rank[rootX]! += 1
            }
        }
        
        // Process all edges
        for edge in graph.edges() {
            guard let source = graph.source(of: edge),
                  let destination = graph.destination(of: edge) else { continue }
            
            visitor?.examineEdge?(edge)
            
            let rootSource = findRoot(source)
            let rootDestination = findRoot(destination)
            
            if rootSource == rootDestination {
                // Cycle detected - both vertices are already in the same set
                visitor?.cycleDetected?(edge)
                return true
            }
            
            union(source, destination)
        }
        
        return false
    }
}

// MARK: - Union-Find Data Structure

public struct UnionFindCyclicProperty<Graph: IncidenceGraph & VertexListGraph & EdgeListGraph> where Graph.VertexDescriptor: Hashable {
    public typealias Vertex = Graph.VertexDescriptor
    public typealias Edge = Graph.EdgeDescriptor
    
    public struct Visitor {
        public var examineEdge: ((Edge) -> Void)?
        public var findRoot: ((Vertex, Vertex) -> Void)?
        public var unionVertices: ((Vertex, Vertex) -> Void)?
        public var cycleDetected: ((Edge) -> Void)?
        
        public init(
            examineEdge: ((Edge) -> Void)? = nil,
            findRoot: ((Vertex, Vertex) -> Void)? = nil,
            unionVertices: ((Vertex, Vertex) -> Void)? = nil,
            cycleDetected: ((Edge) -> Void)? = nil
        ) {
            self.examineEdge = examineEdge
            self.findRoot = findRoot
            self.unionVertices = unionVertices
            self.cycleDetected = cycleDetected
        }
    }
    
    private let graph: Graph
    private var parent: [Vertex: Vertex] = [:]
    private var rank: [Vertex: Int] = [:]
    
    init(on graph: Graph) {
        self.graph = graph
        
        // Initialize each vertex as its own parent
        for vertex in graph.vertices() {
            parent[vertex] = vertex
            rank[vertex] = 0
        }
    }
    
    mutating func hasCycle(visitor: Visitor?) -> Bool {
        // Process all edges
        for edge in graph.edges() {
            visitor?.examineEdge?(edge)
            
            guard let source = graph.source(of: edge),
                  let destination = graph.destination(of: edge) else {
                continue
            }
            
            let rootSource = findRoot(source)
            let rootDestination = findRoot(destination)
            
            visitor?.findRoot?(rootSource, rootDestination)
            
            // If both vertices are in the same set, we found a cycle
            if rootSource == rootDestination {
                visitor?.cycleDetected?(edge)
                return true
            }
            
            // Union the two sets
            union(rootSource, rootDestination)
            visitor?.unionVertices?(rootSource, rootDestination)
        }
        
        return false
    }
    
    private mutating func findRoot(_ vertex: Vertex) -> Vertex {
        if parent[vertex] != vertex {
            // Path compression: make parent point directly to root
            parent[vertex] = findRoot(parent[vertex]!)
        }
        return parent[vertex]!
    }
    
    private mutating func union(_ x: Vertex, _ y: Vertex) {
        let rootX = findRoot(x)
        let rootY = findRoot(y)
        
        // Union by rank: attach smaller tree under root of larger tree
        if rank[rootX]! < rank[rootY]! {
            parent[rootX] = rootY
        } else if rank[rootX]! > rank[rootY]! {
            parent[rootY] = rootX
        } else {
            // If ranks are same, make one root and increment its rank
            parent[rootY] = rootX
            rank[rootX] = rank[rootX]! + 1
        }
    }
}
