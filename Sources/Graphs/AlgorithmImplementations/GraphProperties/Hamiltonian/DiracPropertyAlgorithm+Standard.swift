extension DiracPropertyAlgorithm {
    static func standard<Graph>() -> Self where Self == StandardDiracPropertyAlgorithm<Graph> {
        .init()
    }
}

extension StandardDiracPropertyAlgorithm: DiracPropertyAlgorithm {}
