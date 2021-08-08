public struct Txt : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public let string:String
    public let alignment:Alignment?
    public let wrapping:Wrapping?
    public init(_ str:String, _ alignment: Alignment? = nil, _ wrapping:Wrapping? = nil) {
        self.string = str
        self.alignment = alignment
        self.wrapping = wrapping
    }
    public init(stringLiteral:StringLiteralType) {
        self.string = stringLiteral
        self.alignment = nil
        self.wrapping = nil
    }
    internal func fragment(fallback alignment:Alignment, width:Int) -> HorizontallyAligned {
        let lines:[String]
        switch wrapping {
        case.word:
            lines = string.compressedWords(string, width)
                .map { $0.render(to: width, alignment: self.alignment ?? alignment) }
        case .char, .fit, nil:
            lines = string.split(to: width)
                .map { $0.render(to: width, alignment: self.alignment ?? alignment) }
        }
        return HorizontallyAligned(lines: lines, alignment: alignment, width: .value(width))
    }
    internal func fragment(for column:Col) -> HorizontallyAligned {
        self.fragment(fallback: self.alignment ?? column.alignment,
                      width: column.width.rawValue)
    }
}
extension Txt : Collection {
    public func index(after i: String.Index) -> String.Index {
        string.index(after: i)
    }
    public subscript(position: String.Index) -> String.Element {
        string[position]
    }
    public var startIndex: String.Index {
        string.startIndex
    }
    public var endIndex: String.Index {
        string.endIndex
    }
    public typealias Index = String.Index
}
