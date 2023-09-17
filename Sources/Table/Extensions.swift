extension Substring {
    /// Split substring to fragments
    internal func split(to multipleOf:Int) -> [Substring] {
        // NOTE: Should we pad horizontally as well here?
        guard multipleOf > 0 else {
            return [Substring(self)]
        }
        var arr:[Substring] = []
        var c = startIndex
        while c != endIndex {
            while c < endIndex, self[c] == Character(" ") {
                c = self.index(after: c)
            }
            guard var e = self.index(c, offsetBy: multipleOf, limitedBy: endIndex) else {
                arr.append(self[c..<endIndex])
                return arr
            }
            while self[self.index(before: e)] == Character(" ") && e != c {
                e = self.index(before: e)
            }
            arr.append(self[c..<e])
            c = e
        }
        return arr
    }
}
extension String {
    /// Base algorithm to trim whitespaces and newlines
    /// from `String`'s head and/or tail.
    ///
    /// - Parameters:
    ///     - cursor: Initial index to start trimming from
    ///     - end: Stop trimming
    ///     - comparator: Comparator operator (function) to
    ///      compare if cursor has reached end
    ///     - trimSpace: Boolean value indicating if space(s)
    ///     should be trimmed
    ///     - trimNewline: Boolean value indicating if newline(s)
    ///     should be trimmed
    ///     - strArrStorage: Inout storage for holding trimmed multiline content
    ///     - strStorage:Inout storage for holding trimmed (single-line) content
    ///     - nextIndex: Function to advance cursor to right direction (forwards
    ///     or backwards)
    /// - Important: Trimmed content is stored in strArrStorage and StrStorage
    /// in same order as the index is advanced.
    @inline(__always)
    fileprivate func _headAndTailTrimAndFragment(
        cursor:inout String.Index,
        end:String.Index,
        comparator:(String.Index,String.Index) -> Bool,
        trimSpace:Bool, trimNewline:Bool,
        strArrStorage:inout [String]?,
        strStorage:inout String,
        nextIndex:(inout String.Index) -> Void) {

        var tmp:String = ""
        let reverse:Bool = cursor > end
        var processNext = true
        while comparator(cursor, end), processNext {
            let c = self[cursor]
            guard c == " " || c == "\n" else {
                if reverse {
                    tmp.append(c)
                }
                else {
                    strStorage.append(c)
                }
                processNext = false
                continue
            }
            if trimSpace == false, c == " " {
                if reverse {
                    tmp.append(c)
                }
                else {
                    strStorage.append(c)
                }
            }
            else if trimNewline == false, c == "\n" {
                if strArrStorage != nil {
                    //strArrStorage!.append(/*strStorage*/String(tmp.reversed()))
                    if reverse {
                        strArrStorage!.append(String(tmp.reversed()))
                        tmp = ""
                    }
                    else {
                        strArrStorage!.append(strStorage)
                        strStorage = ""
                    }
//                    strStorage = ""
                }
                else {
                    if reverse {
                        tmp.append(c)
                    }
                    else {
                        strStorage.append(c)
                    }
                }
            }
            nextIndex(&cursor)
        }
        if reverse {
            tmp.reversed().forEach({strStorage.append($0)})
        }
    }

