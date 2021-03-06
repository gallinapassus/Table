extension Substring {
    internal func split(to multipleOf:Int) -> [Substring] {
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

        /* Original implementation: */
         let wds = self
             .split(separator: " ", maxSplits: self.count, omittingEmptySubsequences: true)
             .flatMap({ $0.count > width ? $0.split(to: width) : [$0] })
         return wds         
    }
    internal func compressedWords(_ str:String, _ width:Int) -> [Substring] {
        words(to: width).compress(to: width)
    }
}
extension String {

    internal func render(to width:Int, alignment:Alignment = .default, padding with:Character = " ") -> String {
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

    @inline(__always)
    internal func render(to width:Int, alignment:Alignment = .default, padding with:Character = " ") -> String {
        String(self).render(to: width, alignment: alignment, padding: with)
    }
}
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
}

extension Array where Element: RangeReplaceableCollection, Element.Element:Collection {
    internal func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        return (self.first ?? Element()).indices.map { index in
            self.map { $0[index] }
        }
    }
}
/*
extension Array where Element == Txt {
    internal func fragment(for column:Col) -> [HorizontallyAligned] {
        map { $0.fragment(for: column) }
    }
}*/
extension ArraySlice where Element == HorizontallyAligned {
    @inline(__always)
    internal var alignVertically:[[String]] {
        let height = reduce(0, { Swift.max($0, $1.lines.count) })
        let fragments:[ArraySlice<String>] = map {
            guard $0.lines.count != height else {
                //print("here", $0.lines.count, height, ArraySlice<String>($0.lines))
                return ArraySlice<String>($0.lines)
            }
            //print("align", $0.lines, height)
            return align($0, forHeight: height)
        }
        return fragments.transposed()
    }
}
internal func align(_ horizontallyAligned:HorizontallyAligned, forHeight:Int) -> ArraySlice<String> {
    let padAmount = Swift.max(0, forHeight - horizontallyAligned.lines.count/*horizontallyAligned.width.rawValue*/)
    guard padAmount > 0 else {
        return horizontallyAligned.lines.prefix(forHeight)
    }
    let hpad = String(repeating: " ", count: horizontallyAligned.width.value)
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
