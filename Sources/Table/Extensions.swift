extension Substring {
    func split(to multipleOf:Int) -> [Substring] {
        guard multipleOf > 0 else {
            return [Substring(self)]
        }
        var arr:[Substring] = []
        var c = startIndex
        while c != endIndex {
            while c < endIndex, self[c].isWhitespace {
                c = self.index(after: c)
            }
            guard var e = self.index(c, offsetBy: multipleOf, limitedBy: endIndex) else {
                arr.append(self[c..<endIndex])
                return arr
            }
            while self[self.index(before: e)].isWhitespace && e != c {
                e = self.index(before: e)
            }
            arr.append(self[c..<e])
            c = e
        }
        return arr
    }
}
extension String {
    public func fragment(where character: (Character) -> Bool) -> [Substring] {
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
    func words(to width:Int) -> [Substring] {

        /* Original implementation:
         let wds = self
             .split(separator: " ", maxSplits: self.count, omittingEmptySubsequences: true)
             .flatMap({ $0.count > width ? $0.split(to: width) : [$0] })
         return wds
         */

        let customSplitted:[Substring] = self.fragment(where: { c in
            c.isPunctuation &&
                (c.isWhitespace == false &&
                    c != "\"" &&
                    c != "'" &&
                    c.isCurrencySymbol == false)
        })
        .flatMap { $0.split(maxSplits: $0.count,
                            omittingEmptySubsequences: true, whereSeparator: { $0.isWhitespace })
        }
        let wds = customSplitted
            .flatMap({ $0.count > width ? $0.split(to: width) : [$0] })
        return wds
    }
    internal func compressedWords(_ str:String, _ width:Int) -> [Substring] {
        words(to: width).compress(to: width)
    }
}
extension String {
    func render(to width:Int, alignment:Alignment = .topLeft, padding with:Character = " ") -> String {
        guard width > 0 else {
            return self
        }
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

extension Substring {
    func render(to width:Int, alignment:Alignment = .topLeft, padding with:Character = " ") -> String {
        String(self).render(to: width, alignment: alignment, padding: with)
    }
}
extension Array where Element == Substring {
    // Reverse-greedy
    func compress(to width:Int, binding with:Character = " ") -> [Substring] {
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
    /* Forward-greedy
    func compress_b(to width:Int, binding with:Character = " ") -> [Substring] {
        guard isEmpty == false else {
            return []
        }
        var lidx = startIndex
        var ridx = index(after: lidx)
        while ridx != endIndex {
            if self[lidx].count + self[ridx].count + 1 <= width {
                return (self[..<lidx] +
                            [Substring([self[lidx], self[ridx]].joined(separator: "\(with)"))] +
                            self[index(after: ridx)...]).compress(to: width)
            }
            else {
                lidx = self.index(after: lidx)
                ridx = self.index(after: ridx)
                if ridx == index(before: endIndex) {
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
    }*/
}

extension Array where Element: RangeReplaceableCollection, Element.Element:Collection {
    internal func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        return (self.first ?? Element()).indices.map { index in
            self.map{ $0[index] }
        }
    }
}
extension Array where Element == Txt {
    internal func fragment(for column:Col) -> [HorizontallyAligned] {
        map { $0.fragment(for: column) }
    }
}
/*
extension Array where Element == HorizontallyAligned {
    internal var alignVertically:[[String]] {
        let height = reduce(0, { Swift.max($0, $1.lines.count) })
        return map { align($0, forHeight: height) }.transposed()
    }
}*/
extension ArraySlice where Element == HorizontallyAligned {
    internal var alignVertically:[[String]] {
        let height = reduce(0, { Swift.max($0, $1.lines.count) })
        /*let height = filter({ $0.wrapping != .fit }).reduce(0, { Swift.max($0, $1.lines.count) })*/
        let foo:[ArraySlice<String>] = map {
            guard $0.lines.count != height else {
                return ArraySlice<String>($0.lines)
            }
            return align($0, forHeight: height)
        }
        return foo.transposed()
    }
}
internal func align(_ horizontallyAligned:HorizontallyAligned, forHeight:Int) -> ArraySlice<String> {
    let hpad = String(repeating: " ", count: horizontallyAligned.width.rawValue)
    let padAmount = Swift.max(0, forHeight - horizontallyAligned.lines.count)
    let ret:[String]
    switch horizontallyAligned.alignment {
    case .topLeft, .topRight, .topCenter:
        ret = horizontallyAligned.lines + ArraySlice(repeating: hpad, count: padAmount)
    case .bottomLeft, .bottomRight, .bottomCenter:
        ret = ArraySlice(repeating: hpad, count: padAmount) + horizontallyAligned.lines
    case .middleLeft, .middleRight, .middleCenter:
        let topCount = padAmount / 2
        let bottomCount = forHeight - horizontallyAligned.lines.count - topCount
        let topArray = ArraySlice(repeating: hpad, count: topCount)
        let bottomArray = ArraySlice(repeating: hpad, count: bottomCount)
        ret = topArray + horizontallyAligned.lines + bottomArray
    }
    return ret.prefix(forHeight)
}