    internal func fragment(where character: (Character) -> Bool) -> [Substring] {
        var splits:[Substring] = []
        var i = startIndex
        var cursor = i
        while i != endIndex {
            if character(self[i]) {
                splits.append(self[cursor...i])
                cursor = index(after: i)
            }
            i = index(after: i)
        }
        if i != cursor {
            splits.append(self[cursor...])
        }
        return splits
    }
    internal func words(to width:Int) -> [Substring] {

        let wds:[Substring]
            wds = self
                .split(separator: " ", maxSplits: self.count, omittingEmptySubsequences: true)
                .flatMap({ $0.count > width ? $0.split(to: width) : [$0] })
        return wds.isEmpty ? [Substring("")] : wds
    }
    internal func compressedWords(_ width:Int) -> [Substring] {
        words(to: width).compress(to: width)
    }
    func maxFragmentWidth(separator: Character) -> Int {
        split(separator: "\n", omittingEmptySubsequences: true)
            .reduce(0, { Swift.max($0, $1.count) })
    }
    /// Trim string
    ///
    /// Examples:
    ///
    ///     " abc\n".trim(.leadingWhiteSpaces) // "abc\n"
    ///     "\n \nabc\n".trim(.leadingNewlines) // " abc\n"
    ///     "a b  c".trim(.inlineConsecutiveWhiteSpaces) // "a b c"
    ///     " a\n\nbc\n".trim(.inlineConsecutiveNewlines) // " a\nbc\n"
    ///     " abc  ".trim(.trailingWhiteSpaces) // " abc"
    ///     " abc\n ".trim(.trailingNewlines) // " abc "
    ///     "  \n\na  b\n\nc\n ".trim(.all) // "a b\nc"
    ///
    /// - Returns: A new `String` trimmed according to given `TrimmingOptions`.
    @inline(__always)
    public func trim(_ options:TrimmingOptions) -> String {

        guard self.isEmpty == false else { return self }
        var cursor = startIndex
        var nonArr:[String]? = nil
        var h = ""
        var t = ""


        // Trim Head
        _headAndTailTrimAndFragment(cursor: &cursor, end: endIndex, comparator: <,
            trimSpace: options.contains(.leadingWhiteSpaces),
            trimNewline: options.contains(.leadingNewlines),
            strArrStorage: &nonArr, strStorage: &h,
            nextIndex: self.formIndex(after:))


        // Trim Tail
        let bodyFirstChar = cursor
        cursor = startIndex != endIndex ? self.index(before: endIndex) : cursor
        _headAndTailTrimAndFragment(cursor: &cursor, end: bodyFirstChar, comparator: >,
            trimSpace: options.contains(.trailingWhiteSpaces),
            trimNewline: options.contains(.trailingNewlines),
            strArrStorage: &nonArr, strStorage: &t,
            nextIndex: self.formIndex(before:))


        // Trim Body
        let bodyEnd = cursor
        cursor = bodyFirstChar < endIndex ? self.index(after: bodyFirstChar) : endIndex
        var spcCount = 0
        var nlCount = 0
        while cursor < bodyEnd {
            let c = self[cursor]
            if c == " " {
                spcCount += 1
                nlCount = 0
                if options.contains(.inlineConsecutiveWhiteSpaces) {
                    if spcCount == 1 {
                        h.append(" ")
                    }
                }
                else {
                    h.append(" ")
                }
            }
            else if c == "\n" {
                nlCount += 1
                spcCount = 0
                if options.contains(.inlineConsecutiveNewlines) {
                    if nlCount == 1 {
                        h.append("\n")
                    }
                }
                else {
                    h.append("\n")
                }
            }
            else {
                spcCount = 0
                nlCount = 0
                h.append(c)
            }
            self.formIndex(after: &cursor)
        }
        h.append(/*String(t.reversed())*/t)

        return h
    }
    @inline(__always)
    public func trimAndFrag(_ options:TrimmingOptions) -> [String] {

        guard self.isEmpty == false else { return [""] }


        var cursor = startIndex
        var hh:[String]? = []
        var tt:[String]? = []
        var h:String = ""
        var t:String = ""


        // Trim Head
        _headAndTailTrimAndFragment(cursor: &cursor, end: endIndex,
            comparator: <,
            trimSpace: options.contains(.leadingWhiteSpaces),
            trimNewline: options.contains(.leadingNewlines),
            strArrStorage: &hh, strStorage: &h,
            nextIndex: self.formIndex(after:))
        let bodyFirstChar = cursor
        cursor = self.index(before: endIndex)


        // Trim Tail
        _headAndTailTrimAndFragment(cursor: &cursor, end: bodyFirstChar,
            comparator: >,
            trimSpace: options.contains(.trailingWhiteSpaces),
            trimNewline: options.contains(.trailingNewlines),
            strArrStorage: &tt, strStorage: &t,
            nextIndex: self.formIndex(before:))
        let bodyLastChar = cursor
        if bodyFirstChar < endIndex {
            cursor = self.index(after: bodyFirstChar)
        }


        // Trim Body
        var spcCount = 0
        var nlCount = 0
        while cursor < bodyLastChar {
            let c = self[cursor]
            if c == " " {
                spcCount += 1
                nlCount = 0
                if options.contains(.inlineConsecutiveWhiteSpaces) {
                    if spcCount == 1 {
                        h.append(" ")
                    }
                }
                else {
                    h.append(" ")
                }
            }
            else if c == "\n" {
                nlCount += 1
                spcCount = 0
                if options.contains(.inlineConsecutiveNewlines) {
                    if nlCount == 1 {
                        hh!.append(h)
                        h = ""
                    }
                }
                else {
                    hh!.append(h)
                    h = ""
                }
            }
            else {
                spcCount = 0
                nlCount = 0
                h.append(c)
            }
            self.formIndex(after: &cursor)
        }
        h.append(t)
        hh!.append(h)
        hh!.append(contentsOf: tt!.reversed())

        return hh!
    }
}
extension String {

