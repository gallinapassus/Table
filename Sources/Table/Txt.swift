/// Concrete type encapsulating table cell data
///
/// Associated alignment and wrapping will override the
/// default alignment and wrapping set on the column level.

public struct Txt : ExpressibleByStringLiteral, Equatable, Codable, Hashable {
    public static func == (lhs: Txt, rhs: Txt) -> Bool {
        lhs.string == rhs.string &&
        lhs.wrapping == rhs.wrapping &&
        lhs.alignment == rhs.alignment
    }

    public typealias StringLiteralType = String

    /// Text to be rendered
    public var string:String
    /// Text alignment (will override column default alignment)
    public let alignment:Alignment?
    /// Text wrapping (will override column default wrapping)
    public let wrapping:Wrapping?
    public init() {
        self.init("")
    }
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
public func wordsx(_ str:String, to width:Int) -> [Substring] {
    guard width > 0 else { return [] }
    let splitted = str.split(maxSplits: str.count, omittingEmptySubsequences: false) { c in
        switch c {
        case " ": return true
        default: return false
        }
    }
    //print("splitted: \(splitted)")
    let cutted = splitted.flatMap { $0.cutTo(width: width) }
    //print("cutted: \(cutted)")
    var joined:[Substring] = []
    var len = 0
    var s:String = ""
    for w in cutted {
        if len == 0 {
            s = "\(w)"
            len = s.count
        }
        else if 1 + len + w.count <= width {
            s.append(" \(w)")
            joined.append(s[...])
            s = ""
            len = 0
        }
        else {
            joined.append(s[...])
            s = "\(w)"
            len = s.count
        }
    }
    if s.isEmpty == false {
        joined.append(s[...])
    }
    //print("joined: \(joined)")
    return joined
}
