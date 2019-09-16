public enum Scaling: Hashable {
    case linear(_ range: ClosedRange<Float>)
    case stepped([ClosedRange<Float>: ClosedRange<Float>])

    public var inputLowerBound: Float {
        switch self {
        case let .linear(range):
            return range.lowerBound
        case let .stepped(boundries):
            return boundries.keys.lazy.map { $0.lowerBound }.sorted(by: <).first ?? 0
        }
    }

    public var inputUpperBound: Float {
        switch self {
        case let .linear(range):
            return range.upperBound
        case let .stepped(boundries):
            return boundries.keys.lazy.map { $0.upperBound }.sorted(by: >).first ?? 0
        }
    }

    public var outputLowerBound: Float {
        switch self {
        case let .linear(range):
            return range.lowerBound
        case let .stepped(boundries):
            return boundries.values.lazy.map { $0.lowerBound }.sorted(by: <).first ?? 0
        }
    }

    public var outputUpperBound: Float {
        switch self {
        case let .linear(range):
            return range.upperBound
        case let .stepped(boundries):
            return boundries.values.lazy.map { $0.upperBound }.sorted(by: >).first ?? 0
        }
    }
}
