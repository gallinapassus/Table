/// Concrete type encapsulating table cell data
///
/// Associated alignment and wrapping will override the
/// default alignment and wrapping set on the column level.

public struct Txt : ExpressibleByStringLiteral, Equatable, Codable {
    public typealias StringLiteralType = String

    /// Text to be rendered
    public let string:String
    /// Text alignment (will override column default alignment)
    public let align:Alignment?
    /// Text wrapping (will override column default wrapping)
    public let wrapping:Wrapping?
    public init(_ str:String, align: Alignment? = nil, wrapping:Wrapping? = nil) {
        self.string = str
        self.align = align
        self.wrapping = wrapping
    }
    public init(stringLiteral:StringLiteralType) {
        self.string = stringLiteral
        self.align = nil
        self.wrapping = nil
    }

    /// Generate horizontally aligned text fragments for specified width, alignment and wrapping

    private func fragment(fallback alignment:Alignment, width:Int, wrapping:Wrapping) -> HorizontallyAligned {
        precondition(width >= 0, "Negative widths are not allowed here.")
        let lines:[String]
        switch wrapping {
        case .word:
            lines = string.compressedWords(string, width)
                .map { $0.render(to: width, alignment: self.align ?? alignment) }
        case .char:
            lines = Substring(string).split(to: width)
                .map { $0.render(to: width, alignment: self.align ?? alignment) }
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
                    lines = [string.render(to: width, alignment: self.align ?? alignment)]
                }
            case 3:
                if string.count > width {
                    lines = ["\(string.prefix(1))…\(string.suffix(1))"]
                }
                else {
                    lines = [string.render(to: width, alignment: self.align ?? alignment)]
                }
            default:
                guard width > Width.auto.value else {
                    fatalError("Negative widths are not allowed here.")
                }
                if string.count > width {
                    let head = width / 2
                    let tail = width - 1 - head
                    lines = [(string.prefix(head) + "…" + string.suffix(tail)).split(to: width).first?.render(to: width, alignment: self.align ?? alignment) ?? ""]
                }
                else {
                    lines = [string.render(to: width, alignment: self.align ?? alignment)]
                }
            }
        }
        return HorizontallyAligned(lines: lines, alignment: alignment, width: .value(width))
    }
    internal func fragment(for column:Col) -> HorizontallyAligned {
        return self.fragment(fallback: self.align ?? column.defaultAlignment,
                             width: column.width.value,
                             wrapping: self.wrapping ?? column.defaultWrapping)
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
