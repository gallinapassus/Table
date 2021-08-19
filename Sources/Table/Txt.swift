public struct Txt : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public let string:String
    public let alignment:Alignment?
    public let wrapping:Wrapping?
    public init(_ str:String, alignment: Alignment? = nil, wrapping:Wrapping? = nil) {
        self.string = str
        self.alignment = alignment
        self.wrapping = wrapping
    }
    public init(stringLiteral:StringLiteralType) {
        self.string = stringLiteral
        self.alignment = nil
        self.wrapping = nil
    }
    internal func fragment(fallback alignment:Alignment, width:Int, wrapping:Wrapping) -> HorizontallyAligned {
        precondition(width >= 0, "Negative widths are not allowed here.")
        let lines:[String]
        switch wrapping {
        case .word:
            lines = string.compressedWords(string, width)
                .map { $0.render(to: width, alignment: self.alignment ?? alignment) }
        case .char:
            lines = Substring(string).split(to: width)
                .map { $0.render(to: width, alignment: self.alignment ?? alignment) }
        case .cut:
            switch width {
            case 0:
                lines = [""]
            case 1:
                if string.count > width {
                    lines = ["…"]
                }
                else {
                    lines = [string]
                }
            case 2:
                if string.count > width {
                    lines = ["\(string.prefix(1))…"]
                }
                else {
                    lines = [string.render(to: width, alignment: self.alignment ?? alignment)]
                }
            case 3:
                if string.count > width {
                    lines = ["\(string.prefix(1))…\(string.suffix(1))"]
                }
                else {
                    lines = [string.render(to: width, alignment: self.alignment ?? alignment)]
                }
            default:
                guard width > Width.auto.rawValue else {
                    fatalError("Negative widths are not allowed here.")
                }
                if string.count > width {
                    let head = width / 2
                    let tail = width - 1 - head
                    lines = [(string.prefix(head) + "…" + string.suffix(tail)).split(to: width).first?.render(to: width, alignment: self.alignment ?? alignment) ?? ""]
                }
                else {
                    lines = [string.render(to: width, alignment: self.alignment ?? alignment)]
                }
            }
        }
        return HorizontallyAligned(lines: lines, alignment: alignment, width: .value(width))
    }
    internal func fragment(for column:Col) -> HorizontallyAligned {
        return self.fragment(fallback: self.alignment ?? column.alignment,
                             width: column.width.rawValue,
                             wrapping: self.wrapping ?? column.wrapping)
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
