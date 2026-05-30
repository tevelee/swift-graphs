/// Extension providing composition support for Chrobak-Payne planar drawing visitors.
extension ChrobakPayneDrawing.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: ChrobakPayneDrawing.Visitor) -> ChrobakPayneDrawing.Visitor {
        ChrobakPayneDrawing.Visitor(
            start: {
                self.start?()
                other.start?()
            },
            foundDrawing: { drawing in
                self.foundDrawing?(drawing)
                other.foundDrawing?(drawing)
            },
            foundNonPlanar: {
                self.foundNonPlanar?()
                other.foundNonPlanar?()
            }
        )
    }
}
