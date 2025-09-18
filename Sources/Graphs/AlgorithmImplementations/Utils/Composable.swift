import Foundation

protocol Composable {
    associatedtype Other
    
    func combined(with other: Other) -> Self
}

extension Composable where Other == Self {
    func combined(with other: Self?) -> Self {
        if let other {
            combined(with: other)
        } else {
            self
        }
    }
}

extension Never: Composable {
    func combined(with other: Never) -> Never {}
}
