import Testing
@testable import Graphs

struct LazyGraphTests {
    @Test func incidenceGraph() {
        let graph = LazyIncidenceGraph { vertex in
            vertex == "root" ? ["a", "b", "c"] : []
        }
        #expect(graph.traverse(from: "root", using: .bfs()).vertices == ["root", "a", "b", "c"])
    }
}
