import Foundation

/// Extension providing composition support for Louvain community detection algorithm visitors.
extension LouvainCommunityDetection.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            startPhase: { phase in
                self.startPhase?(phase)
                other.startPhase?(phase)
            },
            moveVertex: { vertex, community in
                self.moveVertex?(vertex, community)
                other.moveVertex?(vertex, community)
            },
            modularityImproved: { modularity in
                self.modularityImproved?(modularity)
                other.modularityImproved?(modularity)
            },
            iterationComplete: { phase, modularity in
                self.iterationComplete?(phase, modularity)
                other.iterationComplete?(phase, modularity)
            }
        )
    }
}
