extension OrePropertyAlgorithm {
    static func standard<Graph>() -> Self where Self == StandardOrePropertyAlgorithm<Graph> {
        .init()
    }
}

extension StandardOrePropertyAlgorithm: OrePropertyAlgorithm {}
