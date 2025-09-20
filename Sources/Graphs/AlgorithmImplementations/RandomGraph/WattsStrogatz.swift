import Foundation

struct WattsStrogatz<
    Graph: MutableGraph
> where Graph.VertexDescriptor: Hashable {
    typealias Vertex = Graph.VertexDescriptor
    
    struct Visitor {
        var addVertex: ((Vertex) -> Void)?
        var addEdge: ((Vertex, Vertex) -> Void)?
        var rewireEdge: ((Vertex, Vertex, Vertex) -> Void)?
        var skipRewiring: ((Vertex, Vertex, String) -> Void)?
        var createRingLattice: ((Vertex, Vertex) -> Void)?
    }
    
    struct Result {
        let graph: Graph
        let vertices: [Vertex]
        let initialEdges: [(Vertex, Vertex)]
        let rewiredEdges: [(Vertex, Vertex)]
        let rewiringProbability: Double
    }
    
    let averageDegree: Double
    let rewiringProbability: Double
    
    init(averageDegree: Double, rewiringProbability: Double) {
        self.averageDegree = averageDegree
        self.rewiringProbability = rewiringProbability
    }
    
    func appendRandomGraph<RNG: RandomNumberGenerator>(
        into graph: inout Graph,
        vertexCount: Int,
        using generator: inout RNG,
        visitor: Visitor? = nil
    ) {
        guard vertexCount > 0 else { return }
        
        // Add vertices
        var vertices: [Vertex] = []
        for _ in 0..<vertexCount {
            let vertex = graph.addVertex()
            visitor?.addVertex?(vertex)
            vertices.append(vertex)
        }
        
        // Create initial regular ring lattice
        let k = Int(averageDegree) / 2
        var initialEdges: [(Vertex, Vertex)] = []
        for i in 0..<vertexCount {
            for j in 1...max(0, k) {
                let targetIndex = (i + j) % vertexCount
                let source = vertices[i]
                let target = vertices[targetIndex]
                graph.addEdge(from: source, to: target)
                visitor?.createRingLattice?(source, target)
                initialEdges.append((source, target))
            }
        }
        
        // Rewire edges with probability p
        for edge in initialEdges {
            if Double.random(in: 0...1, using: &generator) < rewiringProbability {
                let source = edge.0
                if let randomTarget = vertices.randomElement(using: &generator), randomTarget != source {
                    graph.addEdge(from: source, to: randomTarget)
                    visitor?.rewireEdge?(source, edge.1, randomTarget)
                } else {
                    visitor?.skipRewiring?(source, edge.1, "Self-loop avoided or no target")
                }
            } else {
                visitor?.skipRewiring?(edge.0, edge.1, "Probability check failed")
            }
        }
    }
}

extension WattsStrogatz: VisitorSupporting {}
