extension SearchAlgorithm {
    /// Creates an iteratively deepening DFS search algorithm.
    ///
    /// - Parameter maxDepth: The maximum depth to search, or nil for unlimited.
    /// - Returns: An iteratively deepening DFS search algorithm instance.
    @inlinable
    public static func iterativelyDeepeningDFS<Graph>(maxDepth: UInt? = nil) -> Self where Self == IterativelyDeepeningDFSSearch<Graph> {
        .init(maxDepth: maxDepth)
    }
}

/// An iteratively deepening DFS search algorithm implementation for the SearchAlgorithm protocol.
///
/// This struct wraps the core iteratively deepening DFS algorithm to provide a
/// SearchAlgorithm interface, making it easy to use IDDFS as a general search algorithm.
///
/// - Complexity: O(b^d) where b is the branching factor and d is the depth
public struct IterativelyDeepeningDFSSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    /// The visitor type for observing search progress.
    public typealias Visitor = DepthFirstSearch<Graph>.Visitor
    
    /// The maximum depth to search, or nil for unlimited.
    public let maxDepth: UInt?
    
    /// Creates a new iteratively deepening DFS search algorithm.
    ///
    /// - Parameter maxDepth: The maximum depth to search, or nil for unlimited.
    @inlinable
    public init(maxDepth: UInt? = nil) {
        self.maxDepth = maxDepth
    }
    
    /// Performs an iteratively deepening DFS search from the source vertex.
    ///
    /// - Parameters:
    ///   - source: The vertex to start search from.
    ///   - graph: The graph to search in.
    ///   - visitor: An optional visitor to observe the search progress.
    /// - Returns: An iteratively deepening DFS search iterator.
    @inlinable
    public func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: Visitor?
    ) -> IterativelyDeepeningDFSSearchIterator<Graph> {
        IterativelyDeepeningDFSSearchIterator(
            graph: graph,
            source: source,
            visitor: visitor,
            maxDepth: maxDepth
        )
    }
}

/// An iterator for iteratively deepening DFS search results.
public struct IterativelyDeepeningDFSSearchIterator<Graph: IncidenceGraph>: Sequence where Graph.VertexDescriptor: Hashable {
    public typealias Iterator = IterativelyDeepeningDFSIterator<Graph>
    
    @usableFromInline
    let graph: Graph
    @usableFromInline
    let source: Graph.VertexDescriptor
    @usableFromInline
    let visitor: DepthFirstSearch<Graph>.Visitor?
    @usableFromInline
    let maxDepth: UInt?
    
    @inlinable
    public init(
        graph: Graph,
        source: Graph.VertexDescriptor,
        visitor: DepthFirstSearch<Graph>.Visitor?,
        maxDepth: UInt?
    ) {
        self.graph = graph
        self.source = source
        self.visitor = visitor
        self.maxDepth = maxDepth
    }
    
    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(
            graph: graph,
            source: source,
            visitor: visitor,
            maxDepth: maxDepth
        )
    }
}

extension IterativelyDeepeningDFSSearchIterator: VisitorSupportingSequence {
    public typealias Visitor = DepthFirstSearch<Graph>.Visitor
    
    @inlinable
    public func makeIterator(visitor: Visitor?) -> Iterator {
        Iterator(
            graph: graph,
            source: source,
            visitor: visitor,
            maxDepth: maxDepth
        )
    }
}

/// An iterator that performs iteratively deepening DFS search.
public struct IterativelyDeepeningDFSIterator<Graph: IncidenceGraph>: IteratorProtocol where Graph.VertexDescriptor: Hashable {
    public typealias Element = DepthFirstSearch<Graph>.Result
    
    @usableFromInline
    let graph: Graph
    @usableFromInline
    let source: Graph.VertexDescriptor
    @usableFromInline
    let visitor: DepthFirstSearch<Graph>.Visitor?
    @usableFromInline
    let maxDepth: UInt?
    
    @usableFromInline
    var currentDepth: UInt = 0
    @usableFromInline
    var currentIterator: DepthFirstSearch<Graph>.Iterator?
    @usableFromInline
    var visitedVertices = Set<Graph.VertexDescriptor>()
    @usableFromInline
    var isComplete = false
    
    @inlinable
    public init(
        graph: Graph,
        source: Graph.VertexDescriptor,
        visitor: DepthFirstSearch<Graph>.Visitor?,
        maxDepth: UInt?
    ) {
        self.graph = graph
        self.source = source
        self.visitor = visitor
        self.maxDepth = maxDepth
    }
    
    @inlinable
    public mutating func next() -> Element? {
        while !isComplete {
            // If we don't have a current iterator, create one for the current depth
            if currentIterator == nil {
                // Check if we've exceeded the maximum depth
                if let maxDepth = maxDepth, currentDepth > maxDepth {
                    isComplete = true
                    return nil
                }
                
                // Create a visitor that respects the depth limit and tracks visited vertices
                let currentDepthLimit = self.currentDepth
                let visitor = self.visitor
                let depthVisitor = DepthFirstSearch<Graph>.Visitor(
                    shouldTraverse: { args in
                        guard let currentDepth = args.context.depth(of: args.from) else { return true }
                        return currentDepth < currentDepthLimit
                    }
                )
                
                currentIterator = DepthFirstSearch(on: graph, from: source).makeIterator(
                    visitor: depthVisitor.combined(with: visitor)
                )
            }
            
            // Try to get the next result from the current iterator
            if let result = currentIterator?.next() {
                // Only return vertices that haven't been visited yet
                if !visitedVertices.contains(result.currentVertex) {
                    visitedVertices.insert(result.currentVertex)
                    return result
                }
                // Skip already visited vertices and continue the loop
                continue
            }
            
            // Current depth is exhausted, move to next depth
            // Add a reasonable maximum depth to prevent infinite loops
            if currentDepth > 1000 {
                isComplete = true
                return nil
            }
            
            // Move to next depth
            currentIterator = nil
            currentDepth += 1
        }
        
        return nil
    }
}

extension IterativelyDeepeningDFSSearch: VisitorSupporting {}
