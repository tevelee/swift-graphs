@testable import Graphs
import Testing

struct DOTFormatTests {
    @Test func emptyDirectedGraph() throws {
        let graph = AdjacencyList()
        let formatter = GraphFormatter()
        
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "EmptyGraph")
        )
        
        let expected = """
        digraph EmptyGraph {
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func emptyUndirectedGraph() throws {
        let graph = AdjacencyList()
        let formatter = GraphFormatter()
        
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: false, graphName: "UndirectedGraph")
        )
        
        let expected = """
        graph UndirectedGraph {
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func simpleDirectedGraphWithoutProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        let v3 = graph.addVertex()
        graph.addEdge(from: v1, to: v2)
        graph.addEdge(from: v2, to: v3)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "SimpleGraph")
        )
        
        let expected = """
        digraph SimpleGraph {
          v0;
          v1;
          v2;
          v0 -> v1;
          v1 -> v2;
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func simpleUndirectedGraphWithoutProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: false, graphName: "G")
        )
        
        let expected = """
        graph G {
          v0;
          v1;
          v0 -- v1;
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithVertexProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "A" }
        let v2 = graph.addVertex { $0.label = "B" }
        let v3 = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: v1, to: v2)
        graph.addEdge(from: v2, to: v3)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "WithProps"),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        digraph WithProps {
          v0 [Label="A"];
          v1 [Label="B"];
          v2 [Label="C"];
          v0 -> v1;
          v1 -> v2;
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithEdgeProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        graph.addEdge(from: v1, to: v2) { $0.weight = 5.0 }
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "EdgeProps"),
            edgeProperties: [Weight.self]
        )
        
        let expected = """
        digraph EdgeProps {
          v0;
          v1;
          v0 -> v1 [Weight="5.0"];
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithVertexAndEdgeProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "Start" }
        let v2 = graph.addVertex { $0.label = "End" }
        graph.addEdge(from: v1, to: v2) { 
            $0.label = "connects"
            $0.weight = 2.5
        }
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "BothProps"),
            vertexProperties: [Label.self],
            edgeProperties: [Label.self, Weight.self]
        )
        
        let expected = """
        digraph BothProps {
          v0 [Label="Start"];
          v1 [Label="End"];
          v0 -> v1 [Label="connects", Weight="2.5"];
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithSelectiveVertexProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { 
            $0.label = "A"
            $0.weight = 10.0
        }
        let v2 = graph.addVertex { 
            $0.label = "B"
            $0.weight = 20.0
        }
        graph.addEdge(from: v1, to: v2)
        
        // Only serialize label, not weight
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "Selective"),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        digraph Selective {
          v0 [Label="A"];
          v1 [Label="B"];
          v0 -> v1;
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithSelectiveEdgeProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        graph.addEdge(from: v1, to: v2) { 
            $0.label = "edge1"
            $0.weight = 3.0
        }
        
        // Only serialize weight, not label
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "EdgeSelective"),
            edgeProperties: [Weight.self]
        )
        
        let expected = """
        digraph EdgeSelective {
          v0;
          v1;
          v0 -> v1 [Weight="3.0"];
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func strictGraph() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "Strict", strict: true)
        )
        
        let expected = """
        strict digraph Strict {
          v0;
          v1;
          v0 -> v1;
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithAttributes() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(
                directed: true,
                graphName: "Styled",
                graphAttributes: ["rankdir": "LR", "bgcolor": "lightgray"],
                defaultNodeAttributes: ["shape": "box", "style": "filled"],
                defaultEdgeAttributes: ["color": "blue"]
            )
        )
        
        let expected = """
        digraph Styled {
          graph [bgcolor="lightgray", rankdir="LR"];
          node [shape="box", style="filled"];
          edge [color="blue"];
          v0;
          v1;
          v0 -> v1;
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func disconnectedGraph() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        let _ = graph.addVertex()  // v3 is disconnected
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "Disconnected")
        )
        
        let expected = """
        digraph Disconnected {
          v0;
          v1;
          v2;
          v0 -> v1;
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithSpecialCharactersInProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "Node \"A\"" }
        let v2 = graph.addVertex { $0.label = "Node\\B" }
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "Special"),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        digraph Special {
          v0 [Label="Node \\"A\\""];
          v1 [Label="Node\\\\B"];
          v0 -> v1;
        }
        """
        
        #expect(result == expected)
    }
    
    @Test func triangleGraph() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "A" }
        let v2 = graph.addVertex { $0.label = "B" }
        let v3 = graph.addVertex { $0.label = "C" }
        graph.addEdge(from: v1, to: v2)
        graph.addEdge(from: v2, to: v3)
        graph.addEdge(from: v3, to: v1)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .dot(directed: true, graphName: "Triangle"),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        digraph Triangle {
          v0 [Label="A"];
          v1 [Label="B"];
          v2 [Label="C"];
          v0 -> v1;
          v1 -> v2;
          v2 -> v0;
        }
        """
        
        #expect(result == expected)
    }
}
