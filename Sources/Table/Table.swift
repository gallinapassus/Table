#if canImport(OSLog)
import OSLog
#endif
import Foundation

public struct HorizontallyAligned {
    let lines:[String]
    let alignment:Alignment
    let width:Int
    var alignVertically:[[String]] {
        [align(self, forHeight: lines.count)].transposed()
    }
}
public enum Wrapping {
    case word // Prefer wrapping at word boundary (if possible)
    case char // Wrap at character boundary
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
                    let m = Swift.max(/*self.actualColumns[i].width*/tmp[i].width, r[i].count)
                    tmp[i].width =  m
                }
                if /*self.actualColumns[i].width*/tmp[i].width == 0, let hdr = columns[i].header {
                    let smrt = Swift.min(hdr.count, columns.reduce(0, { $0 + ($1.header?.count ?? 0) }) / columns.count)
                    tmp[i].width = Swift.max(1, smrt)
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
            let titleColumnWidth = actualColumns
                .reduce(0, { $0 + $1.width }) + ((actualColumns.count - 1) * frameStyle.insideVerticalSeparator.count)

            let alignedTitle = title
                .fragment(fallback: .middleCenter, width: titleColumnWidth)
                .alignVertically

            for f in alignedTitle {
                print(frameStyle.leftVerticalSeparator +
                        f.joined(separator: frameStyle.insideVerticalSeparator) +
                        frameStyle.rightVerticalSeparator, to: &into)
            }
        }
        if hasHeaderLabels {
            let alignedColumnHeaders = actualColumns
                .compactMap({ ($0.header ?? Txt("")).fragment(for: $0) })
                .alignVertically
            if title == nil {
                print(noTitleHasHeaders, to: &into)
            }
            else {
                print(hasTitleAndHeaders, to: &into)
            }


            for f in alignedColumnHeaders {
                print(frameStyle.leftVerticalSeparator +
                        f.joined(separator: frameStyle.insideVerticalSeparator) +
                        frameStyle.rightVerticalSeparator, to: &into)
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
        print(#function, "Header:", Double(t1 - t0) / 1_000_000, "ms")


        for (i,row) in data.enumerated() {
            var columnized:[HorizontallyAligned] = []
            let maxHeight = row
                .prefix(columns.count)
                .enumerated()
                .map({ j,col in
                    let fragmented = col.fragment(for: actualColumns[j])
                    columnized.append(fragmented)
                    return fragmented.lines.count
                })
                .reduce(0, { Swift.max($0, $1) })
            let missingColumnCount = Swift.max(0, (columns.count - columnized.count))
            let currentCount = columnized.count
            for k in 0..<missingColumnCount {
                let emptyLineFragment = "".render(to: actualColumns[currentCount + k].width) // TODO: Precalc these!
                columnized.append(
                    HorizontallyAligned(lines: Array(repeating: emptyLineFragment, count: maxHeight),
                                        alignment: .topLeft,
                                        width: actualColumns[currentCount + k].width)
                )
            }
            for x in Array(columnized.prefix(columns.count)).alignVertically {
                print("\(frameStyle.leftVerticalSeparator)\(x.joined(separator: frameStyle.insideVerticalSeparator))\(frameStyle.rightVerticalSeparator)", to: &into)
            }
            if i != data.index(before: data.endIndex) {
                print(midhdiv, to: &into)
            }
        }
        print(bottomhdiv, to: &into)
        let t2 = DispatchTime.now().uptimeNanoseconds
        print(#function, "Rows:", Double(t2 - t1) / 1_000_000, "ms")
    }
}
