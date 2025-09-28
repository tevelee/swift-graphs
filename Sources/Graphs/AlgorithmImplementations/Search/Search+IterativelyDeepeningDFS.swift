extension SearchAlgorithm {
    static func iterativelyDeepeningDFS<Graph>(maxDepth: UInt? = nil) -> Self where Self == IterativelyDeepeningDFSSearch<Graph> {
        .init(maxDepth: maxDepth)
    }
}

struct IterativelyDeepeningDFSSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    typealias Visitor = DepthFirstSearch<Graph>.Visitor
    
    let maxDepth: UInt?
    
    func search(
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

struct IterativelyDeepeningDFSSearchIterator<Graph: IncidenceGraph>: Sequence where Graph.VertexDescriptor: Hashable {
    typealias Iterator = IterativelyDeepeningDFSIterator<Graph>
    
    private let graph: Graph
    private let source: Graph.VertexDescriptor
    private let visitor: DepthFirstSearch<Graph>.Visitor?
    private let maxDepth: UInt?
    
    init(
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
    
    func makeIterator() -> Iterator {
        Iterator(
            graph: graph,
            source: source,
            visitor: visitor,
            maxDepth: maxDepth
        )
    }
}

extension IterativelyDeepeningDFSSearchIterator: VisitorSupportingSequence {
    typealias Visitor = DepthFirstSearch<Graph>.Visitor
    
    func makeIterator(visitor: Visitor?) -> Iterator {
        Iterator(
            graph: graph,
            source: source,
            visitor: visitor,
            maxDepth: maxDepth
        )
    }
}

struct IterativelyDeepeningDFSIterator<Graph: IncidenceGraph>: IteratorProtocol where Graph.VertexDescriptor: Hashable {
    typealias Element = DepthFirstSearch<Graph>.Result
    
    private let graph: Graph
    private let source: Graph.VertexDescriptor
    private let visitor: DepthFirstSearch<Graph>.Visitor?
    private let maxDepth: UInt?
    
    private var currentDepth: UInt = 0
    private var currentIterator: DepthFirstSearch<Graph>.Iterator?
    private var visitedVertices = Set<Graph.VertexDescriptor>()
    private var isComplete = false
    
    init(
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
    
    mutating func next() -> Element? {
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
