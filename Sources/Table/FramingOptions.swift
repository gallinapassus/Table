/// Table framing options
///
/// Framing options provide an easy way to affect
/// what parts of the table frame get's rendered.
///
/// By default, all frame elements are included.

public struct FramingOptions : OptionSet, Hashable, Codable, CaseIterable {

    public enum FrameElement : String, Codable, CaseIterable {
        case topFrame
        case bottomFrame
        case leftFrame
        case rightFrame
        case insideHorizontalFrame
        case insideVerticalFrame
        
        public var index:Int {
            Self.allCases.firstIndex(where: { $0.rawValue == rawValue })!
        }
    }

    public typealias RawValue = Int
    public var rawValue:RawValue
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    public init(_ elements:[FrameElement]) {
        self.rawValue = elements.reduce(0, { $0 | (1 << $1.index) })
    }
    public static let topFrame              = FramingOptions(rawValue: 1 << FrameElement.topFrame.index)
    public static let bottomFrame           = FramingOptions(rawValue: 1 << FrameElement.bottomFrame.index)
    public static let leftFrame             = FramingOptions(rawValue: 1 << FrameElement.leftFrame.index)
    public static let rightFrame            = FramingOptions(rawValue: 1 << FrameElement.rightFrame.index)
    public static let insideHorizontalFrame = FramingOptions(rawValue: 1 << FrameElement.insideHorizontalFrame.index)
    public static let insideVerticalFrame   = FramingOptions(rawValue: 1 << FrameElement.insideVerticalFrame.index)

    public static let none = FramingOptions([])
    public static let all = FramingOptions([.topFrame, .bottomFrame,
                                            .insideHorizontalFrame, .insideVerticalFrame,
                                            .leftFrame, .rightFrame])
    public static var allCases:[FramingOptions] = [.topFrame, .bottomFrame,
                                                   .insideHorizontalFrame, .insideVerticalFrame,
                                                   .leftFrame, .rightFrame]
    public static let inside = FramingOptions([.insideHorizontalFrame, .insideVerticalFrame])
    public static let outside = FramingOptions([.topFrame, .bottomFrame, .leftFrame, .rightFrame])

    public var optionsInEffect:String {
        var str:[String] = []
        for i in FrameElement.allCases {
            guard ((1 << i.index) & rawValue) > 0 else { continue }
            str.append(i.rawValue)
        }
        return str.joined(separator: ", ")
    }
    public static var availableOptions:[String] {
        FrameElement.allCases.map({ $0.rawValue })
    }
}

