import Algorithms
import Collections

/// A graph traversal strategy that performs iteratively deepening depth-first search.
extension GraphTraversalStrategy {
    /// Creates a new instance of iteratively deepening depth-first search.
    /// - Parameters:
    ///  - visitor: The visitor to use during traversal.
    ///  - iteration: The depth iteration at which to expand nodes.
    /// - Returns: An instance of `IterativelyDeepeningDepthFirstSearch`.
    @inlinable public static func iterativelyDeepeningDFS<Visitor: VisitorProtocol>(
        _ visitor: Visitor,
        iteration: Int
    ) -> Self where Self == IterativelyDeepeningDepthFirstSearch<Visitor>, Visitor.Visit: DepthMeasuring {
        .init(visitor: visitor, depthIteration: iteration)
    }

    /// Creates a new instance of iteratively deepening depth-first search.
    /// - Parameter iteration: The depth iteration at which to expand nodes.
    /// - Returns: An instance of `IterativelyDeepeningDepthFirstSearch`.
    @inlinable public static func iterativelyDeepeningDFS<Node, Edge>(
        iteration: Int
    ) -> Self where Self == IterativelyDeepeningDepthFirstSearch<DepthTrackingVisitor<NodeVisitor<Node, Edge>>> {
        .init(visitor: NodeVisitor().trackDepth(), depthIteration: iteration)
    }
}

/// A graph traversal strategy that performs iteratively deepening depth-first search.
public struct IterativelyDeepeningDepthFirstSearch<Visitor: VisitorProtocol>: GraphTraversalStrategy where Visitor.Visit: DepthMeasuring {
    public typealias Storage = Deque<Visitor.Visit>
    public typealias Node = Visitor.Node
    public typealias Edge = Visitor.Edge
    public typealias Visit = Visitor.Visit

    /// The visitor used during traversal.
    public let visitor: Visitor
    /// The depth iteration at which to expand nodes.
    public let depthIteration: Int

    /// Initializes a new instance of iteratively deepening depth-first search.
    /// - Parameters:
    ///  - visitor: The visitor to use during traversal.
    ///  - depthIteration: The depth iteration at which to expand nodes.
    @inlinable public init(visitor: Visitor, depthIteration: Int) {
        self.visitor = visitor
        self.depthIteration = depthIteration
    }

    /// Initializes the storage for the traversal.
    /// - Parameter startNode: The node from which to start the traversal.
    /// - Returns: The storage containing the nodes to visit.
    @inlinable public func initializeStorage(startNode: Node) -> Storage {
        Deque([visitor.visit(node: startNode, from: nil)])
    }

    /// Retrieves the next node to visit from the storage.
    /// - Parameters:
    ///  - queue: The storage containing the nodes to visit.
    ///  - edges: A closure that returns the edges leading from a node.
    /// - Returns: The next node to visit, or `nil` if the traversal is complete.
    @inlinable public func next(from queue: inout Storage, edges: (Node) -> some Sequence<GraphEdge<Node, Edge>>) -> Visit? {
        guard let visit = queue.popFirst() else { return nil }
        let visits = edges(node(from: visit)).map { edge in
            visitor.visit(node: edge.destination, from: (visit, edge))
        }
        let (sameIteration, newIteration) = visits.partitioned { $0.depth / depthIteration == visit.depth / depthIteration }
        queue.prepend(contentsOf: sameIteration)
        queue.append(contentsOf: newIteration)
        return visit
    }

    /// Extracts the node from a visit.
    @inlinable public func node(from visit: Visit) -> Node {
        visitor.node(from: visit)
    }
}