    internal func render(to width:Int, alignment:Alignment = .topLeft, padding with:Character = " ") -> String {
        guard self.count < width else {
            return String(self.prefix(width))
        }

        let padAmount = width - self.count
        let pad = String(repeating: with, count: padAmount)
        switch alignment {
        case .topLeft, .bottomLeft, .middleLeft: return self + pad
        case .topRight, .bottomRight, .middleRight: return pad + self
        case .topCenter, .bottomCenter, .middleCenter:
            let rangeHead = pad.startIndex..<pad.index(pad.startIndex, offsetBy: padAmount / 2, limitedBy: pad.endIndex)!
            let rangeTail = rangeHead.upperBound..<pad.endIndex
            return pad[rangeHead].description + self + pad[rangeTail].description
        }
    }
}
extension String.StringInterpolation {
    /// Prints `Optional` values by only interpolating it if the value is set. `nil` is used as a fallback value to provide a clear output.
    mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T?) {
        appendInterpolation(value ?? "nil" as CustomStringConvertible)
    }
    mutating func appendInterpolation<T: CustomStringConvertible>(_ value:T, aligned withOthers:[String], pad:Character = ".") {
        let max = withOthers.reduce(0, { Swift.max($0, $1.count) })
        let pad = String(repeating: pad, count: Swift.max(0, max - value.description.count))
        appendInterpolation(value)
        appendInterpolation(pad)
    }
    mutating func appendInterpolation<T: CustomStringConvertible>(_ value:T, aligned withOthers:any CaseIterable.Type, pad:Character = " ") {
        let max = (withOthers.allCases as any Collection).map({"\($0)"}).reduce(0, { Swift.max($0, $1.count) })
        let pad = String(repeating: pad, count: Swift.max(0, max - value.description.count))
        appendInterpolation(value)
        appendInterpolation(pad)
    }
    mutating func appendInterpolation<T: CustomStringConvertible>(_ value:T, aligned toWidth:Int, pad:Character = " ") {
        let pad = String(repeating: pad, count: Swift.max(0, toWidth - value.description.count))
        guard value.description.count < toWidth else {
            appendInterpolation(value.description.prefix(toWidth))
            return
        }
        appendInterpolation(value)
        appendInterpolation(pad)
    }
    mutating func appendInterpolation<T: CustomStringConvertible>(_ value:T, visibleWhitespaces v:Bool, quoted:Bool = false) {
        if quoted {
            appendLiteral("'")
        }
        appendInterpolation(value.description
            .replacingOccurrences(of: " ", with: "␠")
            .replacingOccurrences(of: "\n", with: "␤"))
        if quoted {
            appendLiteral("'")
        }
    }
}
extension Substring {

