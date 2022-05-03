
public enum Width : RawRepresentable, Equatable, Hashable, Comparable, ExpressibleByIntegerLiteral {
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

    public var rawValue: Int {
        switch self {
        case .auto: return -2
        case .hidden: return -1
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
