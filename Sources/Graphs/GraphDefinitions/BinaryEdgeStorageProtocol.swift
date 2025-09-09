protocol BinaryEdgeStorageProtocol: EdgeStorage {
    func leftEdge(of v: Vertex) -> Edge?
    func rightEdge(of v: Vertex) -> Edge?
    func leftNeighbor(of v: Vertex) -> Vertex?
    func rightNeighbor(of v: Vertex) -> Vertex?
}

extension BinaryEdgeStorage: BinaryEdgeStorageProtocol {}

// Default BinaryIncidenceGraph behavior for graphs backed by BinaryEdgeStorage
extension BinaryIncidenceGraph where Self: EdgeStorageBackedGraph, EdgeStore: BinaryEdgeStorageProtocol {
    func leftEdge(of v: VertexDescriptor) -> EdgeDescriptor? { edgeStore.leftEdge(of: v) }
    func rightEdge(of v: VertexDescriptor) -> EdgeDescriptor? { edgeStore.rightEdge(of: v) }
    func leftNeighbor(of v: VertexDescriptor) -> VertexDescriptor? { edgeStore.leftNeighbor(of: v) }
    func rightNeighbor(of v: VertexDescriptor) -> VertexDescriptor? { edgeStore.rightNeighbor(of: v) }
}

extension MutableBinaryIncidenceGraph where Self: EdgeStorageBackedGraph & MutableGraph, EdgeStore: BinaryEdgeStorageProtocol {
    @discardableResult
    mutating func setLeftChild(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor? {
        if let existing = leftEdge(of: parent) { remove(edge: existing) }
        return addEdge(from: parent, to: child)
    }

    @discardableResult
    mutating func setRightChild(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor? {
        if let existing = rightEdge(of: parent) { remove(edge: existing) }
        return addEdge(from: parent, to: child)
    }
}


