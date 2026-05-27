#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
import OrderedCollections

// MARK: - OrderedVertexStorage.Vertex

extension OrderedVertexStorage.Vertex: SerializableDescriptor {
    public var serializedIdentifier: String {
        "v\(id)"
    }
}

// MARK: - LinearOrderedEdgeStorage.Edge
// (Reached through the OrderedEdgeStorage typealias, which is
// CacheInOutEdges<LinearOrderedEdgeStorage<V>>; the Edge type is the underlying
// LinearOrderedEdgeStorage.Edge.)

extension LinearOrderedEdgeStorage.Edge: SerializableDescriptor {
    public var serializedIdentifier: String {
        "e\(id)"
    }
}

// MARK: - AdjacencyMatrix Descriptors

extension AdjacencyMatrix.Vertex: SerializableDescriptor {
    public var serializedIdentifier: String {
        "v\(id)"
    }
}

extension AdjacencyMatrix.Edge: SerializableDescriptor {
    public var serializedIdentifier: String {
        "e\(id)"
    }
}

// MARK: - GridGraph Descriptors

extension GridGraph.Vertex: SerializableDescriptor {
    public var serializedIdentifier: String {
        "\(x)_\(y)"
    }
}

extension GridGraph.Edge: SerializableDescriptor {
    public var serializedIdentifier: String {
        "\(source.serializedIdentifier)_to_\(destination.serializedIdentifier)"
    }
}

// MARK: - String (for InlineGraph)

extension String: SerializableDescriptor {
    public var serializedIdentifier: String {
        self
    }
}

// MARK: - Int

extension Int: SerializableDescriptor {
    public var serializedIdentifier: String {
        "\(self)"
    }
}
#endif
