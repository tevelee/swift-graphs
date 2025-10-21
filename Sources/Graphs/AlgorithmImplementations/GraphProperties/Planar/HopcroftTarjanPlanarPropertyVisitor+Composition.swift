/// Extension providing composition support for Hopcroft-Tarjan planar property algorithm visitors.
extension HopcroftTarjanPlanarPropertyAlgorithm.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: HopcroftTarjanPlanarPropertyAlgorithm.Visitor) -> HopcroftTarjanPlanarPropertyAlgorithm.Visitor {
        HopcroftTarjanPlanarPropertyAlgorithm.Visitor(
            startDFS: {
                self.startDFS?()
                other.startDFS?()
            },
            discoverVertex: { vertex, time in
                self.discoverVertex?(vertex, time)
                other.discoverVertex?(vertex, time)
            },
            examineEdge: { edge, type in
                self.examineEdge?(edge, type)
                other.examineEdge?(edge, type)
            },
            calculateLowpoint: { vertex, lowpoint in
                self.calculateLowpoint?(vertex, lowpoint)
                other.calculateLowpoint?(vertex, lowpoint)
            },
            checkPlanarity: {
                self.checkPlanarity?()
                other.checkPlanarity?()
            },
            planarityViolation: { reason in
                self.planarityViolation?(reason)
                other.planarityViolation?(reason)
            },
            planaritySuccess: {
                self.planaritySuccess?()
                other.planaritySuccess?()
            }
        )
    }
}
