import Collections

extension GraphTraversalStrategy {
    /// Creates a new instance of a priority traversal strategy using minimum first priority.
    /// - Parameters:
    ///  - visitor: The visitor to use during traversal.
    ///  - priorityFunction: The priority function used to prioritize nodes.
    /// - Returns: An instance of `PriorityTraversalStrategy`.
    @inlinable public static func bestFirstSearch<Visitor: VisitorProtocol, Priority: Comparable>(
        _ visitor: Visitor,
        priorityFunction: @escaping (Visitor.Visit) -> Priority
    ) -> Self where Self == PriorityTraversalStrategy<Visitor, Priority> {
        min(visitor, priorityFunction: priorityFunction)
    }

    /// Creates a new instance of a priority traversal strategy using minimum first priority.
    /// - Parameter priorityFunction: The priority function used to prioritize nodes.
    /// - Returns: An instance of `PriorityTraversalStrategy`.
    @inlinable public static func bestFirstSearch<Node, Edge, Priority: Comparable>(
        priorityFunction: @escaping (Node) -> Priority
    ) -> Self where Self == PriorityTraversalStrategy<NodeVisitor<Node, Edge>, Priority> {
        min(priorityFunction: priorityFunction)
    }

    /// Creates a new instance of a priority traversal strategy using minimum first priority.
    /// - Parameters:
    ///  - visitor: The visitor to use during traversal.
    ///  - priorityFunction: The priority function used to prioritize nodes.
    /// - Returns: An instance of `PriorityTraversalStrategy`.
    @inlinable public static func min<Visitor: VisitorProtocol, Priority: Comparable>(
        _ visitor: Visitor,
        priorityFunction: @escaping (Visitor.Visit) -> Priority
    ) -> Self where Self == PriorityTraversalStrategy<Visitor, Priority> {
        .init(visitor: visitor, isMin: true, priorityFunction: priorityFunction)
    }

    /// Creates a new instance of a priority traversal strategy using minimum first priority.
    /// - Parameter priorityFunction: The priority function used to prioritize nodes.
    /// - Returns: An instance of `PriorityTraversalStrategy`.
    @inlinable public static func min<Node, Edge, Priority: Comparable>(
        priorityFunction: @escaping (Node) -> Priority
    ) -> Self where Self == PriorityTraversalStrategy<NodeVisitor<Node, Edge>, Priority> {
        .init(visitor: .onlyNodes(), isMin: true, priorityFunction: priorityFunction)
    }

    /// Creates a new instance of a priority traversal strategy using maximum first priority.
    /// - Parameters:
    ///  - visitor: The visitor to use during traversal.
    ///  - priorityFunction: The priority function used to prioritize nodes.
    /// - Returns: An instance of `PriorityTraversalStrategy`.
    @inlinable public static func max<Visitor: VisitorProtocol, Priority: Comparable>(
        _ visitor: Visitor,
        priorityFunction: @escaping (Visitor.Visit) -> Priority
    ) -> Self where Self == PriorityTraversalStrategy<Visitor, Priority> {
        .init(visitor: visitor, isMin: false, priorityFunction: priorityFunction)
    }

    /// Creates a new instance of a priority traversal strategy using maximum first priority.
    /// - Parameter priorityFunction: The priority function used to prioritize nodes.
    /// - Returns: An instance of `PriorityTraversalStrategy`.
    @inlinable public static func max<Node, Edge, Priority: Comparable>(
        priorityFunction: @escaping (Node) -> Priority
    ) -> Self where Self == PriorityTraversalStrategy<NodeVisitor<Node, Edge>, Priority> {
        .init(visitor: .onlyNodes(), isMin: false, priorityFunction: priorityFunction)
    }
}

/// A graph traversal strategy that prioritizes nodes based on a priority function.
public struct PriorityTraversalStrategy<Visitor: VisitorProtocol, Priority: Comparable>: GraphTraversalStrategy
where Visitor.Visit: Equatable, Visitor.Node: Equatable {
    public typealias Storage = Heap<Visit>
    public typealias Node = Visitor.Node
    public typealias Edge = Visitor.Edge

    /// A visit instance that includes a priority.
    public struct Visit: Comparable {
        /// The base visit instance.
        public let base: Visitor.Visit
        /// The node being visited.
        public let node: Node
        /// The priority of the node.
        public let priority: Priority

        /// Initializes a new visit instance with the given base visit, node, and priority.
        /// - Parameters:
        ///  - base: The base visit instance.
        ///  - node: The node being visited.
        ///  - priority: The priority of the node.
        @inlinable public init(base: Visitor.Visit, node: Node, priority: Priority) {
            self.base = base
            self.node = node
            self.priority = priority
        }

        @inlinable public static func < (lhs: Self, rhs: Self) -> Bool {
            lhs.priority < rhs.priority
        }
    }

    /// The visitor used during traversal.
    public let visitor: Visitor
    /// Whether the priority order should be minimum or maximum first.
    public let isMin: Bool
    /// The priority function used to prioritize nodes.
    public let priorityFunction: (Visitor.Visit) -> Priority

    /// Initializes a new instance of the priority traversal strategy.
    /// - Parameters:
    ///  - visitor: The visitor to use during traversal.
    ///  - isMin: Whether the priority order should be minimum or maximum first.
    ///  - priorityFunction: The priority function used to prioritize nodes.
    @inlinable public init(visitor: Visitor, isMin: Bool, priorityFunction: @escaping (Visitor.Visit) -> Priority) {
        self.visitor = visitor
        self.isMin = isMin
        self.priorityFunction = priorityFunction
    }

    /// Initializes the storage for the traversal.
    /// - Parameter startNode: The node from which to start the traversal.
    /// - Returns: The storage containing the nodes to visit.
    @inlinable public func initializeStorage(startNode: Node) -> Storage {
        Heap([prioritize(visit: visitor.visit(node: startNode, from: nil))])
    }

    /// Prioritizes a visit instance based on the priority function.
    /// - Parameter visit: The visit instance to prioritize.
    /// - Returns: A visit instance with the priority set.
    @inlinable func prioritize(visit: Visitor.Visit) -> Visit {
        Visit(base: visit, node: visitor.node(from: visit), priority: priorityFunction(visit))
    }

    /// Retrieves the next node to visit from the storage.
    /// - Parameters:
    ///  - queue: The storage containing the nodes to visit.
    ///  - edges: A closure that returns the edges leading from a node.
    /// - Returns: The next node to visit, or `nil` if the traversal is complete.
    @inlinable public func next(from queue: inout Storage, edges: (Node) -> some Sequence<GraphEdge<Node, Edge>>) -> Visit? {
        guard let visit = isMin ? queue.popMin() : queue.popMax() else { return nil }
        let visits = edges(node(from: visit)).map { edge in
            prioritize(visit: visitor.visit(node: edge.destination, from: (visit.base, edge)))
        }
        queue.insert(contentsOf: visits)
        return visit
    }

    /// Extracts the node from a visit.
    /// - Parameter visit: The visit from which to extract the node.
    /// - Returns: The node associated with the visit.
    @inlinable public func node(from visit: Visit) -> Node {
        visitor.node(from: visit.base)
    }
}
