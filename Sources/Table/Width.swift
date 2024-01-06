/// Concrete type for expressing static and dynamic widths for table columns

public enum Width : Equatable, Hashable, ExpressibleByIntegerLiteral, Codable, CaseIterable {
    public static var allCases: [Width] {
        return [.auto, .hidden, .collapsed, .fixed(0), .min(0), .max(0), .in(0...0), .range(0..<0)]
    }
    
    // NOTE: This is propably the weirdest
    // implementation possible -> should be re-worked
    internal static let allowedRange:ClosedRange<Int> = 0...1024

    public typealias IntegerLiteralType = Int
    /// Indicates that column width should be calculated dynamically
    /// based on cell data.
    case auto
    /// Indicates that column should be hidden (not visible at all).
    ///
    /// - Note: See also `value`.
    case hidden
    /// Collapsed column.
    ///
    /// Collapsed column is an empty column which is visible on
    /// the table, but it doesn't contain any cell data as it's width
    /// is set to 0. Also the column header (if set) is collapsed and
    /// not shown.
    ///
    /// Synonym for `.fixed(0)`
    ///
    /// Example table with collapsed column between first and
    /// last columns.
    /// ```
    /// +-------------+
    /// |  Olympics   |
    /// +----++-------+
    /// |Year||Country|
    /// +----++-------+
    /// |1952||Finland|
    /// +----++-------+
    /// |1956||Sweden |
    /// +----++-------+
    /// |1960||Italy  |
    /// +----++-------+
    /// ```
    case collapsed
    /// Fixed table column width.
    ///
    /// - Note: See also `hidden`. The difference between
    /// `.value(0)` and `.hidden` is that table column
    /// with width `.value(0)` will be visually present in the table,
    /// whereas `.hidden` columns are not.
    case fixed(Int)
    /// Indicates that column width must be at least given value
    /// (can be wider).
    case min(Int)
    /// Indicates that column must not exceed given value
    /// (can be smaller).
    case max(Int)
    /// Indicates that column width must be in the specified range.
    case range(Range<Int>)
    /// Indicates that column width must be in the specified closed range.
    case `in`(ClosedRange<Int>)

    /// Is column visible.
    public var isVisible:Bool {
        self == .hidden ? false : true
    }

    public init(_ value: Int) {
        precondition(Self.allowedRange.contains(value),
                     "\(#function): value must be in range \(Self.allowedRange)")
        self = .fixed(value)
    }

    public init(integerLiteral value: IntegerLiteralType) {
        self.init(value)
    }

    public init(range value:Range<Int>) {
        precondition(Self.allowedRange.contains(value.lowerBound) &&
                     Self.allowedRange.contains(value.upperBound),
                     "range must be in range \(Self.allowedRange)")
        if value.lowerBound.distance(to: value.upperBound) == 1 {
            self = .fixed(value.lowerBound)
        }
        else {
            self = .range(value)
        }
    }

    public init(range value:ClosedRange<Int>) {
        precondition(Self.allowedRange.contains(value.lowerBound) &&
                     Self.allowedRange.contains(value.upperBound),
                     "closed range must be in range \(Self.allowedRange)")
        if value.lowerBound == value.upperBound {
            self = .fixed(value.lowerBound)
        }
        else {
            self = .in(value)
        }
    }
}
extension Width : CustomStringConvertible {
    public var description: String {
        switch self {
        case .auto:
            return "auto"
        case .hidden:
            return "hidden"
        case .collapsed:
            return "collapsed"
        case .fixed:
            return "fixed"
        case .min:
            return "min"
        case .max:
            return "max"
        case .range:
            return "range"
        case .in:
            return "in"
        }
    }
}
extension Width : CustomDebugStringConvertible {
    public var debugDescription: String {
        switch self {
        case .auto:
            return "auto"
        case .hidden:
            return "hidden"
        case .collapsed:
            return "collapsed"
        case .fixed(let int):
            return "fixed(\(int))"
        case .min(let int):
            return "min(\(int))"
        case .max(let int):
            return "max(\(int))"
        case .range(let range):
            return "range(\(range))"
        case .in(let closedRange):
            return "in(\(closedRange))"
        }
    }
}
extension Width {
    public func value(limitedBy:Int) -> Int {
        // Actual column width
        let fixed:Int
        switch self {
        case .min(let min):
            fixed = Swift.max(min, limitedBy)
        case .max(let max):
            fixed = Swift.min(max, limitedBy)
        case .in(let closedRange):
            fixed = Swift.max(Swift.min(closedRange.upperBound, limitedBy), closedRange.lowerBound)
        case .range( let range):
            fixed = Swift.max(Swift.min(range.upperBound - 1, limitedBy), range.lowerBound)
        case .auto:
            fixed = Swift.max(0, limitedBy)
        case .fixed(let v):
            fixed = v
        case .collapsed:
            fixed = 0
        case .hidden:
            fixed = 0
        }
        return fixed
    }
}
