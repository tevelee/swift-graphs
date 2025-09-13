extension IncidenceGraph where Self: VertexListGraph, VertexDescriptor: Hashable {
    func hamiltonianPath(
        using algorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianPath(in: self)
    }
    
    func hamiltonianCycle(
        using algorithm: some HamiltonianCycleAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianCycle(in: self)
    }
    
    func hamiltonianPath(
        from source: VertexDescriptor,
        using algorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianPath(from: source, in: self)
    }
    
    func hamiltonianPath(
        from source: VertexDescriptor,
        to destination: VertexDescriptor,
        using algorithm: some HamiltonianPathAlgorithm<Self>
    ) -> Path<VertexDescriptor, EdgeDescriptor>? {
        algorithm.hamiltonianPath(from: source, to: destination, in: self)
    }
}

protocol HamiltonianPathAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    
    func hamiltonianPath(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
    func hamiltonianPath(from source: Graph.VertexDescriptor, in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
    func hamiltonianPath(from source: Graph.VertexDescriptor, to destination: Graph.VertexDescriptor, in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}

protocol HamiltonianCycleAlgorithm<Graph> {
    associatedtype Graph: IncidenceGraph & VertexListGraph where Graph.VertexDescriptor: Hashable
    
    func hamiltonianCycle(in graph: Graph) -> Path<Graph.VertexDescriptor, Graph.EdgeDescriptor>?
}
