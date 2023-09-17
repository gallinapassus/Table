/// Concrete type encapsulating table cell data
///
/// Associated alignment and wrapping will override the
/// default alignment and wrapping set on the column level.

/*final*/ public /*class*/ struct Txt : ExpressibleByStringLiteral, Equatable, Codable, Hashable {
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
    public /*convenience*/ init() {
        self.init("")
    }
    public init(_ str:String, alignment: Alignment? = nil, wrapping:Wrapping? = nil) {
        self.string = str
        self.alignment = alignment
        self.wrapping = wrapping
    }
    /*required*/ public init(stringLiteral:StringLiteralType) {
        self.string = stringLiteral
        self.alignment = nil
        self.wrapping = nil
    }

    /// Generate horizontally aligned text fragments for specified width, alignment and wrapping

    private func fragment(fallback alignment:Alignment, width:Int, wrapping:Wrapping) -> HorizontallyAligned {
        precondition(width >= 0, "Negative widths are not allowed here.")
        let lines:[String]
        switch wrapping {
        case .word2:
            let foo = wordsx(string, to: width)
            lines = foo.map { $0.render(to: width, alignment: self.alignment ?? alignment) }
        case .word:
            let foo = string.compressedWords(width)
            lines = foo.map { $0.render(to: width, alignment: self.alignment ?? alignment) }
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
//                guard width > Width.auto.value else {
//                    fatalError("Negative widths are not allowed here.")
//                }
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
        return HorizontallyAligned(lines: lines, alignment: alignment, width: width)
    }
    internal func fragment(for column:FixedCol) -> HorizontallyAligned {
        return self.fragment(fallback: self.alignment ?? column.defaultAlignment,
                             width: column.width,
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
public func wordsx(_ str:String, to width:Int) -> [Substring] {
    //print(#function, "processing '\(str)'")
    guard width > 0 else {
        return []
    }
    
    guard str.isContiguousUTF8 else {
        fatalError()
    }
    
    var cursor = str.startIndex
    var lo = str.startIndex
    var lr:[Range<String.Index>] = []
    var subs:[Substring] = []
    var c = 0
    
    let consumeWhitespace = {
        while cursor < str.endIndex, str[cursor] == Character(" ") {
            cursor = str.index(after: cursor)
        }
    }
    let tot = {
        let a = lr.count
        let b = lr.reduce(0, {
            $0 + str.distance(from: $1.lowerBound, to: $1.upperBound)
        })
        let d = str.distance(from: lo, to: cursor)
        let total = a + b + d
        return (d,total)
    }
    let appendSub = {
        let (d,t) = tot()
        if t <= width {
            if d > 0 {
                //print("fits, append '\(str[lo..<cursor])' to stack")
                lr.append(lo..<cursor)
            }
        }
        else {
            //print("doesn't fit, append '\(lr.map({ str[$0] }).joined(separator: "-"))' to subs")
            subs.append(Substring(lr.map({ str[$0] }).joined(separator: "-")))
            //print("and, append '\(str[lo..<cursor])' to stack")
            lr.append(lo..<cursor)
//            subs.append(Substring(str[lo..<cursor]))
        }
    }
    consumeWhitespace()
    lo = cursor
    var counter = 0
    while cursor < str.endIndex {
        counter += 1
//        print(str[cursor].isNewline ? "\\n" : str[cursor], "==",
//              str[cursor].asciiValue!,
//              "\t'\(str[cursor...])'",
//              lr.map({ "\(str[$0])" })
//        )
        if (c > 0 && c % width == 0) || str[cursor].isNewline {
            if str[cursor].isNewline {
                if c % width == 0 {
                    //print("cutpoint & newline @\(c), counter \(counter)")
                    appendSub()
                    subs.append(Substring("␤"))
                    lr = []
                }
                else {
                    //print("newline only @\(c), counter \(counter) '\(str[lo..<cursor])'")
                    appendSub()
                    subs.append(Substring("␤"))
                }
            }
            else {
                //print("cutpoint only @\(c), counter \(counter)")
                appendSub()
                lr = []
            }
            consumeWhitespace()
            lo = cursor
            c = 0
        }
        else if str[cursor] == Character(" ") {
            let (d,t) = tot()
            if t <= width {
                if /*str.distance(from: lo, to: cursor)*/d > 0 {
                    //notAllWhitespaces()
                    lr.append(lo..<cursor)
                }
            }
            else {
                //print("appending '\(Substring(lr.map({ str[$0] }).joined(separator: "+")))'")
                subs.append(Substring(lr.map({ str[$0] }).joined(separator: "+")))
                //notAllWhitespaces()
                lr = [lo..<cursor]
                lo = cursor
                c = 0
            }
            consumeWhitespace()
            lo = cursor
            c = 0
            continue
        }
        /*else if str[cursor].isNewline {
            print("HERE")
            if tot() <= width {
                if str.distance(from: lo, to: cursor) > 0 {
                    //notAllWhitespaces()
                    lr.append(lo..<cursor)
                }
                //print("appending '\(Substring(lr.map({ str[$0] }).joined(separator: "%")))'")
                subs.append(Substring(lr.map({ str[$0] }).joined(separator: "%")))
                subs.append(Substring("␤"))
                //print("appending '\(Substring("<%>"))'")
                //subs.append(Substring("<%>"))
                lo = str.index(after: cursor)
                lr = []
                c = 0
            }
            else {
                //print("appending '\(Substring(lr.map({ str[$0] }).joined(separator: "&")))'")
                subs.append(Substring(lr.map({ str[$0] }).joined(separator: "&")))
                //print("appending '\(Substring(str[lo..<cursor]))'")
                if notAllWhitespaces() {
                    subs.append(Substring(str[lo..<cursor]))
                    subs.append(Substring("␤"))
                }
                //print("appending '\(Substring("<&>"))'")
                //subs.append(Substring("<&>"))
                lo = str.index(after: cursor)
                lr = []
                c = 0
            }
        }*/
        if cursor < str.endIndex {
            cursor = str.index(after: cursor)
            c += 1
        }
    }
    //print("I'm at: stack '\(lr.map({str[$0]}))' '\(str[lo..<cursor])'")
    appendSub()
    /*
    let (d,t) = tot()
    if t <= width {
        if d > 0 {
            if str[lo..<cursor].allSatisfy({ $0 == Character(" ") }) == false {
                lr.append(lo..<cursor)
            }
        }
        if lr.count > 0 {
            subs.append(Substring(lr.map({ str[$0] }).joined(separator: "#")))
        }
    }
    else {
        //                if lr.count > 0 {
        subs.append(Substring(lr.map({ str[$0] }).joined(separator: "*")))
        //                }
        if lo < cursor {
            subs.append(Substring(str[lo..<cursor]))
        }
    }
    */
    //print("returning", subs)
    return subs
}
extension Txt : CustomStringConvertible {
    public var description: String {
        let a = alignment == nil ? "nil" : ".\(alignment!)"
        let w = wrapping == nil ? "nil" : ".\(wrapping!)"
        return "\(type(of: self))(\"\(string.replacingOccurrences(of: "\n", with: "\\n"))\", \(a), \(w))"
    }
}
/*
extension Txt {
    func format(for width:Int,
                defaultAlignment:Alignment,
                defaultWrapping:Wrapping) -> [String] {

        let haligned = halign(
            defaultAlignment: defaultAlignment,
            defaultWrapping: defaultWrapping,
            width: width
        )
        return haligned
    }
}
*/
