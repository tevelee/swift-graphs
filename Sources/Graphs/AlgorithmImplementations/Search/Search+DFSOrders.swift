extension SearchAlgorithm {
    static func dfs<Graph>(order: DFSOrder<Graph>) -> Self where Self == DFSOrderedSearch<Graph> {
        .init(order: order)
    }
}

struct DFSOrderedSearch<Graph: IncidenceGraph>: SearchAlgorithm where Graph.VertexDescriptor: Hashable {
    let order: DFSOrder<Graph>
    
    func search(
        from source: Graph.VertexDescriptor,
        in graph: Graph,
        visitor: DepthFirstSearch<Graph>.Visitor?
    ) -> AnySequence<Graph.VertexDescriptor> {
        let base = DepthFirstSearch(on: graph, from: source)
        return AnySequence {
            let buffer = SharedBuffer<Graph.VertexDescriptor>()
            var iterator = base.makeIterator(visitor: order.makeVisitor(graph, buffer).combined(with: visitor))
            return AnyIterator {
                if !buffer.elements.isEmpty {
                    return buffer.elements.removeFirst()
                }
                while iterator.next() != nil {
                    if !buffer.elements.isEmpty {
                        return buffer.elements.removeFirst()
                    }
                }
                return nil
            }
        }
    }
}
