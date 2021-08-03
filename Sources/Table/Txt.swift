public struct Txt : ExpressibleByStringLiteral {
    public typealias StringLiteralType = String

    public let string:String
    public let alignment:Alignment?
    public init(_ str:String, _ alignment: Alignment? = nil) {
        self.string = str
        self.alignment = alignment
    }
    public init(stringLiteral:StringLiteralType) {
        self.string = stringLiteral
        self.alignment = nil
    }
    internal func fragment(fallback alignment:Alignment, width:Int, with wrapper:((String, Int)->[Substring])? = nil) -> HorizontallyAligned {
        //let t0 = DispatchTime.now().uptimeNanoseconds
        let wrapper = wrapper ?? string.compressedWords(_:_:)
        let lines = wrapper(string, width)
            .map { $0.render(to: width, alignment: self.alignment ?? alignment) }
        //let t1 = DispatchTime.now().uptimeNanoseconds
        //print(#function, Double(t1 - t0) / 1_000_000)
        return HorizontallyAligned(lines: lines, alignment: alignment, width: .value(width))
    }
    internal func fragment(for column:Col, with wrapper:((String, Int)->[Substring])? = nil) -> HorizontallyAligned {
        self.fragment(fallback: self.alignment ?? column.alignment,
                      width: column.width.rawValue,
                      with: wrapper ?? string.compressedWords(_:_:))
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

