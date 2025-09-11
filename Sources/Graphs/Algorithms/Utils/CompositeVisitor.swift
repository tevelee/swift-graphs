// MARK: - Composite Visitor for DFS

extension DepthFirstSearch.Visitor {
    static func composite(_ visitors: Self...) -> Self {
        .init(
            discoverVertex: { vertex in
                for visitor in visitors {
                    visitor.discoverVertex?(vertex)
                }
            },
            examineVertex: { vertex in
                for visitor in visitors {
                    visitor.examineVertex?(vertex)
                }
            },
            examineEdge: { edge in
                for visitor in visitors {
                    visitor.examineEdge?(edge)
                }
            },
            treeEdge: { edge in
                for visitor in visitors {
                    visitor.treeEdge?(edge)
                }
            },
            backEdge: { edge in
                for visitor in visitors {
                    visitor.backEdge?(edge)
                }
            },
            forwardEdge: { edge in
                for visitor in visitors {
                    visitor.forwardEdge?(edge)
                }
            },
            crossEdge: { edge in
                for visitor in visitors {
                    visitor.crossEdge?(edge)
                }
            },
            finishVertex: { vertex in
                for visitor in visitors {
                    visitor.finishVertex?(vertex)
                }
            },
            shouldTraverse: { context in
                // For shouldTraverse, we need all visitors to agree (AND logic)
                for visitor in visitors {
                    if let shouldTraverse = visitor.shouldTraverse, !shouldTraverse(context) {
                        return false
                    }
                }
                return true
            }
        )
    }
}
