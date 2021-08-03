#if canImport(OSLog)
import OSLog
#endif
import Foundation

internal class HorizontallyAligned {
    let lines:[String]
    let alignment:Alignment
    let width:Width
    lazy var alignVertically:[[String]] = {
        [align(self, forHeight: lines.count)].transposed()
    }()
    internal init(lines: [String], alignment: Alignment, width: Width = .auto) {
        self.lines = lines
        self.alignment = alignment
        self.width = width
    }
}
public enum Width : RawRepresentable, Equatable, Hashable, Comparable, ExpressibleByIntegerLiteral {
    public init?(rawValue: Int) {
        let allowedRange = 1...Int16.max
        if rawValue == -1 {
            self = .auto
        }
        else if rawValue == 0 {
            self = .hidden
        }
        else if let i16 = Int16(exactly: rawValue),
                allowedRange.contains(i16) {
            self = .value(rawValue)
        }
        else {
            fatalError("\(Self.self) must be in range \(allowedRange) or .auto or .hidden")
        }
    }

    public var rawValue: Int {
        switch self {
        case .auto: return -1
        case .hidden: return 0
        case let .value(i): return i
        }
    }

    public init(integerLiteral value: RawValue) {
        self = .value(Swift.min(Int(Int16.max), value))
    }

    public typealias RawValue = Int
    public typealias IntegerLiteralType = RawValue
    case auto, hidden, value(Int)
}
public enum Wrapping : UInt8, RawRepresentable {
    case word // Prefer wrapping at word boundary (if possible)
    case char // Wrap at character boundary
}
public enum Alignment : UInt8, RawRepresentable, CaseIterable {
    case topRight, topLeft, topCenter
    case bottomRight, bottomLeft, bottomCenter
    case middleRight, middleLeft, middleCenter
}
public enum ColumnContentHint {
    case unique, repetitive
}
public struct Col {
    public let header:Txt?
    fileprivate (set) public var width:Width
    public let alignment:Alignment
    public let wrapping:Wrapping
    public let contentHint:ColumnContentHint
    public init(header:Txt?, width:Width = .auto, alignment:Alignment, wrapping:Wrapping = .word, contentHint:ColumnContentHint = .repetitive) {
        self.header = header
        self.width = width
        self.alignment = alignment
        self.wrapping = wrapping
        self.contentHint = contentHint
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
                    let m = Swift.max(tmp[i].width.rawValue, r[i].count)
                    tmp[i].width =  .value(m)
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
            .joined(separator: String(repeating: frameStyle.topHorizontalSeparator, count: frameStyle.topHorizontalVerticalSeparator.count)) + frameStyle.topRightCorner
        let noTitleHasHeaders = frameStyle.topLeftCorner + actualColumns
            .map({ String(repeating: frameStyle.topHorizontalSeparator, count: $0.width.rawValue) })
            .joined(separator: frameStyle.topHorizontalVerticalSeparator) + frameStyle.topRightCorner
        let hasTitleAndHeaders = frameStyle.insideLeftVerticalSeparator + actualColumns
            .map({ String(repeating: frameStyle.insideHorizontalSeparator, count: $0.width.rawValue) })
            .joined(separator: frameStyle.topHorizontalVerticalSeparator) + frameStyle.insideRightVerticalSeparator
        let midhdiv = frameStyle.insideLeftVerticalSeparator + actualColumns
            .map({ String(repeating: frameStyle.insideHorizontalSeparator, count: $0.width.rawValue) })
            .joined(separator: frameStyle.insideHorizontalVerticalSeparator) + frameStyle.insideRightVerticalSeparator
        let bottomhdiv = frameStyle.bottomLeftCorner + actualColumns
            .map({ String(repeating: frameStyle.bottomHorizontalSeparator, count: $0.width.rawValue) })
            .joined(separator: frameStyle.bottomHorizontalVerticalSeparator) + frameStyle.bottomRightCorner


        if let title = title {
            print(hasTitleTop, to: &into)
            let titleColumnWidth = actualColumns
                .reduce(0, { $0 + $1.width.rawValue }) + ((actualColumns.count - 1) * frameStyle.insideVerticalSeparator.count)

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

        var cache:[UInt32:[Int:HorizontallyAligned]] = [:]
        var cacheHits:Int = 0
        var cacheMisses:Int = 0
        // Main loop to render row/column data
        for (i,row) in data.enumerated() {
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
                            cache[u32, default:[:]][col.string.hashValue] = fragmented
                            columnized.append(fragmented)
                            cacheMisses += 1
                            return fragmented.lines.count
                        }

                        /*
                        if let fromCache = cache[col.string.hashValue]?[actualColumns[j].width.rawValue]?[col.alignment ?? actualColumns[j].alignment] {
                            //print("MATCH for '\(col.string)'")
                            columnized.append(HorizontallyAligned(lines: fromCache, alignment: col.alignment ?? actualColumns[j].alignment, width: actualColumns[j].width))
                            cacheHits += 1
                            return fromCache.count
                        }
                        else {
                            let fragmented = col.fragment(for: actualColumns[j])
                            //print("fragmenting \(actualColumns[j].width) '\(col.string)' -> \(fragmented.lines)")
                            cache[col.string.hashValue, default:[:]][actualColumns[j].width.rawValue, default:[:]][col.alignment ?? actualColumns[j].alignment, default:[]] = fragmented.lines
                            columnized.append(fragmented)
                            cacheMisses += 1
                            return fragmented.lines.count
                        }
                         */
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
            for k in 0..<missingColumnCount {
                let emptyLineFragment = "".render(to: actualColumns[currentCount + k].width.rawValue) // TODO: Precalc these!
                columnized.append(
                    HorizontallyAligned(lines: Array(repeating: emptyLineFragment, count: maxHeight),
                                        alignment: .topLeft,
                                        width: actualColumns[currentCount + k].width)
                )
            }

            for x in columnized.prefix(actualColumns.count).alignVertically {
                print("\(frameStyle.leftVerticalSeparator)\(x.joined(separator: frameStyle.insideVerticalSeparator))\(frameStyle.rightVerticalSeparator)", to: &into)
            }
            if i != data.index(before: data.endIndex) {
                print(midhdiv, to: &into)
            }
        }
        print(bottomhdiv, to: &into)
        let t2 = DispatchTime.now().uptimeNanoseconds
        print(#function, "Rows:", Double(t2 - t1) / 1_000_000, "ms")
        print(#function, "Total:",
              Double(t1 - t0) / 1_000_000, "ms",
              "+",
              Double(t2 - t1) / 1_000_000, "ms",
              "=>",
              Double(t2 - t0) / 1_000_000, "ms")
        print(#function, "hits =", cacheHits, "misses =", cacheMisses, 100.0 * (Double(cacheHits) / Double(cacheMisses)))
//        dump(cac)
    }
}
