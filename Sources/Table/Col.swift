
public struct Col : Equatable, Codable {
    public let header:Txt?
    internal (set) public var width:Width
    public let columnAlignment:Alignment
    public let wrapping:Wrapping
    public let contentHint:ColumnContentHint
    public init(_ header:Txt? = nil,
                width:Width = .auto,
                columnDefaultAlignment:Alignment = .default,
                wrapping:Wrapping = .default,
                contentHint:ColumnContentHint = .repetitive) {
        self.header = header
        self.width = width
        self.columnAlignment = columnDefaultAlignment
        self.wrapping = wrapping
        self.contentHint = contentHint
    }
}
extension Col : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String
    public  init(stringLiteral value: String) {
        self.header = Txt(value)
        self.width = .auto
        self.columnAlignment = .default
        self.wrapping = .default
        self.contentHint = .repetitive
    }
}
extension Col : ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = Int
    public init(integerLiteral value: Int) {
        self.init(width: Width.value(value))
    }
}
extension Col {
    public init(_ string:String,
                width:Width = .auto,
                align:Alignment = .default,
                wrapping:Wrapping = .default,
                contentHint:ColumnContentHint = .repetitive) {
        self.init(Txt(string), width: width, columnDefaultAlignment: align, wrapping: wrapping, contentHint: contentHint)
    }
}
public enum ColumnContentHint : Equatable, Codable {
    case unique, repetitive
}
