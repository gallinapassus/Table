
public struct FrameRenderingOptions : OptionSet, Hashable, Codable {
    public typealias RawValue = Int
    public var rawValue:RawValue
    public init(rawValue: RawValue) {
        self.rawValue = rawValue
    }
    public static let topFrame              = FrameRenderingOptions(rawValue: 1 << 0)
    public static let bottomFrame           = FrameRenderingOptions(rawValue: 1 << 1)
    public static let leftFrame             = FrameRenderingOptions(rawValue: 1 << 2)
    public static let rightFrame            = FrameRenderingOptions(rawValue: 1 << 3)
    public static let insideHorizontalFrame = FrameRenderingOptions(rawValue: 1 << 4)
    public static let insideVerticalFrame   = FrameRenderingOptions(rawValue: 1 << 5)

    public static let none = FrameRenderingOptions([])
    public static let all = FrameRenderingOptions([.topFrame, .bottomFrame,
                                                   .insideHorizontalFrame, .insideVerticalFrame,
                                                   .leftFrame, .rightFrame])
    public static let inside = FrameRenderingOptions([.insideHorizontalFrame, .insideVerticalFrame])
    public static let outside = FrameRenderingOptions([.topFrame, .bottomFrame, .leftFrame, .rightFrame])

    public var optionsInEffect:String {
        var str:[String] = []
        for i in 0...5 {
            switch rawValue & (1 << i) {
            case FrameRenderingOptions.topFrame.rawValue: str.append("topFrame")
            case FrameRenderingOptions.bottomFrame.rawValue: str.append("bottomFrame")
            case FrameRenderingOptions.leftFrame.rawValue: str.append("leftFrame")
            case FrameRenderingOptions.rightFrame.rawValue: str.append("rightFrame")
            case FrameRenderingOptions.insideHorizontalFrame.rawValue: str.append("insideHorizontalFrame")
            case FrameRenderingOptions.insideVerticalFrame.rawValue: str.append("insideVerticalFrame")
            default: break
            }
        }
        return str.joined(separator: ", ")
    }
}

