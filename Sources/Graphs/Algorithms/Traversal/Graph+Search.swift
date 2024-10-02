extension GraphComponent {
    /// Searches for the first visit that satisfies the given goal using the specified traversal strategy.
    /// - Parameters:
    ///   - node: The starting node for the traversal.
    ///   - strategy: The traversal strategy to use.
    ///   - goal: A closure that takes a visit and returns a Boolean value indicating whether the visit satisfies the goal.
    /// - Returns: The first visit that satisfies the goal, or `nil` if no such visit is found.
    @inlinable public func searchFirst<Visit>(
        from node: Node,
        strategy: some GraphTraversalStrategy<Node, Edge, Visit>,
        goal: (Visit) -> Bool
    ) -> Visit? {
        traversal(from: node, strategy: strategy).first(where: goal)
    }

    /// Searches for all visits that satisfy the given goal using the specified traversal strategy.
    /// - Parameters:
    ///   - node: The starting node for the traversal.
    ///   - strategy: The traversal strategy to use.
    ///   - goal: A closure that takes a visit and returns a Boolean value indicating whether the visit satisfies the goal.
    /// - Returns: An array of visits that satisfy the goal.
    @inlinable public func searchAll<Visit>(
        from node: Node,
        strategy: some GraphTraversalStrategy<Node, Edge, Visit>,
        goal: (Visit) -> Bool
    ) -> [Visit] {
        traversal(from: node, strategy: strategy).filter(goal)
    }
}