    @inline(__always)
    internal func render(to width:Int, alignment:Alignment = .topLeft, padding with:Character = " ") -> String {
        String(self).render(to: width, alignment: alignment, padding: with)
    }
}
extension Substring {
    @inline(__always)
    public func cutTo(width:Int) -> [Substring] {
        guard count > width else { return [self] }
        return stride(from: 0, to: count, by: width)
            .map {
                let s = self.index(startIndex, offsetBy: $0, limitedBy: endIndex) ?? endIndex
                let e = self.index(startIndex, offsetBy: $0 + width, limitedBy: endIndex) ?? endIndex
                return self[s..<e]
            }
    }
}
import DebugKit
extension Array where Element == Substring {
    // Reverse-greedy
    internal func compress(to width:Int, binding with:Character = " ") -> [Substring] {
        guard isEmpty == false else {
            return []
        }
        var ridx = index(before: endIndex)
        var lidx = index(before: ridx)
        while ridx != startIndex {
            if self[lidx].count + self[ridx].count + 1 <= width {
                return (self[..<lidx] +
                            [Substring([self[lidx], self[ridx]].joined(separator: "\(with)"))] +
                            self[index(after: ridx)...]).compress(to: width)
            }
            else {
                lidx = self.index(before: lidx)
                ridx = self.index(before: ridx)
                if lidx == startIndex {
                    if self[lidx].count + self[ridx].count + 1 <= width {
                        return (self[..<lidx] +
                                    [Substring([self[lidx], self[ridx]].joined(separator: "\(with)"))] +
                                    self[index(after: ridx)...])
                    }
                    else {
                        return self
                    }
                }
            }
        }
        return self
    }
    // Forward-greedy <tbi>
    @inline(__always)
    public func packWordsTo(width:Int, alignment:Alignment, combining with:String = " ") -> [String] {
        // ["Quick", "brown", "fox", "jumped", "over", "the", "lazy", "dog."]
        // -> ["  Quick brown", "fox jumped over", "  the lazy dog."]
        let splitted = self.flatMap({ $0.split(to: width) })
        var frags:[String] = []
        var line:String = ""
        for word in splitted {
            guard word.count != width else {
                if line.isEmpty == false {
                    let combined = Table.halignOrCut(line, alignment, width)
                    frags.append(combined)
                }
                frags.append(String(word))
                line = ""
                continue
            }
            guard line.isEmpty else {
                if (line.count + word.count + with.count) <= width {
                    line.append(line.isEmpty ? "\(word)" : " \(word)")
                }
                else {
                    frags.append(Table.halignOrCut(line, alignment, width))
                    line = "\(word)"
                }
                continue
            }
            line = "\(word)"
        }

        if line.isEmpty == false {
            frags.append(halignOrCut(line, alignment, width))
        }
        return frags
    }
}
extension Array where Element: RangeReplaceableCollection, Element.Element:Collection {
    internal func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        return (self.first ?? Element()).indices.map { index in
            self.map { $0[index] }
        }
    }
}
extension ArraySlice where Element == HorizontallyAligned {
    /// Align cell data vertically
    @inline(__always)
    internal func alignVertically(height:Int) -> [[String]] {
        // Find out number of lines needed to represent
        // all cells on this row
        let h:Int
        if height > 0 {
            // Use the given height
            h = height
        }
        else {
            // 0 == no height info => calculate it
            h = reduce(0, { Swift.max($0, $1.lines.count) })
        }
        // Create the cell fragments
        let fragments:[ArraySlice<String>] = map {
            guard $0.lines.count != h else {
                // No need to "vertically pad" if line count
                // already matches the required height
                return ArraySlice<String>($0.lines)
            }
            // Current line count != required height => pad vertically
            return padVertically($0, forHeight: h)
        }
        // Last step, transpose the cell fragments
        return fragments.transposed()
    }
}
/// Pad cell data  vertically
@inline(__always)
internal func padVertically(_ horizontallyAligned:HorizontallyAligned, forHeight:Int) -> ArraySlice<String> {
    // Calculate how many row fragments we need to add for this cell
    let padAmount = Swift.max(0, forHeight - horizontallyAligned.lines.count)
    guard padAmount > 0 else {
        // There was no need for padding
        print("OUT:", horizontallyAligned.lines[...])
        return horizontallyAligned.lines[...]
    }
    // Generate the horizontal cell fragment to be
    // used in padding
    let hpad = String(repeating: " ", count: horizontallyAligned.width)
    // Pad vertically (=add empty cell fragments)
    // based on the alignment setting
    let ret:[String]
    switch horizontallyAligned.alignment {
    case .topLeft, .topRight, .topCenter:
        // Add pad framents to the end of the array
        ret = horizontallyAligned.lines + ArraySlice(repeating: hpad, count: padAmount)
    case .bottomLeft, .bottomRight, .bottomCenter:
        // Add pad framents to the beginning of the array
        ret = ArraySlice(repeating: hpad, count: padAmount) + horizontallyAligned.lines
    case .middleLeft, .middleRight, .middleCenter:
        // Add pad framents to the beginning and end of the array
        let topCount = padAmount / 2
        let bottomCount = forHeight - horizontallyAligned.lines.count - topCount
        let topArray = ArraySlice(repeating: hpad, count: topCount)
        let bottomArray = ArraySlice(repeating: hpad, count: bottomCount)
        ret = topArray + horizontallyAligned.lines + bottomArray
    }
    return ret[...]
}
extension String {
    /// Cut and align `String` to specific width and alignment.
    ///
    /// - Returns: An array of Strings cut to specific width and aligned to given alignment.
    /// An empty array is returned if width is less than or equal to zero.
    ///
    public func cutTo(width:Int, alignment:Alignment) -> [String] {
        guard width > 0 else {
            return []
        }
        var ranges:[Range<String.Index>] = []
        var current = startIndex
        var cursor = startIndex
        var c = 0
        let safelyAdvanceCursor = {
            if cursor < endIndex {
                cursor = index(after: cursor)
            }
        }
        while cursor < endIndex {
            if (c > 0 && c % width == 0) || self[cursor].isNewline {
                if self[cursor].isNewline {
                    ranges.append(current..<cursor)
                    safelyAdvanceCursor()
                    while cursor < endIndex, self[cursor].isNewline {
                        ranges.append(endIndex..<endIndex)
                        safelyAdvanceCursor()
                    }
                    if cursor == endIndex {
                        ranges.append(endIndex..<endIndex)
                    }
                    current = cursor
                    c = 0
                }
                else {
                    ranges.append(current..<cursor)
                    current = cursor
                    c = 0
                }
            }
            safelyAdvanceCursor()
            c += 1
        }
        if current < cursor {
            ranges.append(current..<cursor)
        }
        let cut = ranges.map {
            Table.halignOrCut(self[$0], alignment, width)
        }
        guard cut.isEmpty == false else {
            return [String(repeating: " ", count: width)]
        }
        return cut
    }
}
/// Align horizontally.
///
/// - Returns: Horizontally aligned `String` to the given `alignment` and `width`.
/// Original `String` will be cut to `width` if `String.count > width`.
@inline(__always)
internal func halignOrCut<S:StringProtocol>(_ str:S, _ alignment:Alignment = .topLeft, _ width:Int, padding with:Character = " ") -> String {
    guard str.count < width else {
        return "\(str.prefix(width))"
    }
    
    let padAmount = width - str.count
    let pad = String(repeating: with, count: padAmount)
    switch alignment {
    case .topLeft, .bottomLeft, .middleLeft: return str + pad
    case .topRight, .bottomRight, .middleRight: return pad + str
    case .topCenter, .bottomCenter, .middleCenter:
        let rangeHead = pad.startIndex..<pad.index(pad.startIndex, offsetBy: padAmount / 2, limitedBy: pad.endIndex)!
        let rangeTail = rangeHead.upperBound..<pad.endIndex
        return "\(pad[rangeHead])" + str + "\(pad[rangeTail])"
    }
}

