extension BinaryGraphProtocol {
    /// Searches for the first visit that meets the goal criteria using the specified traversal strategy.
    /// - Parameters:
    ///   - node: The starting node for the search.
    ///   - strategy: The traversal strategy to use for the search.
    ///   - goal: A closure that takes a visit and returns a Boolean value indicating whether the visit meets the goal criteria.
    /// - Returns: The first visit that meets the goal criteria, or `nil` if no such visit is found.
    @inlinable public func searchFirst<Visit>(from node: Node, strategy: some BinaryGraphTraversalStrategy<Node, Edge, Visit>, goal: (Visit) -> Bool) -> Visit? {
        traversal(from: node, strategy: strategy).first(where: goal)
    }

    /// Searches for all visits that meet the goal criteria using the specified traversal strategy.
    /// - Parameters:
    ///   - node: The starting node for the search.
    ///   - strategy: The traversal strategy to use for the search.
    ///   - goal: A closure that takes a visit and returns a Boolean value indicating whether the visit meets the goal criteria.
    /// - Returns: An array of visits that meet the goal criteria.
    @inlinable public func searchAll<Visit>(from node: Node, strategy: some BinaryGraphTraversalStrategy<Node, Edge, Visit>, goal: (Visit) -> Bool) -> [Visit] {
        traversal(from: node, strategy: strategy).filter(goal)
    }
}
