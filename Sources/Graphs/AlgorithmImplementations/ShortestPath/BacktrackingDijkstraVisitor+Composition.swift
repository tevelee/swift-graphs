extension BacktrackingDijkstra.Visitor: Composable {
    public typealias Other = Self
    
    @inlinable
    public func combined(with other: Self) -> Self {
        return Self(
            examineVertex: { vertex in
                self.examineVertex?(vertex)
                other.examineVertex?(vertex)
            },
            examineEdge: { edge in
                self.examineEdge?(edge)
                other.examineEdge?(edge)
            },
            edgeOnShortestPath: { edge in
                self.edgeOnShortestPath?(edge)
                other.edgeOnShortestPath?(edge)
            },
            finishVertex: { vertex in
                self.finishVertex?(vertex)
                other.finishVertex?(vertex)
            },
            pathFound: { vertices, edges in
                self.pathFound?(vertices, edges)
                other.pathFound?(vertices, edges)
            }
        )
    }
}

