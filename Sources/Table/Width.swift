public enum Width : Equatable, Hashable, ExpressibleByIntegerLiteral, Codable {

    private static let allowedRange = 0...Int(Int16.max)

    public var value: Int {
        let retval:Int
        switch self {
        case .in: retval = -6
        case .range: retval = -5
        case .max(let m): retval = m
        case .min(let m): retval = m
        case .auto: retval = -2
        case .hidden: retval = -1
        case .value(let i): retval = i
        }
        guard Self.allowedRange.contains(retval) || [-6, -5, -2, -1].contains(retval) else {
            fatalError("Width out of bounds (\(retval)), allowed range \(Self.allowedRange)")
        }
        return retval
    }

    public init(_ value: Int) {
        if value == -2 {
            self = .auto
        }
        else if value == -1 {
            self = .hidden
        }
        else if value < 0 {
            fatalError("\(Self.self) min, max, in or range can not be initialized with \(#function)")
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
