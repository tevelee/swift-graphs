protocol BinaryIncidenceGraph: Graph {
    func leftEdge(of v: VertexDescriptor) -> EdgeDescriptor?
    func rightEdge(of v: VertexDescriptor) -> EdgeDescriptor?

    func leftNeighbor(of v: VertexDescriptor) -> VertexDescriptor?
    func rightNeighbor(of v: VertexDescriptor) -> VertexDescriptor?
}

protocol MutableBinaryIncidenceGraph: BinaryIncidenceGraph, MutableGraph {
    @discardableResult
    mutating func setLeftChild(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor?
    @discardableResult
    mutating func setRightChild(of parent: VertexDescriptor, to child: VertexDescriptor) -> EdgeDescriptor?
}
