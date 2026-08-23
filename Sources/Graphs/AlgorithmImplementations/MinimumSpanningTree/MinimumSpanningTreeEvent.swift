/// An event emitted by a minimum-spanning-tree algorithm.
public enum MinimumSpanningTreeEvent<Vertex, Edge, Weight> {
    /// A vertex is about to be examined.
    case vertexExamined(Vertex)
    /// An edge is about to be examined.
    case edgeExamined(Edge)
    /// An edge was added to the spanning tree.
    case edgeAdded(Edge, weight: Weight)
    /// An edge was skipped.
    case edgeSkipped(Edge, reason: String)
    /// Two components were joined through their representative vertices.
    case verticesJoined(Vertex, Vertex)
    /// A Boruvka component-merge iteration completed.
    case componentMergeFinished(Int)
}

extension MinimumSpanningTreeEvent: VertexExaminedEvent, EdgeExaminedEvent {
    @inlinable
    public static func examinedVertex(from event: Self) -> Vertex? {
        guard case .vertexExamined(let vertex) = event else { return nil }
        return vertex
    }

    @inlinable
    public static func examinedEdge(from event: Self) -> Edge? {
        guard case .edgeExamined(let edge) = event else { return nil }
        return edge
    }
}

/// Typed selectors for minimum-spanning-tree events.
public enum MinimumSpanningTreeEventCases<Vertex, Edge, Weight> {
    /// Selects examined vertices.
    public static var vertexExamined: AlgorithmEventCase<MinimumSpanningTreeEvent<Vertex, Edge, Weight>, Vertex> {
        .init {
            guard case .vertexExamined(let vertex) = $0 else { return nil }
            return vertex
        }
    }

    /// Selects examined edges.
    public static var edgeExamined: AlgorithmEventCase<MinimumSpanningTreeEvent<Vertex, Edge, Weight>, Edge> {
        .init {
            guard case .edgeExamined(let edge) = $0 else { return nil }
            return edge
        }
    }

    /// Selects edges added to the spanning tree.
    public static var edgeAdded: AlgorithmEventCase<MinimumSpanningTreeEvent<Vertex, Edge, Weight>, (edge: Edge, weight: Weight)> {
        .init {
            guard case .edgeAdded(let edge, let weight) = $0 else { return nil }
            return (edge, weight)
        }
    }

    /// Selects skipped edges.
    public static var edgeSkipped: AlgorithmEventCase<MinimumSpanningTreeEvent<Vertex, Edge, Weight>, (edge: Edge, reason: String)> {
        .init {
            guard case .edgeSkipped(let edge, let reason) = $0 else { return nil }
            return (edge, reason)
        }
    }

    /// Selects component joins.
    public static var verticesJoined: AlgorithmEventCase<MinimumSpanningTreeEvent<Vertex, Edge, Weight>, (Vertex, Vertex)> {
        .init {
            guard case .verticesJoined(let first, let second) = $0 else { return nil }
            return (first, second)
        }
    }

    /// Selects completed Boruvka merge iterations.
    public static var componentMergeFinished: AlgorithmEventCase<MinimumSpanningTreeEvent<Vertex, Edge, Weight>, Int> {
        .init {
            guard case .componentMergeFinished(let iteration) = $0 else { return nil }
            return iteration
        }
    }
}
