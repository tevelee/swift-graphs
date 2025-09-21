extension ReverseCuthillMcKeeOrderingAlgorithm.Visitor: Composable {
    typealias Other = Self
    
    func combined(with other: Self) -> Self {
        Self(
            examineVertex: other.examineVertex ?? self.examineVertex,
            enqueueVertex: other.enqueueVertex ?? self.enqueueVertex,
            dequeueVertex: other.dequeueVertex ?? self.dequeueVertex,
            startFromVertex: other.startFromVertex ?? self.startFromVertex
        )
    }
}
