/// Extension providing composition support for Left-Right planar embedding visitors.
extension LeftRightPlanarEmbedding.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: LeftRightPlanarEmbedding.Visitor) -> LeftRightPlanarEmbedding.Visitor {
        LeftRightPlanarEmbedding.Visitor(
            start: {
                self.start?()
                other.start?()
            },
            foundPlanar: { embedding in
                self.foundPlanar?(embedding)
                other.foundPlanar?(embedding)
            },
            foundNonPlanar: { certificate in
                self.foundNonPlanar?(certificate)
                other.foundNonPlanar?(certificate)
            }
        )
    }
}
