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
    public typealias Event = DepthFirstSearch<Graph>.Event

    /// The maximum depth to search, or nil for unlimited.
    public let maxDepth: UInt?
    @usableFromInline
    let shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?

    /// Creates a new iteratively deepening DFS search algorithm.
    ///
    /// - Parameter maxDepth: The maximum depth to search, or nil for unlimited.
    @inlinable
    public init(maxDepth: UInt? = nil) {
        self.maxDepth = maxDepth
        self.shouldTraverse = nil
    }

    @inlinable
    init(maxDepth: UInt?, shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?) {
        self.maxDepth = maxDepth
        self.shouldTraverse = shouldTraverse
    }

    /// Adds a policy that decides whether candidate tree edges may be traversed.
    @inlinable
    public func allowingTraversal(_ predicate: @escaping (DepthFirstSearch<Graph>.TraversalCandidate) -> Bool) -> Self {
        let earlier = shouldTraverse
        return .init(maxDepth: maxDepth) { candidate in
            (earlier?(candidate) ?? true) && predicate(candidate)
        }
    }

    /// Performs an iteratively deepening DFS search from the source vertex.
    ///
    /// - Parameters:
    ///   - source: The vertex to start search from.
    ///   - graph: The graph to search in.
    ///   - observation: An optional observation of the search progress.
    /// - Returns: An iteratively deepening DFS search iterator.
    @inlinable
    public func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        observation: AlgorithmObservation<Event>?
    ) -> IterativelyDeepeningDFSSearchIterator<Graph> {
        IterativelyDeepeningDFSSearchIterator(
            graph: graph,
            source: source,
            observation: observation,
            shouldTraverse: shouldTraverse,
            maxDepth: maxDepth
        )
    }
}

/// An iterator for iteratively deepening DFS search results.
public struct IterativelyDeepeningDFSSearchIterator<Graph: IncidenceGraph>: Sequence where Graph.VertexDescriptor: Hashable {
    public typealias Iterator = IterativelyDeepeningDFSIterator<Graph>
    public typealias Event = DepthFirstSearch<Graph>.Event

    @usableFromInline
    let graph: Graph
    @usableFromInline
    let source: Graph.VertexDescriptor
    @usableFromInline
    let observation: AlgorithmObservation<Event>?
    @usableFromInline
    let shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?
    @usableFromInline
    let maxDepth: UInt?

    @inlinable
    public init(
        graph: Graph,
        source: Graph.VertexDescriptor,
        observation: AlgorithmObservation<Event>? = nil,
        shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?,
        maxDepth: UInt?
    ) {
        self.graph = graph
        self.source = source
        self.observation = observation
        self.shouldTraverse = shouldTraverse
        self.maxDepth = maxDepth
    }

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(
            graph: graph,
            source: source,
            observation: observation,
            shouldTraverse: shouldTraverse,
            maxDepth: maxDepth
        )
    }
}

extension IterativelyDeepeningDFSSearchIterator: AlgorithmObservationSequence {
    @inlinable
    public func makeIterator(observation: AlgorithmObservation<Event>?) -> Iterator {
        let combined = self.observation.map { $0.followed(by: observation) } ?? observation
        return Iterator(
            graph: graph,
            source: source,
            observation: combined,
            shouldTraverse: shouldTraverse,
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
    let observation: AlgorithmObservation<DepthFirstSearch<Graph>.Event>?
    @usableFromInline
    let shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?
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
        observation: AlgorithmObservation<DepthFirstSearch<Graph>.Event>? = nil,
        shouldTraverse: ((DepthFirstSearch<Graph>.TraversalCandidate) -> Bool)?,
        maxDepth: UInt?
    ) {
        self.graph = graph
        self.source = source
        self.observation = observation
        self.shouldTraverse = shouldTraverse
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

                // Create a policy that respects the depth limit.
                let currentDepthLimit = self.currentDepth
                let callerPolicy = shouldTraverse
                let depthPolicy: (DepthFirstSearch<Graph>.TraversalCandidate) -> Bool = { candidate in
                    let currentDepth = candidate.context.depth(of: candidate.from) ?? 0
                    return currentDepth < currentDepthLimit && (callerPolicy?(candidate) ?? true)
                }

                currentIterator = DepthFirstSearch(
                    on: graph,
                    from: source,
                    shouldTraverse: depthPolicy
                ).makeIterator(
                    observation: observation
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

extension IterativelyDeepeningDFSSearch: AlgorithmObserving {}
