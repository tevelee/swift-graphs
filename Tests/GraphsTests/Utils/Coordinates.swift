import Foundation
import simd
@testable import Graphs

enum Coordinates2D: VertexProperty {
    static let defaultValue: SIMD2<Double> = .init(0, 0)
}

extension VertexPropertyValues {
    var coordinates: SIMD2<Double> {
        get { self[Coordinates2D.self] }
        set { self[Coordinates2D.self] = newValue }
    }
}


