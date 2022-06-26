public enum Width : Equatable, Hashable, ExpressibleByIntegerLiteral {

    private static let allowedRange = 0...Int(Int16.max)

    public var value: Int {
        switch self {
        case .in: return -6
        case .range: return -5
        case .max: return -4
        case .min: return -3
        case .auto: return -2
        case .hidden: return -1
        case let .value(i): return i
        }
    }

    public init(_ value: Int) {
        if value == -2 {
            self = .auto
        }
        else if value == -1 {
            self = .hidden
        }
        else {
            precondition(Self.allowedRange.contains(value),
                         "\(Self.self) value must be in the range \(Self.allowedRange) or .auto or .hidden (\(value) was given)")
            self = .value(value)
        }
    }
    public init(integerLiteral value: IntegerLiteralType) {
        precondition(value >= 0)
        self.init(value)
    }

    public init(range value:Range<Int>) {
        precondition(value.lowerBound >= 0)
        precondition(Int(Self.allowedRange.upperBound) >= value.upperBound)
        if value.lowerBound.distance(to: value.upperBound) == 1 {
            self = .value(value.lowerBound)
        }
        else {
            self = .range(value)
        }
    }
    
    public init(range value:ClosedRange<Int>) {
        precondition(value.lowerBound >= 0)
        precondition(value.upperBound < Int.max)
        if value.lowerBound == value.upperBound {
            self = .value(value.lowerBound)
        }
        else {
            self = .in(value)
        }
    }
    
    public typealias IntegerLiteralType = Int
    case auto, hidden, value(Int), min(Int), max(Int), range(Range<Int>), `in`(ClosedRange<Int>)
}
