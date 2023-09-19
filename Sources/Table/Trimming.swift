/// Text trimming options
///
/// Defines generic trimming options.

public struct TrimmingOptions : OptionSet, CaseIterable, CustomStringConvertible, Hashable, Comparable, Codable {
    enum Opts : Int, CaseIterable {
        case leadingWhiteSpaces
        case leadingNewlines
        case inlineConsecutiveWhiteSpaces
        case inlineConsecutiveNewlines
        case trailingWhiteSpaces
        case trailingNewlines
    }
    public static var allCases: [TrimmingOptions] = Opts.allCases
        .filter({ $0.rawValue < (MemoryLayout<Int>.size * 8)})
        .map { TrimmingOptions(rawValue: 1 << $0.rawValue) }
    public static func < (lhs: TrimmingOptions, rhs: TrimmingOptions) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    public let rawValue: Int
    public init(rawValue:Int) {
        self.rawValue = rawValue
    }
    public static let leadingWhiteSpaces = TrimmingOptions(rawValue: 1 << Opts.leadingWhiteSpaces.rawValue)
    public static let leadingNewlines = TrimmingOptions(rawValue: 1 << Opts.leadingNewlines.rawValue)
    public static let inlineConsecutiveWhiteSpaces = TrimmingOptions(rawValue: 1 << Opts.inlineConsecutiveWhiteSpaces.rawValue)
    public static let inlineConsecutiveNewlines = TrimmingOptions(rawValue: 1 << Opts.inlineConsecutiveNewlines.rawValue)
    public static let trailingWhiteSpaces = TrimmingOptions(rawValue: 1 << Opts.trailingWhiteSpaces.rawValue)
    public static let trailingNewlines = TrimmingOptions(rawValue: 1 << Opts.trailingNewlines.rawValue)
    public static let all = TrimmingOptions(rawValue: allCases.reduce(0, { $0 + $1.rawValue }))
    public var description:String {
        var members:[String] = []
        for option in Opts.allCases where self.contains(TrimmingOptions(rawValue: 1<<option.rawValue)) {
            members.append("\(option)")
        }
        return "[\(members.joined(separator: "|"))]"
    }
}

