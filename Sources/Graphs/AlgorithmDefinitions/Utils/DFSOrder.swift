/// A configuration for depth-first search traversal order.
///
/// DFSOrder allows customizing the order in which vertices are visited during
/// depth-first search traversal. This is useful for implementing different
/// traversal strategies like preorder, postorder, and inorder.
public struct DFSOrder<Graph: IncidenceGraph> where Graph.VertexDescriptor: Hashable {
    @usableFromInline
    let makeObservation: (Graph, SharedBuffer<Graph.VertexDescriptor>) -> AlgorithmObservation<DepthFirstSearch<Graph>.Event>

    @inlinable
    public init(
        makeObservation: @escaping (Graph, SharedBuffer<Graph.VertexDescriptor>) -> AlgorithmObservation<DepthFirstSearch<Graph>.Event>
    ) {
        self.makeObservation = makeObservation
    }
}

public final class SharedBuffer<Element> {
    public var elements: [Element] = []

    @inlinable
    public init() {}

    public func append(_ element: Element) {
        elements.append(element)
    }
}

extension DFSOrder {
    @inlinable
    public static var preorder: DFSOrder {
        DFSOrder { _, buffer in
            .init { event in
                if case .vertexDiscovered(let vertex) = event {
                    buffer.append(vertex)
                }
            }
        }
    }

    @inlinable
    public static var postorder: DFSOrder {
        DFSOrder { _, buffer in
            .init { event in
                if case .vertexFinished(let vertex) = event {
                    buffer.append(vertex)
                }
            }
        }
    }
}

extension DFSOrder where Graph: BinaryIncidenceGraph {
    @inlinable
    public static var inorder: DFSOrder {
        DFSOrder { graph, buffer in
            var emitted = Set<Graph.VertexDescriptor>()
            var parent: [Graph.VertexDescriptor: Graph.VertexDescriptor] = [:]

            func emit(_ v: Graph.VertexDescriptor) {
                if emitted.insert(v).inserted {
                    buffer.append(v)
                }
            }

            return .init { event in
                switch event {
                    case .vertexDiscovered(let vertex):
                        if graph.leftNeighbor(of: vertex) == nil {
                            emit(vertex)
                        }
                    case .treeEdgeTraversed(let edge):
                        if let parentVertex = graph.source(of: edge),
                            let child = graph.destination(of: edge)
                        {
                            parent[child] = parentVertex
                        }
                    case .vertexFinished(let vertex):
                        if let parentVertex = parent[vertex],
                            let leftChild = graph.leftNeighbor(of: parentVertex),
                            leftChild == vertex
                        {
                            emit(parentVertex)
                        }
                    default:
                        break
                }
            }
        }
    }
}
