public enum Width : RawRepresentable, Equatable, Hashable, ExpressibleByIntegerLiteral {
    
    public var rawValue: Int {
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

    public init?(rawValue: Int) {
        let allowedRange = 0...Int16.max
        if rawValue == -2 {
            self = .auto
        }
        else if rawValue == -1 {
            self = .hidden
        }
        else if let i16 = Int16(exactly: rawValue),
                allowedRange.contains(i16) {
            self = .value(rawValue)
        }
        else {
            fatalError("\(Self.self) value must be in range \(allowedRange) or .auto or .hidden (\(rawValue) was given)")
        }
    }

    public init(integerLiteral value: IntegerLiteralType) {
        precondition(value >= 0)
        self = .value(value)
    }

    public init(range value:Range<RawValue>) {
        precondition(value.lowerBound >= 0)
        self = .range(value)
    }
    
    public init(range value:ClosedRange<RawValue>) {
        precondition(value.lowerBound >= 0)
        precondition(value.upperBound < RawValue.max)
        if value.lowerBound == value.upperBound {
            self = .value(value.lowerBound)
        }
        else {
            self = .in(value)
        }
    }
    
    public typealias RawValue = Int
    public typealias IntegerLiteralType = RawValue
    case auto, hidden, value(RawValue), min(RawValue), max(RawValue), range(Range<RawValue>), `in`(ClosedRange<RawValue>)
}
