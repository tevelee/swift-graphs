/// Extension providing composition support for Watts-Strogatz random graph algorithm visitors.
extension WattsStrogatz.Visitor: Composable {
    public typealias Other = WattsStrogatz.Visitor
    
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            addVertex: { vertex in
                self.addVertex?(vertex)
                other.addVertex?(vertex)
            },
            addEdge: { from, to in
                self.addEdge?(from, to)
                other.addEdge?(from, to)
            },
            rewireEdge: { from, oldTo, newTo in
                self.rewireEdge?(from, oldTo, newTo)
                other.rewireEdge?(from, oldTo, newTo)
            },
            skipRewiring: { from, to, reason in
                self.skipRewiring?(from, to, reason)
                other.skipRewiring?(from, to, reason)
            },
            createRingLattice: { from, to in
                self.createRingLattice?(from, to)
                other.createRingLattice?(from, to)
            }
        )
    }
}
