/// Dirac property visitor for Hamiltonian cycle algorithms.
public struct DiracProperty<Graph: IncidenceGraph & VertexListGraph & BidirectionalGraph> where Graph.VertexDescriptor: Hashable {
    /// A visitor that can be used to observe Dirac property algorithm progress.
    public struct Visitor {
        /// Called when there are insufficient vertices for Dirac's theorem.
        public var insufficientVertices: ((Int) -> Void)?
        /// Called when checking the minimum degree requirement.
        public var checkMinimumDegree: ((Int) -> Void)?
        /// Called when checking a vertex's degree.
        public var checkVertexDegree: ((Graph.VertexDescriptor, Int, Int) -> Void)?
        /// Called when a vertex's degree is too low.
        public var degreeTooLow: ((Graph.VertexDescriptor, Int, Int) -> Void)?
        
        /// Creates a new visitor.
        @inlinable
        public init(
            insufficientVertices: ((Int) -> Void)? = nil,
            checkMinimumDegree: ((Int) -> Void)? = nil,
            checkVertexDegree: ((Graph.VertexDescriptor, Int, Int) -> Void)? = nil,
            degreeTooLow: ((Graph.VertexDescriptor, Int, Int) -> Void)? = nil
        ) {
            self.insufficientVertices = insufficientVertices
            self.checkMinimumDegree = checkMinimumDegree
            self.checkVertexDegree = checkVertexDegree
            self.degreeTooLow = degreeTooLow
        }
    }
}

extension DiracProperty.Visitor: Composable {
    @inlinable
    public func combined(with other: DiracProperty<Graph>.Visitor) -> DiracProperty<Graph>.Visitor {
        DiracProperty.Visitor(
            insufficientVertices: self.insufficientVertices ?? other.insufficientVertices,
            checkMinimumDegree: self.checkMinimumDegree ?? other.checkMinimumDegree,
            checkVertexDegree: self.checkVertexDegree ?? other.checkVertexDegree,
            degreeTooLow: self.degreeTooLow ?? other.degreeTooLow
        )
    }
}
