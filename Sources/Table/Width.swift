
public enum Width : RawRepresentable, Equatable, Hashable, Comparable, ExpressibleByIntegerLiteral {
    public init?(rawValue: Int) {
        let allowedRange = 1...Int16.max
        if rawValue == -1 {
            self = .auto
        }
        else if rawValue == 0 {
            self = .hidden
        }
        else if let i16 = Int16(exactly: rawValue),
                allowedRange.contains(i16) {
            self = .value(rawValue)
        }
        else {
            fatalError("\(Self.self) must be in range \(allowedRange) or .auto or .hidden")
        }
    }

    public var rawValue: Int {
        switch self {
        case .auto: return -1
        case .hidden: return 0
        case let .value(i): return i
        }
    }

    public init(integerLiteral value: RawValue) {
        self = Width(rawValue: value)!
//        self = .value(Swift.min(Int(Int16.max), value))
    }

    public typealias RawValue = Int
    public typealias IntegerLiteralType = RawValue
    case auto, hidden, value(Int)
}
