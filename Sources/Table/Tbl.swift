import Foundation

public struct Tbl {
    public let data:[[Txt]]
    public let columns:[Col]
    public let title:Txt?
    public let frameStyle:FrameElements
    public let frameRenderingOptions:FrameRenderingOptions
    private var actualColumns:[Col] = []
    public init(_ title:Txt?, columns: [Col], data:[[Txt]],
                frameStyle:FrameElements = .rounded,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        let t0 = DispatchTime.now().uptimeNanoseconds
        self.data = data
        self.columns = columns
        self.title = title
        self.frameStyle = frameStyle
        self.frameRenderingOptions = frameRenderingOptions

        // Calculate column widths for autowidth columns
        self.actualColumns = calculateAutowidths()

        let t1 = DispatchTime.now().uptimeNanoseconds
        print(#function, Double(t1 - t0) / 1_000_000)
    }
    private func calculateAutowidths() -> [Col] {
        // Figure out actual column widths (for columns which have
        // specified width as 0 => autowidth)
        if columns.allSatisfy({ $0.width > 0 }) {
            // No autowidths defined, use columns as they are defined
            return columns
        }
        else {
            // One or more columns are autowidth columns
            var tmp = columns
            let recalc = columns.enumerated().compactMap({ columns[$0.offset].width > 0 ? nil : $0.offset })
            //print("recalc indices", recalc)
            for i in recalc {
                for r in data {
                    guard r.count > i else { continue }
                    let m = Swift.max(tmp[i].width.rawValue, r[i].count)
                    tmp[i].width = .value(m)
                }
                if tmp[i].width == 0, let hdr = columns[i].header {
                    let smrt = Swift.min(hdr.count, columns.reduce(0, { $0 + ($1.header?.count ?? 0) }) / columns.count)
                    tmp[i].width = .value(Swift.max(1, smrt))
                }
            }
            //print("actual", tmp.map { $0.width })
            return tmp
        }
    }
    public init(_ title:String, columns: [Col], data:[[Txt]],
                frameStyle:FrameElements = .rounded,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        self.init(Txt(title, .middleCenter), columns: columns, data: data,
                  frameStyle: frameStyle, frameRenderingOptions: frameRenderingOptions)
    }
    public func render(into: inout String) {
        let t0 = DispatchTime.now().uptimeNanoseconds



        // Prepare dividers
        let hasHeaderLabels:Bool = columns.compactMap({ $0.header }).reduce(0, { $0 + $1.count }) > 0
        let hasTitleTop = frameStyle.topLeftCorner + actualColumns
            .map({ String(repeating: frameStyle.topHorizontalSeparator, count: $0.width.rawValue) })
            .joined(separator: String(repeating: frameStyle.topHorizontalSeparator, count: frameStyle.topHorizontalVerticalSeparator.count)) + frameStyle.topRightCorner + "\n"
        let noTitleHasHeaders = frameStyle.topLeftCorner + actualColumns
            .map({ String(repeating: frameStyle.topHorizontalSeparator, count: $0.width.rawValue) })
            .joined(separator: frameStyle.topHorizontalVerticalSeparator) + frameStyle.topRightCorner + "\n"
        let hasTitleAndHeaders = frameStyle.insideLeftVerticalSeparator + actualColumns
            .map({ String(repeating: frameStyle.insideHorizontalSeparator, count: $0.width.rawValue) })
            .joined(separator: frameStyle.topHorizontalVerticalSeparator) + frameStyle.insideRightVerticalSeparator + "\n"
        let midhdiv = frameStyle.insideLeftVerticalSeparator + actualColumns
            .map({ String(repeating: frameStyle.insideHorizontalSeparator, count: $0.width.rawValue) })
            .joined(separator: frameStyle.insideHorizontalVerticalSeparator) + frameStyle.insideRightVerticalSeparator + "\n"
        let bottomhdiv = frameStyle.bottomLeftCorner + actualColumns
            .map({ String(repeating: frameStyle.bottomHorizontalSeparator, count: $0.width.rawValue) })
            .joined(separator: frameStyle.bottomHorizontalVerticalSeparator) + frameStyle.bottomRightCorner + "\n"


        if let title = title {
            into.append(hasTitleTop)
            let titleColumnWidth = actualColumns
                .reduce(0, { $0 + $1.width.rawValue }) + ((actualColumns.count - 1) * frameStyle.insideVerticalSeparator.count)

            let alignedTitle = title
                .fragment(fallback: .middleCenter, width: titleColumnWidth)
                .verticallyAligned

            for f in alignedTitle {
                into.append(frameStyle.leftVerticalSeparator +
                        f.joined(separator: frameStyle.insideVerticalSeparator) +
                        frameStyle.rightVerticalSeparator + "\n")
            }
        }
        if hasHeaderLabels {
            let alignedColumnHeaders = actualColumns
                .compactMap({ ($0.header ?? Txt(""))
                                .fragment(for: $0) })
                .dropFirst(0) // <= Convert Array to ArraySlice
                .alignVertically
            if title == nil {
                into.append(noTitleHasHeaders)
            }
            else {
                into.append(hasTitleAndHeaders)
            }


            for f in alignedColumnHeaders {
                into.append(frameStyle.leftVerticalSeparator +
                        f.joined(separator: frameStyle.insideVerticalSeparator) +
                        frameStyle.rightVerticalSeparator + "\n")
            }
            into.append(midhdiv)
        }
        else {
            if title == nil {
                into.append(noTitleHasHeaders)
            }
            else {
                into.append(hasTitleAndHeaders)
            }
        }
        let t1 = DispatchTime.now().uptimeNanoseconds
        print(#function, "Header:", Double(t1 - t0) / 1_000_000, "ms")

        var cache:[UInt32:[Int:HorizontallyAligned]] = [:]
        var cacheHits:Int = 0
        var cacheMisses:Int = 0
        // Main loop to render row/column data
        for (i,row) in data.enumerated() {
            //let a0 = DispatchTime.now().uptimeNanoseconds
            var columnized:ContiguousArray<HorizontallyAligned> = []
            let maxHeight = row
                .prefix(columns.count)
                .enumerated()
                .map({ j,col in

                    if actualColumns[j].contentHint == .repetitive {

                        // Combine width & alignment
                        let u32:UInt32 = (UInt32(actualColumns[j].width.rawValue) << 16) +
                            UInt32(col.alignment?.rawValue ?? actualColumns[j].alignment.rawValue)

                        if let fromCache = cache[u32]?[col.string.hashValue] {
                            columnized.append(fromCache)
                            cacheHits += 1
                            return fromCache.lines.count
                        }
                        else {
                            let fragmented = col.fragment(for: actualColumns[j])
                            // Write to cache
                            cache[u32, default:[:]][col.string.hashValue] = fragmented
                            columnized.append(fragmented)
                            cacheMisses += 1
                            return fragmented.lines.count
                        }
                    }
                    else {
                        let fragmented = col.fragment(for: actualColumns[j])
                        columnized.append(fragmented)
                        return fragmented.lines.count
                    }
                })
                .reduce(0, { Swift.max($0, $1) })
            let missingColumnCount = Swift.max(0, (columns.count - columnized.count))
            let currentCount = columnized.count
            //let a1 = DispatchTime.now().uptimeNanoseconds
            for k in 0..<missingColumnCount {
                let emptyLineFragment = "".render(to: actualColumns[currentCount + k].width.rawValue) // TODO: Precalc these!
                columnized.append(
                    HorizontallyAligned(lines: Array(repeating: emptyLineFragment, count: maxHeight),
                                        alignment: .topLeft,
                                        width: actualColumns[currentCount + k].width)
                )
            }
            //let a2 = DispatchTime.now().uptimeNanoseconds
            for x in columnized.prefix(actualColumns.count).alignVertically {
                into.append(frameStyle.leftVerticalSeparator + x.joined(separator: frameStyle.insideVerticalSeparator) + frameStyle.rightVerticalSeparator + "\n")
            }
            if i != data.index(before: data.endIndex) {
                into.append(midhdiv)
            }
            //let a3 = DispatchTime.now().uptimeNanoseconds
            //print(a1-a0, a2-a1, a3-a2)
        }
        into.append(bottomhdiv)
        let t2 = DispatchTime.now().uptimeNanoseconds
        print(#function, "Rows:", Double(t2 - t1) / 1_000_000, "ms")
        print(#function, "Total:",
              Double(t1 - t0) / 1_000_000, "ms",
              "+",
              Double(t2 - t1) / 1_000_000, "ms",
              "=>",
              Double(t2 - t0) / 1_000_000, "ms")
        let nf = NumberFormatter()
        nf.minimumFractionDigits = 1
        nf.maximumFractionDigits = 1
        print(#function, "hits =", cacheHits,
              ", misses =", cacheMisses,
              ", hit-miss ratio = ", nf.string(from: NSNumber(value: (Double(cacheHits) / Double(cacheMisses)))) ?? "?")
//        dump(cac)
    }
}
