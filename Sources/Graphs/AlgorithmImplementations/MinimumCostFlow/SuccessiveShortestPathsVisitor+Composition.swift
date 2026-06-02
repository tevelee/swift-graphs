#if !GRAPHS_USES_TRAITS || GRAPHS_OPTIMIZATION
    /// Extension providing composition support for Successive Shortest Paths visitors.
    extension SuccessiveShortestPaths.Visitor: Composable {
        /// Combines this visitor with another, so both receive every event.
        ///
        /// - Parameter other: The visitor to compose with.
        /// - Returns: A new visitor that forwards all events to both visitors.
        @inlinable
        public func combined(with other: Self) -> Self {
            .init(
                findPath: { source, sink in
                    self.findPath?(source, sink)
                    other.findPath?(source, sink)
                },
                augmentPath: { edges, flow in
                    self.augmentPath?(edges, flow)
                    other.augmentPath?(edges, flow)
                },
                updateFlow: { edge, flow in
                    self.updateFlow?(edge, flow)
                    other.updateFlow?(edge, flow)
                },
                iterationCompleted: { totalFlow, totalCost in
                    self.iterationCompleted?(totalFlow, totalCost)
                    other.iterationCompleted?(totalFlow, totalCost)
                }
            )
        }
    }
#endif
