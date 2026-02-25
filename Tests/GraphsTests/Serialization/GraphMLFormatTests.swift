#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
@testable import Graphs
import Testing
import Foundation

struct GraphMLFormatTests {
    @Test func emptyGraphWithoutSchema() throws {
        let graph = AdjacencyList()
        let formatter = GraphFormatter()
        
        let result = try formatter.string(
            from: graph,
            using: .graphML(directed: true, includeSchema: false)
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml>
          <graph edgedefault="directed">
          </graph>
        </graphml>
        """
        
        #expect(result == expected)
    }
    
    @Test func emptyGraphWithSchema() throws {
        let graph = AdjacencyList()
        let formatter = GraphFormatter()
        
        let result = try formatter.string(
            from: graph,
            using: .graphML(directed: true, includeSchema: true)
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml xmlns="http://graphml.graphdrawing.org/xmlns" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://graphml.graphdrawing.org/xmlns http://graphml.graphdrawing.org/xmlns/1.0/graphml.xsd">
          <graph edgedefault="directed">
          </graph>
        </graphml>
        """
        
        #expect(result == expected)
    }
    
    @Test func simpleGraphWithoutProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .graphML(directed: true, includeSchema: false)
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml>
          <graph edgedefault="directed">
            <node id="v0"/>
            <node id="v1"/>
            <edge source="v0" target="v1"/>
          </graph>
        </graphml>
        """
        
        #expect(result == expected)
    }
    
    @Test func undirectedGraph() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex()
        let v2 = graph.addVertex()
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .graphML(directed: false, includeSchema: false)
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml>
          <graph edgedefault="undirected">
            <node id="v0"/>
            <node id="v1"/>
            <edge source="v0" target="v1"/>
          </graph>
        </graphml>
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithVertexProperties() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "A" }
        let v2 = graph.addVertex { $0.label = "B" }
        graph.addEdge(from: v1, to: v2)
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .graphML(directed: true, includeSchema: false),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml>
          <graph edgedefault="directed">
            <key id="d0" for="node" attr.name="Label" attr.type="string"/>
            <node id="v0">
              <data key="d0">A</data>
            </node>
            <node id="v1">
              <data key="d0">B</data>
            </node>
            <edge source="v0" target="v1">
            </edge>
          </graph>
        </graphml>
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
            using: .graphML(directed: true, includeSchema: false),
            edgeProperties: [Weight.self]
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml>
          <graph edgedefault="directed">
            <key id="d0" for="edge" attr.name="Weight" attr.type="string"/>
            <node id="v0">
            </node>
            <node id="v1">
            </node>
            <edge source="v0" target="v1">
              <data key="d0">5.0</data>
            </edge>
          </graph>
        </graphml>
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithBothProperties() throws {
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
            using: .graphML(directed: true, includeSchema: false),
            vertexProperties: [Label.self],
            edgeProperties: [Label.self, Weight.self]
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml>
          <graph edgedefault="directed">
            <key id="d0" for="node" attr.name="Label" attr.type="string"/>
            <key id="d0" for="edge" attr.name="Label" attr.type="string"/>
            <key id="d1" for="edge" attr.name="Weight" attr.type="string"/>
            <node id="v0">
              <data key="d0">Start</data>
            </node>
            <node id="v1">
              <data key="d0">End</data>
            </node>
            <edge source="v0" target="v1">
              <data key="d0">connects</data>
              <data key="d1">2.5</data>
            </edge>
          </graph>
        </graphml>
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
        
        let formatter = GraphFormatter()
        // Only serialize label, not weight
        let result = try formatter.string(
            from: graph,
            using: .graphML(directed: true, includeSchema: false),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml>
          <graph edgedefault="directed">
            <key id="d0" for="node" attr.name="Label" attr.type="string"/>
            <node id="v0">
              <data key="d0">A</data>
            </node>
            <node id="v1">
              <data key="d0">B</data>
            </node>
            <edge source="v0" target="v1">
            </edge>
          </graph>
        </graphml>
        """
        
        #expect(result == expected)
    }
    
    @Test func graphWithXMLSpecialCharacters() throws {
        var graph = AdjacencyList()
        let v1 = graph.addVertex { $0.label = "A & B" }
        let v2 = graph.addVertex { $0.label = "X < Y" }
        graph.addEdge(from: v1, to: v2) { $0.label = "quote\"test" }
        
        let formatter = GraphFormatter()
        let result = try formatter.string(
            from: graph,
            using: .graphML(directed: true, includeSchema: false),
            vertexProperties: [Label.self],
            edgeProperties: [Label.self]
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml>
          <graph edgedefault="directed">
            <key id="d0" for="node" attr.name="Label" attr.type="string"/>
            <key id="d0" for="edge" attr.name="Label" attr.type="string"/>
            <node id="v0">
              <data key="d0">A &amp; B</data>
            </node>
            <node id="v1">
              <data key="d0">X &lt; Y</data>
            </node>
            <edge source="v0" target="v1">
              <data key="d0">quote&quot;test</data>
            </edge>
          </graph>
        </graphml>
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
            using: .graphML(directed: true, includeSchema: false)
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml>
          <graph edgedefault="directed">
            <node id="v0"/>
            <node id="v1"/>
            <node id="v2"/>
            <edge source="v0" target="v1"/>
          </graph>
        </graphml>
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
            using: .graphML(directed: true, includeSchema: false),
            vertexProperties: [Label.self]
        )
        
        let expected = """
        <?xml version="1.0" encoding="UTF-8"?>
        <graphml>
          <graph edgedefault="directed">
            <key id="d0" for="node" attr.name="Label" attr.type="string"/>
            <node id="v0">
              <data key="d0">A</data>
            </node>
            <node id="v1">
              <data key="d0">B</data>
            </node>
            <node id="v2">
              <data key="d0">C</data>
            </node>
            <edge source="v0" target="v1">
            </edge>
            <edge source="v1" target="v2">
            </edge>
            <edge source="v2" target="v0">
            </edge>
          </graph>
        </graphml>
        """
        
        #expect(result == expected)
    }
}
#endif
