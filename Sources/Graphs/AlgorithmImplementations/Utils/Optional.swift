extension Optional {
    @inlinable
    public func unwrap(orReport message: String, file: StaticString = #file, line: UInt = #line) -> Wrapped {
        guard let self else {
            preconditionFailure(message, file: file, line: line)
        }
        return self
    }
}
