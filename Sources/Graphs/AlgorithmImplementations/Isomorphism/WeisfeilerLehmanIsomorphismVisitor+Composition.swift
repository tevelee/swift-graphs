import Foundation

/// Extension providing composition support for Weisfeiler-Lehman isomorphism algorithm visitors.
extension WeisfeilerLehmanIsomorphism.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            labelVertex: { vertex, label in
                self.labelVertex?(vertex, label)
                other.labelVertex?(vertex, label)
            },
            iterationComplete: { iteration, labels in
                self.iterationComplete?(iteration, labels)
                other.iterationComplete?(iteration, labels)
            },
            labelsStabilized: { labels in
                self.labelsStabilized?(labels)
                other.labelsStabilized?(labels)
            }
        )
    }
}

/// Extension providing composition support for enhanced Weisfeiler-Lehman isomorphism algorithm visitors.
extension EnhancedWeisfeilerLehmanIsomorphism.Visitor: Composable {
    /// Combines this visitor with another visitor.
    ///
    /// - Parameter other: The other visitor to combine with.
    /// - Returns: A new visitor that calls both visitors' callbacks.
    @inlinable
    public func combined(with other: Self) -> Self {
        .init(
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            labelVertex: { vertex, label in
                self.labelVertex?(vertex, label)
                other.labelVertex?(vertex, label)
            },
            iterationComplete: { iteration, labels in
                self.iterationComplete?(iteration, labels)
                other.iterationComplete?(iteration, labels)
            },
            labelsStabilized: { labels in
                self.labelsStabilized?(labels)
                other.labelsStabilized?(labels)
            }
        )
    }
}
