/// Table framing options
///
/// Framing options provide an easy way to affect
/// what parts of the table frame get's rendered.
///
/// By default, all frame elements are included.

public struct FramingOptions : OptionSet, Hashable, Codable {
    public typealias RawValue = Int
    public var rawValue:RawValue
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    public static let topFrame              = FramingOptions(rawValue: 1 << 0)
    public static let bottomFrame           = FramingOptions(rawValue: 1 << 1)
    public static let leftFrame             = FramingOptions(rawValue: 1 << 2)
    public static let rightFrame            = FramingOptions(rawValue: 1 << 3)
    public static let insideHorizontalFrame = FramingOptions(rawValue: 1 << 4)
    public static let insideVerticalFrame   = FramingOptions(rawValue: 1 << 5)

    public static let none = FramingOptions([])
    public static let all = FramingOptions([.topFrame, .bottomFrame,
                                                   .insideHorizontalFrame, .insideVerticalFrame,
                                                   .leftFrame, .rightFrame])
    public static let inside = FramingOptions([.insideHorizontalFrame, .insideVerticalFrame])
    public static let outside = FramingOptions([.topFrame, .bottomFrame, .leftFrame, .rightFrame])

    public var optionsInEffect:String {
        var str:[String] = []
        for i in 0...5 {
            switch rawValue & (1 << i) {
            case FramingOptions.topFrame.rawValue: str.append("topFrame")
            case FramingOptions.bottomFrame.rawValue: str.append("bottomFrame")
            case FramingOptions.leftFrame.rawValue: str.append("leftFrame")
            case FramingOptions.rightFrame.rawValue: str.append("rightFrame")
            case FramingOptions.insideHorizontalFrame.rawValue: str.append("insideHorizontalFrame")
            case FramingOptions.insideVerticalFrame.rawValue: str.append("insideVerticalFrame")
            default: break
            }
        }
        return str.joined(separator: ", ")
    }
}

