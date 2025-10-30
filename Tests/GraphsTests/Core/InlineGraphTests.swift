@testable import Graphs
import Testing

struct InlineGraphTests {
    @Test func createsEmptyGraph() {
        let graph = InlineGraph<String, SimpleEdge<String>>()
        
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }
    
    @Test func createsEmptyGraphWithConvenienceInitializer() {
        let graph: InlineGraph<String, SimpleEdge<String>> = InlineGraph()
        
        #expect(graph.vertexCount == 0)
        #expect(graph.edgeCount == 0)
    }
    
    @Test func addsVerticesAndEdges() {
        var graph: InlineGraph<String, SimpleEdge<String>> = InlineGraph()
        
        graph.addVertex("A")
        graph.addVertex("B")
        graph.addVertex("C")
        
        #expect(graph.vertexCount == 3)
        
        graph.addEdge(from: "A", to: "B")
        graph.addEdge(from: "B", to: "C")
        graph.addEdge(from: "A", to: "C")
        
        #expect(graph.edgeCount == 3)
        #expect(graph.outDegree(of: "A") == 2)
        #expect(graph.outDegree(of: "B") == 1)
        #expect(graph.outDegree(of: "C") == 0)
    }
    
    @Test func initializesFromEdgePairs() {
        let graph = InlineGraph(edges: [
            ("A", "B"),
            ("B", "C"),
            ("C", "D"),
            ("A", "D")
        ])
        
        #expect(graph.vertexCount == 4)
        #expect(graph.edgeCount == 4)
        #expect(graph.outDegree(of: "A") == 2)
    }
    
    @Test func initializesFromSimpleEdges() {
        let edges = [
            SimpleEdge(source: 1, destination: 2),
            SimpleEdge(source: 2, destination: 3),
            SimpleEdge(source: 3, destination: 1)
        ]
        
        let graph = InlineGraph(edges: edges)
        
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
    }
    
    @Test func worksWithCustomEdgeType() {
        struct WeightedEdge: EdgeProtocol, Equatable {
            let source: Int
            let destination: Int
            let weight: Double
        }
        
        var graph = InlineGraph<Int, WeightedEdge>()
        
        graph.addEdge(WeightedEdge(source: 1, destination: 2, weight: 5.0))
        graph.addEdge(WeightedEdge(source: 2, destination: 3, weight: 3.5))
        graph.addEdge(WeightedEdge(source: 1, destination: 3, weight: 8.0))
        
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
        
        let edgesFrom1 = graph.outgoingEdges(of: 1)
        #expect(edgesFrom1.count == 2)
        #expect(edgesFrom1.allSatisfy { $0.source == 1 })
    }
    
    @Test func adjacentVerticesReturnsCorrectNeighbors() {
        var graph = InlineGraph<String, SimpleEdge<String>>()
        
        graph.addEdge(from: "A", to: "B")
        graph.addEdge(from: "A", to: "C")
        graph.addEdge(from: "A", to: "D")
        
        let neighbors = Array(graph.adjacentVertices(of: "A"))
        #expect(neighbors.count == 3)
        #expect(Set(neighbors) == Set(["B", "C", "D"]))
    }
    
    @Test func removesVertex() {
        var graph = InlineGraph<String, SimpleEdge<String>>()
        
        graph.addEdge(from: "A", to: "B")
        graph.addEdge(from: "B", to: "C")
        graph.addEdge(from: "A", to: "C")
        
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 3)
        
        graph.remove(vertex: "B")
        
        #expect(graph.vertexCount == 2)
        // Should remove edge from A to B, and edge from B to C
        #expect(graph.edgeCount == 1)
        #expect(graph.outDegree(of: "A") == 1)
    }
    
    @Test func removesEdge() {
        var graph = InlineGraph<String, SimpleEdge<String>>()
        
        let edge1 = graph.addEdge(from: "A", to: "B")
        graph.addEdge(from: "A", to: "C")
        
        #expect(graph.edgeCount == 2)
        
        graph.remove(edge: edge1)
        
        #expect(graph.edgeCount == 1)
        #expect(graph.outDegree(of: "A") == 1)
        
        let remainingEdges = graph.outgoingEdges(of: "A")
        #expect(remainingEdges.first?.destination == "C")
    }
    
    @Test func handlesIsolatedVertices() {
        var graph = InlineGraph<String, SimpleEdge<String>>()
        
        graph.addVertex("Isolated")
        graph.addEdge(from: "A", to: "B")
        
        #expect(graph.vertexCount == 3)
        #expect(graph.edgeCount == 1)
        #expect(graph.outDegree(of: "Isolated") == 0)
    }
    
    @Test func sourceAndDestinationAccessors() {
        var graph = InlineGraph<String, SimpleEdge<String>>()
        
        let edge = graph.addEdge(from: "X", to: "Y")
        
        #expect(graph.source(of: edge) == "X")
        #expect(graph.destination(of: edge) == "Y")
    }
    
    @Test func edgesEnumerationIncludesAllEdges() {
        var graph = InlineGraph<Int, SimpleEdge<Int>>()
        
        graph.addEdge(from: 1, to: 2)
        graph.addEdge(from: 2, to: 3)
        graph.addEdge(from: 1, to: 3)
        graph.addEdge(from: 3, to: 1)
        
        let allEdges = graph.edges()
        #expect(allEdges.count == 4)
        
        let sources = Set(allEdges.map { $0.source })
        #expect(sources == Set([1, 2, 3]))
    }
    
    @Test func verticesEnumerationIncludesAllVertices() {
        let graph = InlineGraph(edges: [
            (1, 2),
            (2, 3),
            (3, 4),
            (4, 1)
        ])
        
        let allVertices = Set(graph.vertices())
        #expect(allVertices == Set([1, 2, 3, 4]))
    }
}

