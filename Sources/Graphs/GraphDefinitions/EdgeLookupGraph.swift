protocol EdgeLookupGraph: Graph {
    func edge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor?
}

extension EdgeLookupGraph where Self: IncidenceGraph, VertexDescriptor: Equatable {
    func edge(from source: VertexDescriptor, to destination: VertexDescriptor) -> EdgeDescriptor? {
        for e in outgoingEdges(of: source) {
            if let v = self.destination(of: e), v == destination { return e }
        }
        return nil
    }
}


