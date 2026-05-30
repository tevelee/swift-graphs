#if !GRAPHS_USES_TRAITS || GRAPHS_SERIALIZATION
    import Foundation

    extension SerializationFormat {
        /// Creates a DOT (Graphviz) format with the specified options.
        ///
        /// - Parameters:
        ///   - directed: Whether the graph is directed (default: true)
        ///   - graphName: The name of the graph (default: "G")
        ///   - strict: Whether to use strict mode (default: false)
        ///   - graphAttributes: Custom graph-level attributes (default: empty)
        ///   - defaultNodeAttributes: Default node attributes (default: empty)
        ///   - defaultEdgeAttributes: Default edge attributes (default: empty)
        /// - Returns: A configured DOT format serializer
        public static func dot<G>(
            directed: Bool = true,
            graphName: String = "G",
            strict: Bool = false,
            graphAttributes: [String: String] = [:],
            defaultNodeAttributes: [String: String] = [:],
            defaultEdgeAttributes: [String: String] = [:]
        ) -> Self where Self == DOTFormat<G> {
            .init(
                directed: directed,
                graphName: graphName,
                strict: strict,
                graphAttributes: graphAttributes,
                defaultNodeAttributes: defaultNodeAttributes,
                defaultEdgeAttributes: defaultEdgeAttributes
            )
        }
    }

    /// A serialization format for Graphviz DOT files.
    ///
    /// The DOT format is a plain text graph description language used by Graphviz.
    /// It supports both directed and undirected graphs with various attributes.
    ///
    /// Example usage:
    /// ```swift
    /// let formatter = GraphFormatter()
    /// let dotString = try formatter.string(
    ///     from: graph,
    ///     using: .dot(directed: true, graphName: "MyGraph"),
    ///     vertexProperties: [Label.self],
    ///     edgeProperties: [Weight.self]
    /// )
    /// ```
    public struct DOTFormat<G: VertexListGraph & EdgeListGraph & IncidenceGraph>: SerializationFormat where G.VertexDescriptor: SerializableDescriptor {
        private let directed: Bool
        private let graphName: String
        private let strict: Bool
        private let graphAttributes: [String: String]
        private let defaultNodeAttributes: [String: String]
        private let defaultEdgeAttributes: [String: String]

        public init(
            directed: Bool = true,
            graphName: String = "G",
            strict: Bool = false,
            graphAttributes: [String: String] = [:],
            defaultNodeAttributes: [String: String] = [:],
            defaultEdgeAttributes: [String: String] = [:]
        ) {
            self.directed = directed
            self.graphName = graphName
            self.strict = strict
            self.graphAttributes = graphAttributes
            self.defaultNodeAttributes = defaultNodeAttributes
            self.defaultEdgeAttributes = defaultEdgeAttributes
        }

        public func serialize(_ graph: G) throws -> Data {
            var lines: [String] = []

            // Graph declaration
            let strictKeyword = strict ? "strict " : ""
            let graphType = directed ? "digraph" : "graph"
            let edgeOp = directed ? "->" : "--"
            lines.append("\(strictKeyword)\(graphType) \(graphName) {")

            // Graph attributes
            if !graphAttributes.isEmpty {
                let attrs = formatAttributes(graphAttributes)
                lines.append("  graph [\(attrs)];")
            }

            // Default node attributes
            if !defaultNodeAttributes.isEmpty {
                let attrs = formatAttributes(defaultNodeAttributes)
                lines.append("  node [\(attrs)];")
            }

            // Default edge attributes
            if !defaultEdgeAttributes.isEmpty {
                let attrs = formatAttributes(defaultEdgeAttributes)
                lines.append("  edge [\(attrs)];")
            }

            // Vertices
            for vertex in graph.vertices() {
                let id = vertexIdentifier(vertex)
                lines.append("  \(id);")
            }

            // Edges
            for edge in graph.edges() {
                guard let source = graph.source(of: edge),
                    let destination = graph.destination(of: edge)
                else {
                    throw SerializationError.missingDescriptorIdentifier
                }
                lines.append("  \(vertexIdentifier(source)) \(edgeOp) \(vertexIdentifier(destination));")
            }

            lines.append("}")

            let result = lines.joined(separator: "\n")
            guard let data = result.data(using: .utf8) else {
                throw SerializationError.encodingFailed(NSError(domain: "UTF8", code: -1))
            }
            return data
        }

        // MARK: - Private Helpers

        private func vertexIdentifier(_ vertex: G.VertexDescriptor) -> String {
            let id = vertex.serializedIdentifier
            // Escape if necessary
            if id.contains(" ") || id.contains("\"") || id.contains("\\") {
                let escaped =
                    id
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                return "\"\(escaped)\""
            }
            return id
        }

        private func formatAttributes(_ attrs: [String: String]) -> String {
            attrs.keys.sorted().map { key in
                let value = attrs[key]!
                let escapedValue =
                    value
                    .replacingOccurrences(of: "\\", with: "\\\\")
                    .replacingOccurrences(of: "\"", with: "\\\"")
                return "\(key)=\"\(escapedValue)\""
            }.joined(separator: ", ")
        }

    }

    extension DeserializationFormat {
        /// Creates a DOT (Graphviz) format for reading graphs back from DOT text.
        ///
        /// - Returns: A DOT deserialization format targeting graph type `G`.
        public static func dot<G>() -> Self where Self == DOTFormat<G> {
            .init()
        }
    }

    extension DOTFormat: DeserializationFormat where G: MutableGraph {
        /// Reconstructs a graph from DOT text produced by ``serialize(_:)``.
        ///
        /// Parses node statements (`a;`) and edge statements (`a -> b;` or `a -- b;`), including
        /// quoted identifiers containing spaces. Identifiers serve only as a correspondence map;
        /// the reconstructed graph assigns its own descriptors. Attribute blocks (`[…]`), default
        /// `graph`/`node`/`edge` statements, and comments are ignored.
        public func deserialize(_ data: Data, into graph: inout G) throws {
            guard let text = String(data: data, encoding: .utf8) else {
                throw SerializationError.invalidFormat("DOT input is not valid UTF-8")
            }
            guard let open = text.firstIndex(of: "{"), let close = text.lastIndex(of: "}"), open < close else {
                throw SerializationError.invalidFormat("DOT input missing a '{ … }' body")
            }
            let body = text[text.index(after: open) ..< close]

            var idMap: [String: G.VertexDescriptor] = [:]
            func vertex(for id: String) -> G.VertexDescriptor {
                if let existing = idMap[id] { return existing }
                let descriptor = graph.addVertex()
                idMap[id] = descriptor
                return descriptor
            }

            for rawStatement in body.split(separator: ";", omittingEmptySubsequences: true) {
                let statement = rawStatement.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !statement.isEmpty else { continue }
                // Skip default-attribute statements: graph […], node […], edge […]
                if let keyword = statement.split(separator: " ", maxSplits: 1).first,
                    keyword == "graph" || keyword == "node" || keyword == "edge"
                {
                    continue
                }
                let ids = Self.parseStatementIdentifiers(statement)
                guard !ids.isEmpty else { continue }
                if ids.count == 1 {
                    _ = vertex(for: ids[0])
                } else {
                    // Chains (a -> b -> c) connect consecutive identifiers.
                    for index in 0 ..< (ids.count - 1) {
                        _ = graph.addEdge(from: vertex(for: ids[index]), to: vertex(for: ids[index + 1]))
                    }
                }
            }
        }

        /// Extracts the vertex identifiers from a single DOT statement, unquoting as needed and
        /// stopping at any trailing attribute block (`[…]`). Edge operators (`->`, `--`) are skipped.
        @usableFromInline
        static func parseStatementIdentifiers(_ statement: String) -> [String] {
            var ids: [String] = []
            var chars = Array(statement)
            var i = 0
            while i < chars.count {
                let c = chars[i]
                if c == " " || c == "\t" || c == "\n" || c == "\r" {
                    i += 1
                } else if c == "[" {
                    break  // attribute block — ignore the rest of the statement
                } else if c == "-" && i + 1 < chars.count && (chars[i + 1] == ">" || chars[i + 1] == "-") {
                    i += 2  // edge operator
                } else if c == "\"" {
                    // quoted identifier with escape handling
                    var value = ""
                    i += 1
                    while i < chars.count {
                        let ch = chars[i]
                        if ch == "\\" && i + 1 < chars.count {
                            value.append(chars[i + 1])
                            i += 2
                        } else if ch == "\"" {
                            i += 1
                            break
                        } else {
                            value.append(ch)
                            i += 1
                        }
                    }
                    ids.append(value)
                } else {
                    // bare identifier
                    var value = ""
                    while i < chars.count {
                        let ch = chars[i]
                        if ch == " " || ch == "\t" || ch == "\n" || ch == "\r" || ch == "[" || ch == "\"" {
                            break
                        }
                        if ch == "-" && i + 1 < chars.count && (chars[i + 1] == ">" || chars[i + 1] == "-") {
                            break
                        }
                        value.append(ch)
                        i += 1
                    }
                    if !value.isEmpty { ids.append(value) }
                }
            }
            return ids
        }
    }

    extension DOTFormat: PropertySerializationFormat where G: PropertyGraph, G: IncidenceGraph {
        public func serialize(
            _ graph: G,
            vertexProperties: [any GraphProperty.Type],
            edgeProperties: [any GraphProperty.Type]
        ) throws -> Data {
            var lines: [String] = []

            // Graph declaration
            let strictKeyword = strict ? "strict " : ""
            let graphType = directed ? "digraph" : "graph"
            let edgeOp = directed ? "->" : "--"
            lines.append("\(strictKeyword)\(graphType) \(graphName) {")

            // Graph attributes
            if !graphAttributes.isEmpty {
                let attrs = formatAttributes(graphAttributes)
                lines.append("  graph [\(attrs)];")
            }

            // Default node attributes
            if !defaultNodeAttributes.isEmpty {
                let attrs = formatAttributes(defaultNodeAttributes)
                lines.append("  node [\(attrs)];")
            }

            // Default edge attributes
            if !defaultEdgeAttributes.isEmpty {
                let attrs = formatAttributes(defaultEdgeAttributes)
                lines.append("  edge [\(attrs)];")
            }

            // Vertices
            for vertex in graph.vertices() {
                let id = vertexIdentifier(vertex)
                let attributes = extractVertexProperties(
                    from: graph,
                    vertex: vertex,
                    propertyTypes: vertexProperties
                )

                if attributes.isEmpty {
                    lines.append("  \(id);")
                } else {
                    let attrs = formatAttributes(attributes)
                    lines.append("  \(id) [\(attrs)];")
                }
            }

            // Edges
            for edge in graph.edges() {
                guard let source = graph.source(of: edge),
                    let destination = graph.destination(of: edge)
                else {
                    throw SerializationError.missingDescriptorIdentifier
                }

                let sourceId = vertexIdentifier(source)
                let destinationId = vertexIdentifier(destination)
                let attributes = extractEdgeProperties(
                    from: graph,
                    edge: edge,
                    propertyTypes: edgeProperties
                )

                if attributes.isEmpty {
                    lines.append("  \(sourceId) \(edgeOp) \(destinationId);")
                } else {
                    let attrs = formatAttributes(attributes)
                    lines.append("  \(sourceId) \(edgeOp) \(destinationId) [\(attrs)];")
                }
            }

            lines.append("}")

            let result = lines.joined(separator: "\n")
            guard let data = result.data(using: .utf8) else {
                throw SerializationError.encodingFailed(NSError(domain: "UTF8", code: -1))
            }
            return data
        }

        private func extractVertexProperties(
            from graph: G,
            vertex: G.VertexDescriptor,
            propertyTypes: [any GraphProperty.Type]
        ) -> [String: String] {
            guard !propertyTypes.isEmpty else { return [:] }

            var result: [String: String] = [:]
            let propertyMap = graph.vertexPropertyMap
            let props = propertyMap[vertex]

            for propertyType in propertyTypes {
                let typeName = "\(propertyType)"
                if let prop = propertyType as? any VertexProperty.Type {
                    result[typeName] = "\(props[prop])"
                }
            }

            return result
        }

        private func extractEdgeProperties(
            from graph: G,
            edge: G.EdgeDescriptor,
            propertyTypes: [any GraphProperty.Type]
        ) -> [String: String] {
            guard !propertyTypes.isEmpty else { return [:] }

            var result: [String: String] = [:]
            let propertyMap = graph.edgePropertyMap
            let props = propertyMap[edge]

            for propertyType in propertyTypes {
                let typeName = "\(propertyType)"
                if let prop = propertyType as? any EdgeProperty.Type {
                    result[typeName] = "\(props[prop])"
                }
            }

            return result
        }
    }
#endif
