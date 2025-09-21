extension SmallestLastVertexOrderingAlgorithm.Visitor: Composable {
    typealias Other = Self
    
    func combined(with other: Self) -> Self {
        Self(
            examineVertex: other.examineVertex ?? self.examineVertex,
            removeVertex: other.removeVertex ?? self.removeVertex,
            updateDegree: other.updateDegree ?? self.updateDegree
        )
    }
}
