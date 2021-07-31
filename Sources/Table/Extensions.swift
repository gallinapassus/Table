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
        guard width > 0 else {
            return String(self)
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
