#if canImport(OSLog)
import OSLog
#endif
import Foundation
public enum Wrapping {
    case word
}
public enum Alignment : CaseIterable {
    case topRight, topLeft, topCenter
    case bottomRight, bottomLeft, bottomCenter
    case middleRight, middleLeft, middleCenter
}
public struct Col {
    public let header:Txt?
    fileprivate (set) public var width:Int
    public let alignment:Alignment
    public let wrapping:Wrapping
    public init(header:Txt?, width:Int, alignment:Alignment, wrapping:Wrapping = .word) {
        self.header = header
        self.width = width
        self.alignment = alignment
        self.wrapping = wrapping
    }
}
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

public struct Tbl {
    public let data:[[Txt]]
    public let columns:[Col]
    public let title:Txt?
    public let frameStyle:FrameElements
    public let frameRenderingOptions:FrameRenderingOptions
    private var actualColumns:[Col]
    public init(_ title:Txt?, columns: [Col], data:[[Txt]],
                frameStyle:FrameElements = .rounded,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        let t0 = DispatchTime.now().uptimeNanoseconds
        self.data = data
        self.columns = columns
        self.title = title
        self.frameStyle = frameStyle
        self.frameRenderingOptions = frameRenderingOptions
        if columns.allSatisfy({ $0.width > 0 }) {
            self.actualColumns = columns
        }
        else {
            self.actualColumns = columns
            let recalc = columns.enumerated().compactMap({ columns[$0.offset].width > 0 ? nil : $0.offset })
//            print("recalculating column widths for columns \(recalc.map { columns[$0].header.string }.joined(separator: ", "))")
            for i in recalc {
                for r in data {
                    guard r.count > i else { continue }
                    let m = Swift.max(self.actualColumns[i].width, r[i].count)
                    self.actualColumns[i].width =  m//Swift.max(self.actualColumns[i].width, r[i].count)
                }
                if self.actualColumns[i].width == 0, let hdr = columns[i].header {
                    let smrt = Swift.min(hdr.count, columns.reduce(0, { $0 + ($1.header?.count ?? 0) }) / columns.count)
                    self.actualColumns[i].width = Swift.max(1, smrt)
                }
            }
        }
        let t1 = DispatchTime.now().uptimeNanoseconds
        //print("Calculated widths:", actualColumns.forEach { print($0.header.string, $0.width, separator: ": ") } )
        print(#function, Double(t1 - t0) / 1_000_000)
    }
    public init(_ title:String, columns: [Col], data:[[Txt]],
                frameStyle:FrameElements = .rounded,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        self.init(Txt(title, .middleCenter), columns: columns, data: data,
                  frameStyle: frameStyle, frameRenderingOptions: frameRenderingOptions)
    }

    public func columnizedHeaders() -> [[String]] {
        let t0 = DispatchTime.now().uptimeNanoseconds
        let cc:[[String]] = columns
            .enumerated()
            .map({ i,c in
                let w = actualColumns[i].width == 0 ? (c.header?.count ?? 1) : actualColumns[i].width
                return (c.header?.string ?? "")
                    .words(to: w)
                    .compress(to: w)
                    .map {
                        $0.render(to: w,
                                  alignment: actualColumns[i].header?.alignment ?? actualColumns[i].alignment)
                    }
            })
        let t1 = DispatchTime.now().uptimeNanoseconds
        print(#function, Double(t1 - t0) / 1_000_000)
        return cc
    }
    public func render(into: inout String) {
        let t0 = DispatchTime.now().uptimeNanoseconds
        let hdrs = columnizedHeaders()
        let rc = hdrs.reduce(0, { Swift.max($0, $1.count) })
        let headers:[[String]] = hdrs.enumerated().map({ i,f in
            if f.count < rc {
                let alignment = columns[i].header?.alignment ?? columns[i].alignment
                switch alignment {
                case .topLeft, .topRight, .topCenter:
                    let str = "".render(to: self.actualColumns[i].width, alignment: alignment)
                    return f + Array(repeating: str, count: rc - f.count)
                case .bottomLeft, .bottomRight, .bottomCenter:
                    let str = "".render(to: self.actualColumns[i].width, alignment: alignment)
                    return Array(repeating: str, count: rc - f.count) + f
                case .middleLeft, .middleRight, .middleCenter:
                    let tc = (rc - f.count) / 2
                    let bc = rc - f.count - tc
                    let ta = Array(repeating: "".render(to: self.actualColumns[i].width, alignment: alignment),
                                   count: tc)
                    let ba = Array(repeating: "".render(to: self.actualColumns[i].width, alignment: alignment),
                                   count: bc)
                    return ta + f + ba
                }
            }
            else {
                return f
            }
        })
        let hasHeaderLabels:Bool = columns.compactMap({ $0.header }).reduce(0, { $0 + $1.count }) > 0
        let hasTitleTop = frameStyle.topLeftCorner + actualColumns
            .map({ String(repeating: frameStyle.topHorizontalSeparator, count: $0.width) })
            .joined(separator: String(repeating: frameStyle.topHorizontalSeparator, count: frameStyle.topHorizontalVerticalSeparator.count)) + frameStyle.topRightCorner
        let noTitleHasHeaders = frameStyle.topLeftCorner + actualColumns
            .map({ String(repeating: frameStyle.topHorizontalSeparator, count: $0.width) })
            .joined(separator: frameStyle.topHorizontalVerticalSeparator) + frameStyle.topRightCorner
        let hasTitleAndHeaders = frameStyle.insideLeftVerticalSeparator + actualColumns
            .map({ String(repeating: frameStyle.insideHorizontalSeparator, count: $0.width) })
            .joined(separator: frameStyle.topHorizontalVerticalSeparator) + frameStyle.insideRightVerticalSeparator
        let midhdiv = frameStyle.insideLeftVerticalSeparator + actualColumns
            .map({ String(repeating: frameStyle.insideHorizontalSeparator, count: $0.width) })
            .joined(separator: frameStyle.insideHorizontalVerticalSeparator) + frameStyle.insideRightVerticalSeparator
        let bottomhdiv = frameStyle.bottomLeftCorner + actualColumns
            .map({ String(repeating: frameStyle.bottomHorizontalSeparator, count: $0.width) })
            .joined(separator: frameStyle.bottomHorizontalVerticalSeparator) + frameStyle.bottomRightCorner



        if let title = title {
            print(hasTitleTop, to: &into)
            let totw = actualColumns.reduce(0, { $0 + $1.width }) + ((actualColumns.count - 1) * frameStyle.insideVerticalSeparator.count)
            let rowfrags = title.string.words(to: totw)
                    .compress(to: totw)
                    .map { $0.render(to: totw, alignment: title.alignment ?? .bottomCenter) }
            for r in rowfrags {
                print("\(frameStyle.leftVerticalSeparator)\(r)\(frameStyle.rightVerticalSeparator)", to: &into)
            }
        }
        if hasHeaderLabels {
            if title == nil {
                print("***", to: &into)
                print(noTitleHasHeaders, to: &into)
            }
            else {
                print(hasTitleAndHeaders, to: &into)
            }
            let trans = headers.transposed()
            for row in trans.indices {
                print("\(frameStyle.leftVerticalSeparator)\(trans[row].joined(separator: frameStyle.insideVerticalSeparator))\(frameStyle.rightVerticalSeparator)", to: &into)
            }
            print(midhdiv, to: &into)
        }
        else {
            if title == nil {
                print(noTitleHasHeaders, to: &into)
            }
            else {
                print(hasTitleAndHeaders, to: &into)
            }
        }
        let t1 = DispatchTime.now().uptimeNanoseconds
        print(#function, "Header:", Double(t1 - t0) / 1_000_000)


        for i in data.indices {
            let row = data[i]
            var rc = 0
            var columnized:[[String]] = []
            for (j,c) in row.prefix(columns.count).enumerated() {
                let a = c.alignment ?? columns[j].alignment
                let frags = c.string
                    .words(to: actualColumns[j].width).compress(to: actualColumns[j].width)
                    .map { $0.render(to: actualColumns[j].width, alignment: a) }
                rc = Swift.max(rc, frags.count)
                columnized.append(frags)
            }
            let missing = Swift.max(0, (columns.count - row.count))
            for l in 0..<missing {
                let arr = Array(repeating: String(repeating: " ", count: actualColumns[row.count + l].width), count: rc)
                columnized.append(contentsOf: [arr])
            }
            // Add missing column data
            for (k,r) in columnized.enumerated() {
                if r.count < rc {
                    switch data[i][k].alignment ?? columns[k].alignment {
                    case .topLeft, .topRight, .topCenter:
                        columnized[k].append(contentsOf: Array(repeating: String("").render(to: actualColumns[k].width), count: rc - r.count))
                    case .middleLeft, .middleRight, .middleCenter:
                        let tc = (rc - r.count) / 2
                        let bc = rc - r.count - tc
                        let ta = Array(repeating: String().render(to: actualColumns[k].width), count: tc)
                        let ba = Array(repeating: String().render(to: actualColumns[k].width), count: bc)
                        columnized[k] = ta + columnized[k] + ba
                    case .bottomLeft, .bottomRight, .bottomCenter:
                        columnized[k] = Array(repeating: String().render(to: actualColumns[k].width), count: rc - r.count) + columnized[k]
                    }
                }
            }
            for f in columnized.transposed() {
                print("\(frameStyle.leftVerticalSeparator)\(f.joined(separator: frameStyle.insideVerticalSeparator))\(frameStyle.rightVerticalSeparator)", to: &into)
            }
            if i != data.index(before: data.endIndex) {
                print(midhdiv, to: &into)
            }
        }
        print(bottomhdiv, to: &into)
        let t2 = DispatchTime.now().uptimeNanoseconds
        print(#function, "Rows:", Double(t2 - t1) / 1_000_000)
    }
}
