import Benchmark
import Graphs

func registerMSTBenchmarks() {
    Benchmark("MST/Kruskal/undirected-5k-d8") { benchmark in
        let (graph, _) = makeUndirectedSparseGraph(n: 5_000, avgDegree: 8)
        let weight: CostDefinition<BenchGraph, Double> = .property(\.weight)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let mst = graph.minimumSpanningTree(using: .kruskal(weight: weight))
            blackHole(mst)
        }
    }

    Benchmark("MST/Prim/undirected-5k-d8") { benchmark in
        let (graph, _) = makeUndirectedSparseGraph(n: 5_000, avgDegree: 8)
        let weight: CostDefinition<BenchGraph, Double> = .property(\.weight)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let mst = graph.minimumSpanningTree(using: .prim(weight: weight))
            blackHole(mst)
        }
    }

    Benchmark("MST/Boruvka/undirected-5k-d8") { benchmark in
        let (graph, _) = makeUndirectedSparseGraph(n: 5_000, avgDegree: 8)
        let weight: CostDefinition<BenchGraph, Double> = .property(\.weight)
        benchmark.startMeasurement()
        for _ in benchmark.scaledIterations {
            let mst = graph.minimumSpanningTree(using: .boruvka(weight: weight))
            blackHole(mst)
        }
    }
}
