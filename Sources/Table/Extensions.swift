extension Substring {
    func split(to multipleOf:Int) -> [Substring] {
        guard multipleOf > 0 else {
            return [Substring(self)]
        }
        var arr:[Substring] = []
        var c = startIndex
        while c != endIndex {
            guard let e = self.index(c, offsetBy: multipleOf, limitedBy: endIndex) else {
                arr.append(self[c..<endIndex])
                return arr
            }
            arr.append(self[c..<e])
            c = e
        }
        return arr
    }
}
extension String {
    func words(to width:Int) -> [Substring] {
        let wds = self
            .split(separator: " ", maxSplits: self.count, omittingEmptySubsequences: true)
            .flatMap({ $0.count > width ? $0.split(to: width) : [$0] })
        return wds
    }
    func split(to multipleOf:Int) -> [Substring] {
        guard multipleOf > 0 else {
            return [Substring(self)]
        }
        var arr:[Substring] = []
        var c = self.startIndex
        while c != endIndex {
            while self[c].isWhitespace, c != endIndex {
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
            let start = pad.startIndex..<pad.index(pad.startIndex, offsetBy: padAmount / 2, limitedBy: pad.endIndex)!
            let end = start.upperBound..<pad.endIndex
            return String(pad[start]) + String(self) + String(pad[end])
        }
    }
}

extension Substring {
    func render(to width:Int, alignment:Alignment = .topLeft, padding with:Character = " ") -> String {
        String(self).render(to: width, alignment: alignment, padding: with)
    }
}
extension Array where Element == Substring {
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
}

extension Array where Element: RangeReplaceableCollection, Element.Element:Collection {
    func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        guard let firstRow = self.first else { return [] }
        return firstRow.indices.map { index in
            self.map{ $0[index] }
        }
    }
}
extension Array where Element == Txt {
    func fragment(for column:Col, with wrapper:((String, Int)->[Substring])? = nil) -> [HorizontallyAligned] {
        map {
            $0.fragment(for: column,
                        with: wrapper ?? $0.string.compressedWords(_:_:))
        }
    }
}
extension Array where Element == HorizontallyAligned {
    var alignVertically:[[String]] {
        let height = reduce(0, { Swift.max($0, $1.lines.count) })
        let ret = map { align($0, forHeight: height) }
        return ret.transposed()
    }
}
public func align(_ horizontallyAligned:HorizontallyAligned, forHeight:Int) -> ArraySlice<String> {
    //let t0 = DispatchTime.now().uptimeNanoseconds
    let hpad = "".render(to: horizontallyAligned.width,
                         alignment: horizontallyAligned.alignment)
    let padAmount = Swift.max(0, forHeight - horizontallyAligned.lines.count)
    let ret:[String]
    switch horizontallyAligned.alignment {
    case .topLeft, .topRight, .topCenter:
        ret = horizontallyAligned.lines + Array(repeating: hpad, count: padAmount)
    case .bottomLeft, .bottomRight, .bottomCenter:
        ret = Array(repeating: hpad, count: padAmount) + horizontallyAligned.lines
    case .middleLeft, .middleRight, .middleCenter:
        let topCount = padAmount / 2
        let bottomCount = forHeight - horizontallyAligned.lines.count - topCount
        let topArray = Array(repeating: hpad, count: topCount)
        let bottomArray = Array(repeating: hpad, count: bottomCount)
        ret = topArray + horizontallyAligned.lines + bottomArray
    }
    //let t1 = DispatchTime.now().uptimeNanoseconds
    //print(#function, Double(t1 - t0) / 1_000_000)
    return ret.prefix(forHeight)
}
