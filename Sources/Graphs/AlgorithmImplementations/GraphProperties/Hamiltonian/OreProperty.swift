/// Ore property visitor for Hamiltonian cycle algorithms.
public struct OreProperty<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
    /// A visitor that can be used to observe Ore property algorithm progress.
    public struct Visitor {
        /// Called when there are insufficient vertices for Ore's theorem.
        public var insufficientVertices: ((Int) -> Void)?
        /// Called when checking the vertex count.
        public var checkVertexCount: ((Int) -> Void)?
        /// Called when checking a vertex pair for adjacency.
        public var checkVertexPair: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Bool) -> Void)?
        /// Called when checking the degree sum of two vertices.
        public var checkDegreeSum: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Int, Int) -> Void)?
        /// Called when the degree sum is too low.
        public var degreeSumTooLow: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Int, Int) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            insufficientVertices: ((Int) -> Void)? = nil,
            checkVertexCount: ((Int) -> Void)? = nil,
            checkVertexPair: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Bool) -> Void)? = nil,
            checkDegreeSum: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Int, Int) -> Void)? = nil,
            degreeSumTooLow: ((Graph.VertexDescriptor, Graph.VertexDescriptor, Int, Int) -> Void)? = nil
        ) {
            self.insufficientVertices = insufficientVertices
            self.checkVertexCount = checkVertexCount
            self.checkVertexPair = checkVertexPair
            self.checkDegreeSum = checkDegreeSum
            self.degreeSumTooLow = degreeSumTooLow
        }
    }
}

extension OreProperty.Visitor: Composable {
    @inlinable
    public func combined(with other: OreProperty<Graph>.Visitor) -> OreProperty<Graph>.Visitor {
        OreProperty.Visitor(
            insufficientVertices: self.insufficientVertices ?? other.insufficientVertices,
            checkVertexCount: self.checkVertexCount ?? other.checkVertexCount,
            checkVertexPair: self.checkVertexPair ?? other.checkVertexPair,
            checkDegreeSum: self.checkDegreeSum ?? other.checkDegreeSum,
            degreeSumTooLow: self.degreeSumTooLow ?? other.degreeSumTooLow
        )
    }
}