extension Txt {
    /// Trim.
    internal func trim(_ options:TrimmingOptions) -> Txt {
        Txt(string.trim(options), alignment: alignment, wrapping: wrapping)
    }
    /* Not available
    /// Trim in-place.
    internal func trim(_ options:TrimmingOptions) {
        string = string.trim(options)
    }*/
    internal func trimAndFragment(_ options:TrimmingOptions) -> [Txt] {
        let trimmed:[String] = string.trimAndFrag(options)
        return trimmed.map { Txt($0, alignment: alignment, wrapping: wrapping) }
    }
    internal func halign(defaultAlignment:Alignment,
                       defaultWrapping:Wrapping,
                       width:Int) -> [String] {

        // Return quickly?
        guard string.isEmpty == false else {
            return [String(repeating: " ", count: width)]
        }

        var lines:[String] = []
        switch wrapping ?? defaultWrapping {
        case .word:
            lines = string
                .compressedWords(width).map({ $0.description })
                .map({ $0.render(to: width, alignment: alignment ?? defaultAlignment) })

        case .word2:
            // Transform "Quick brown fox jumped over the lazy dog."
            // to width(14), alignment(right)
            //  ["   Quick brown",
            //   "    fox jumped",
            //   " over the lazy"
            //   "          dog."]
            let fragments:[String] = string.trimAndFrag(.all)

            for frag in fragments {
                let words = frag.split(separator: " ", omittingEmptySubsequences: true)
                lines = words.packWordsTo(width: width, alignment: defaultAlignment)
            }

        case .char:
            // Cut cell content to cell width
            // - Newlines are obeyed
            // - No special whitespace handling - spaces are left intact
            lines = string
                .cutTo(width: width, alignment: alignment ?? defaultAlignment)
        case .cut:
            // Squeeze the entire cell into single line
            // Newlines are made visible but ot obeyed
            if string.count <= width {
                lines = [
                    Table.halignOrCut(string, alignment ?? defaultAlignment, width)
                ]
            }
            else {
                let s = string
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: "\n", with: "␤")
                switch width {
                case 0: lines = []
                case 1: lines = ["…"]
                case 2: lines = ["\(s.first! == "\n" ? "␤" : s.first!)…"]
                case 3: lines = ["\(s.first! == "\n" ? "␤" : s.first!)…\(s.last! == "\n" ? "␤" : s.last!)"]
                default:
                    if width % 2 == 0 {
                        let h = width / 2
                        let m:String.Index = s.index(s.startIndex,
                                                     offsetBy: h - 1)
                        let n:String.Index = s.index(s.endIndex,
                                                     offsetBy: -(width - h))
                        lines = [s[s.startIndex..<m] + "…" + s[n..<s.endIndex]]
                    }
                    else {
                        let h = width / 2
                        let m:String.Index = s.index(s.startIndex,
                                                     offsetBy: h)
                        let n:String.Index = s.index(s.endIndex,
                                                     offsetBy: -(width - h - 1))
                        lines = [s[s.startIndex..<m] + "…" + s[n..<s.endIndex]]
                    }
                }
            }
        }
        //print("\(d.0) \(d.1) \(d.2) │     └ return → \(lines)")
        return lines
    }
    internal func halign(for column:FixedCol) -> [String] {
        self.halign(
            defaultAlignment: column.defaultAlignment,
            defaultWrapping: column.defaultWrapping,
            width: column.width
        )
    }
    public func align(defaultAlignment:Alignment, defaultWrapping:Wrapping, width:Int, height:Int = 0) -> [String] {
        self.halign(
            defaultAlignment: defaultAlignment,
            defaultWrapping: defaultWrapping,
            width: width
        ).valign(alignment ?? defaultAlignment, height: height)
    }
    /// Pre-format cell text and calculate the minimum- and maximum widths
    /// for the given `Wrapping` style.
    public func preFormat(for wrapping:Wrapping) -> (preformat:Txt, minWidth:Int, maxWidth:Int) {


        switch wrapping {
        case .word, .word2:
            let trimmed:String = string.trim(.all)
            let singleSpaced = trimmed//.trimmingCharacters(in: CharacterSet(charactersIn: " "))
                .split(separator: " ", omittingEmptySubsequences: true)
            guard singleSpaced.isEmpty == false else {
                // empty string after cleanup
                return ("", 0, 0)
            }
            let lo = singleSpaced.reduce(Int.max, { Swift.min($0, $1.count) })
            let hi = singleSpaced.reduce(lo, { Swift.max($0, $1.count) })
            return (Txt(singleSpaced.joined(separator: " "),
                        alignment: alignment,
                        wrapping: wrapping),
                    lo,
                    hi)
        case .char, .cut:
            let trimmed:String = string.trim([.leadingWhiteSpaces, .trailingWhiteSpaces])
            return (Txt(trimmed, alignment: alignment, wrapping: wrapping), count, count)
        }
    }
}
// MARK: Keep
extension Array where Element == String {
    public func valign(_ horizontallyAligned:Alignment, height:Int = 0) -> [String] {

        //print("\(type(of: self)).valign(\(horizontallyAligned), height: \(height))")
        // Calculate (if it was not previously known)
        let forHeight:Int = height == 0 ? count : Swift.max(0, height)

        // Calculate how many row fragments we need to add for this cell
        let padAmount = Swift.max(0, forHeight - count)
        guard let hlen = first?.count else {
            return Array(repeating: String(), count: forHeight)
        }
        // Generate the horizontal cell fragment to be
        // used in padding
        let hpad:String = String(repeating: " ", count: hlen)
        // Pad vertically (=add empty cell fragments)
        // based on the alignment setting
        let ret:[String]
        switch horizontallyAligned {
        case .topLeft, .topRight, .topCenter:
            // Add pad framents to the end of the array
            ret = self + Array(repeating: hpad, count: padAmount)
        case .bottomLeft, .bottomRight, .bottomCenter:
            // Add pad framents to the beginning of the array
            ret = Array(repeating: hpad, count: padAmount) + self
        case .middleLeft, .middleRight, .middleCenter:
            // Add pad framents to the beginning and end of the array
            let topCount = padAmount / 2
            let bottomCount = Swift.max(0, forHeight - count - topCount)
            let topArray = Array(repeating: hpad, count: topCount)
            let bottomArray = Array(repeating: hpad, count: bottomCount)
            ret = topArray + self + bottomArray
        }
        return Array(ret.prefix(forHeight))
    }
}
extension Array where Element == Txt {
    // Simple two sweep approach
    internal func align(for columns:[FixedCol]) -> [[String]] {
        var alignedRow:[[String]] = []
        var rmax = 0
        var haligned:[[String]] = []

        var i = 0
        // Sweep 1
        for c in columns {
            let cell = c.ref < self.count ? self[c.ref] : Txt("")
            let h:[String] = cell.halign(for: c)
            rmax = Swift.max(rmax, h.count)
            haligned.append(h)
            i += 1
        }
        // Sweep 2
        for h in haligned {
            let v = h.valign(.topLeft, height: rmax)
            alignedRow.append(v)
            i += 1
        }
        return alignedRow
    }
}
import Foundation
extension Wrapping {
    public func nlSplitted(_ cell:Txt, compressingMultipleConsecutiveNewlinesIntoOne c:Bool = false) -> [Txt] {
        switch self {
        case .word:
            return cell.string.split(separator: "\n", omittingEmptySubsequences: c)
                .map({ Txt($0.description, alignment: cell.alignment, wrapping: cell.wrapping) })
        case .word2:
            return cell.string.split(separator: "\n", omittingEmptySubsequences: c)
                .map({ Txt($0.description, alignment: cell.alignment, wrapping: cell.wrapping) })
        case .char:
            return cell.string.split(separator: "\n", omittingEmptySubsequences: c)
                .map({ Txt($0.description, alignment: cell.alignment, wrapping: cell.wrapping) })
        case .cut:
            return cell.string.split(separator: "\n", omittingEmptySubsequences: c)
                .map({ Txt($0.description, alignment: cell.alignment, wrapping: cell.wrapping) })
        }
    }
}
