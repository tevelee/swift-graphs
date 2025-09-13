@testable import Graphs
import Testing

struct ColoringExampleTest {
    
    @Test func testColoringExample() {
        // Create a sample graph
        var graph = AdjacencyList()
        
        // Add vertices
        let a = graph.addVertex { $0.label = "A" }
        let b = graph.addVertex { $0.label = "B" }
        let c = graph.addVertex { $0.label = "C" }
        let d = graph.addVertex { $0.label = "D" }
        let e = graph.addVertex { $0.label = "E" }
        
        // Add edges to create a pentagon
        graph.addEdge(from: a, to: b)
        graph.addEdge(from: b, to: a)
        graph.addEdge(from: b, to: c)
        graph.addEdge(from: c, to: b)
        graph.addEdge(from: c, to: d)
        graph.addEdge(from: d, to: c)
        graph.addEdge(from: d, to: e)
        graph.addEdge(from: e, to: d)
        graph.addEdge(from: e, to: a)
        graph.addEdge(from: a, to: e)
        
        // Test Greedy coloring
        let greedyColoring = graph.colorGraph(using: .greedy(on: graph))
        #expect(greedyColoring.isProper)
        #expect(greedyColoring.chromaticNumber >= 2) // Pentagon needs at least 2 colors
        #expect(greedyColoring.chromaticNumber <= 3) // Pentagon can be colored with 3 colors
        
        // Test DSatur coloring
        let dsaturColoring = graph.colorGraph(using: .dsatur(on: graph))
        #expect(dsaturColoring.isProper)
        #expect(dsaturColoring.chromaticNumber >= 2)
        #expect(dsaturColoring.chromaticNumber <= 3)
        
        // Test Welsh-Powell coloring
        let welshPowellColoring = graph.colorGraph(using: .welshPowell(on: graph))
        #expect(welshPowellColoring.isProper)
        #expect(welshPowellColoring.chromaticNumber >= 2)
        #expect(welshPowellColoring.chromaticNumber <= 3)
        
        // Test with a complete graph K4
        var k4Graph = AdjacencyList()
        let v1 = k4Graph.addVertex { $0.label = "V1" }
        let v2 = k4Graph.addVertex { $0.label = "V2" }
        let v3 = k4Graph.addVertex { $0.label = "V3" }
        let v4 = k4Graph.addVertex { $0.label = "V4" }
        
        // Add all possible edges
        let vertices = [v1, v2, v3, v4]
        for i in 0..<vertices.count {
            for j in (i+1)..<vertices.count {
                k4Graph.addEdge(from: vertices[i], to: vertices[j])
                k4Graph.addEdge(from: vertices[j], to: vertices[i])
            }
        }
        
        let k4Coloring = k4Graph.colorGraph(using: .greedy(on: k4Graph))
        #expect(k4Coloring.isProper)
        #expect(k4Coloring.chromaticNumber == 4) // Complete graph K4 needs exactly 4 colors
    }
}
