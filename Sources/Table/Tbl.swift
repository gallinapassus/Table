import Foundation

public struct Tbl : Equatable, Codable {
    public static func == (lhs: Tbl, rhs: Tbl) -> Bool {
        lhs.data == rhs.data &&
        lhs.columns == rhs.columns &&
        lhs.title == rhs.title &&
        lhs.frameStyle == rhs.frameStyle &&
        lhs.frameRenderingOptions == rhs.frameRenderingOptions
    }
    
    public let data:[[Txt]]
    public let columns:[Col]
    public let title:Txt?
    public var frameStyle:FrameElements
    public var frameRenderingOptions:FrameRenderingOptions
    private var actualColumns:[Col] = []
    private let hasData:Bool
    private let hasVisibleColumns:Bool
    private let hasHeaderLabels:Bool
    private let hasTitle:Bool
    public init(_ title:Txt? = nil,
                columns: [Col] = [],
                cells:[[Txt]],
                frameStyle:FrameElements = .default,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        precondition(columns.count <= UInt16.max, "Maximum column count is limited to \(UInt16.max).")
        if columns.isEmpty {
            // Let's treat empty column set as "automatic columns"
            let maxColCount = cells.reduce(0, { Swift.max($0, $1.count) })
            if maxColCount == 0 {
                // Actually, there is no data either, no columns then
                self.columns = []
            }
            else {
                self.columns = Array(repeating: Col(width: .auto, columnDefaultAlignment: .default), count: maxColCount)
            }
        }
        else {
            self.columns = columns
        }
        self.data = cells
        self.hasData = !data.isEmpty
        self.title = title
        self.frameStyle = frameStyle
        self.frameRenderingOptions = frameRenderingOptions
        
        // Calculate column widths for autowidth columns
        self.actualColumns = Tbl.calculateAutowidths(for: self.columns, from: cells)
        self.hasVisibleColumns = !actualColumns.allSatisfy({ $0.width == .hidden }) && self.actualColumns.reduce(0, { $0 + $1.width.value}) >= 0
        self.hasHeaderLabels = !actualColumns.allSatisfy({ $0.header == nil })
        self.hasTitle = title != nil
    }
    private static func calculateAutowidths(for columns:[Col], from data: [[Txt]]) -> [Col] {
        // Figure out actual column widths
        //print("got", columns.map({ $0.width }))
        var tmp = columns
        let recalc:[Int] = columns.enumerated().compactMap({ (i,c) in
            switch c.width {
            case .value: return nil
            default: return i
            }
        })
        //        print("recalc", recalc)
        for i in recalc {
            var lo = Int.max
            var hi = 0
            for (_/*j*/,row) in data.enumerated() {
                guard row.count > i else {
                    continue
                }
                lo = Swift.min(lo, row[i].count)
                hi = Swift.max(hi, row[i].count)
            }
            //print("[\(i)] min ... max = \(lo) ... \(hi)")
            switch tmp[i].width {
            case .min(let min): tmp[i].width = .value(Swift.max(min, lo))
            case .max(let max): tmp[i].width = .value(Swift.min(max, hi))
            case .in(let closedRange):
                tmp[i].width = .value(Swift.max(Swift.min(closedRange.upperBound, hi), closedRange.lowerBound))
            case .range( let range):
                tmp[i].width = .value(Swift.max(Swift.min(range.upperBound - 1, hi), range.lowerBound))
            case .auto:
                tmp[i].width = .value(Swift.max(0, hi))
            default: break
            }
        }
        //print("returning", tmp.map({ $0.width }))
        return tmp
    }
    private class FrameElement : ExpressibleByStringLiteral, Collection, CustomStringConvertible {
        typealias StringLiteralType = String
        public typealias Index = String.Index
        var string:String = ""
        required init(stringLiteral value:StringLiteralType) {
            self.string = value
        }
        public func append(_ other:StringLiteralType) {
            string.append(other)
        }
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
        var description: String { string }
    }
    private func calculateTitleColumnWidth() -> Int {
        let visibleColumnCount = actualColumns.filter({ $0.width.value > Width.hidden.value }).count - 1
        let calculatedWidth = actualColumns.filter({ $0.width.value > Width.hidden.value })
            .reduce(Swift.max(0, visibleColumnCount) * frameStyle.insideVerticalSeparator.element(for: frameRenderingOptions).count,
                    { $0 + $1.width.value })
        return calculatedWidth
    }
    public func render(into: inout String, leftPad:String = "", rightPad:String = "") {
        let lPad = leftPad
            .filter({ $0.isNewline == false })
        let rPad = rightPad
            .filter({ $0.isNewline == false })
        
        
        // Assign elements before entering "busy" loop,
        // so that they are not evaluated each iteration
        let leftVerticalSeparator = frameStyle.leftVerticalSeparator.element(for: frameRenderingOptions)
        let rightVerticalSeparator = frameStyle.rightVerticalSeparator.element(for: frameRenderingOptions)
        let l = "\(lPad)\(leftVerticalSeparator)"
        let r = "\(rightVerticalSeparator)\(rPad)\n"
        let insideVerticalSeparator = frameStyle.insideVerticalSeparator.element(for: frameRenderingOptions)
        let titleColumnWidth = calculateTitleColumnWidth()
        
        
        // Top frame
        if frameRenderingOptions.contains(.topFrame) {
            into.append(lPad)
            into.append(frameStyle.topLeftCorner.element(for: frameRenderingOptions))
            if hasTitle {
                into.append(
                    String(repeating: frameStyle.topHorizontalSeparator.element(for: frameRenderingOptions),
                           count: titleColumnWidth)
                )
            }
            else if (hasHeaderLabels && hasVisibleColumns) || (hasVisibleColumns && hasData) {
                into.append(
                    actualColumns.map({
                        String(repeating: frameStyle.topHorizontalSeparator.element(for: frameRenderingOptions),
                               count: $0.width.value)
                    }).joined(separator: frameStyle.topHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                )
            }
            into.append(frameStyle.topRightCorner.element(for: frameRenderingOptions))
            into.append("\(rPad)\n")
        }
        
        
        // Title
        if let title = title {
            let alignedTitle = title.fragment(for: Col(width: .value(titleColumnWidth), columnDefaultAlignment: title.align ?? .middleCenter, wrapping: title.wrapping ?? .word, contentHint: .unique))
            //.fragment(fallback: .middleCenter, width: titleColumnWidth, wrapping: .word)
            //.verticallyAligned
            
            for fragment in alignedTitle.lines {
                into.append(
                    lPad +
                    frameStyle.leftVerticalSeparator.element(for: frameRenderingOptions) +
                    fragment +
                    frameStyle.rightVerticalSeparator.element(for: frameRenderingOptions) +
                    "\(rPad)\n")
            }
            
            
            // Divider between title and column headers -or-
            // divider between title and data
            
            if frameRenderingOptions.contains(.insideHorizontalFrame),
               (hasVisibleColumns && hasHeaderLabels) || hasData || hasTitle {
                into.append(lPad)
                into.append(frameStyle.insideLeftVerticalSeparator.element(for: frameRenderingOptions))
                if hasVisibleColumns && (hasHeaderLabels || hasData) {
                    into.append(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            return String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                                          count: Swift.max(0, $0.width.value))
                        }).joined(separator: frameStyle.topHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                    )
                }
                else {
                    into.append(
                        String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                               count: titleColumnWidth)
                    )
                }
                into.append(frameStyle.insideRightVerticalSeparator.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
        }
        
        
        // Column headers
        if hasHeaderLabels, hasVisibleColumns {
            
            let alignedColumnHeaders = actualColumns
                .filter({ $0.width.value > Width.hidden.value })
                .compactMap({ column in
                    return (column.header ?? Txt("")).fragment(for: column)
                })
                .dropFirst(0) // <= Convert Array to ArraySlice
                .alignVertically
            for f in alignedColumnHeaders {
                into.append(lPad)
                into.append(frameStyle.leftVerticalSeparator.element(for: frameRenderingOptions))
                into.append(f.joined(separator: frameStyle.insideVerticalSeparator.element(for: frameRenderingOptions)))
                into.append(frameStyle.rightVerticalSeparator.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
            
            
            
            // Divider, before data
            if frameRenderingOptions.contains(.insideHorizontalFrame) {
                into.append(lPad)
                into.append(frameStyle.insideLeftVerticalSeparator.element(for: frameRenderingOptions))
                if hasHeaderLabels && hasVisibleColumns {
                    into.append(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                                   count: $0.width.value)
                        }).joined(separator: frameStyle.insideHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                    )
                }
                else if title != nil {
                    if hasVisibleColumns {
                        into.append(
                            actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                                String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                                       count: $0.width.value)
                            }).joined(separator: frameStyle.topHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                        )
                    }
                    else {
                        into.append(
                            String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                                   count: titleColumnWidth)
                        )
                    }
                }
                into.append(frameStyle.insideRightVerticalSeparator.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
        }
        
        
        // Data rows
        var cache:[UInt32:[Int:HorizontallyAligned]] = [:]
        var cacheHits:Int = 0
        var cacheMisses:Int = 0
        
        let lastValidIndex = data.index(before: data.endIndex)
        let actualVisibleColumns = actualColumns.filter({ $0.width.value > Width.hidden.value })
        let actualVisibleColumnCount = actualVisibleColumns.count
        let visibleColumnIndexes = actualColumns
            .enumerated()
            .filter({ $0.element.width.value > Width.hidden.value || $0.element.width == .auto })
            .map({ $0.offset })
            .prefix(Swift.min(actualVisibleColumnCount, Int(UInt16.max)))
        // Main loop to render row/column data
        /*
         var cost1:UInt64 = 0
         var cost2:UInt64 = 0
         var cost3:UInt64 = 0
         */
        for (i,row) in data.enumerated() {
            //let a0 = DispatchTime.now().uptimeNanoseconds
            var columnized:ArraySlice<HorizontallyAligned> = []
            let maxHeight:Int = visibleColumnIndexes
                .filter { $0 < row.count }
                .map {
                    if actualColumns[$0].contentHint == .repetitive {
                        
                        // Combine width & alignment
                        let u32:UInt32 = (UInt32(actualColumns[$0].width.value) << 16) +
                        UInt32(row[$0].align?.rawValue ?? actualColumns[$0].columnAlignment.rawValue)
                        
                        if let fromCache = cache[u32]?[row[$0].string.hashValue] {
                            columnized.append(fromCache)
                            cacheHits += 1
                            return fromCache.lines.count
                        }
                        else {
                            let fragmented = row[$0].fragment(for: actualColumns[$0])
                            // Write to cache
                            cache[u32, default:[:]][row[$0].string.hashValue] = fragmented
                            columnized.append(fragmented)
                            cacheMisses += 1
                            return fragmented.lines.count
                        }
                    }
                    else {
                        let fragmented = row[$0].fragment(for: actualColumns[$0])
                        columnized.append(fragmented)
                        return fragmented.lines.count
                    }
                }
                .reduce(0, { Swift.max($0, $1) })
            let missingColumnCount = Swift.max(0, actualVisibleColumnCount - columnized.count)
            let currentCount = columnized.count
            /*
             //let a1 = DispatchTime.now().uptimeNanoseconds
             //            print(row.map { $0.string },
             //                  "missingColumnCount", missingColumnCount,
             //                  actualColumns.map { $0.width.rawValue },
             //                  columnized.map { $0.lines }, terminator: " -> ")
             */
            for k in 0..<missingColumnCount {
                let len = actualVisibleColumns[currentCount + k].width.value
                let emptyLineFragment = String(repeating: " ", count: len)
                columnized.append(
                    HorizontallyAligned(lines: Array(repeating: emptyLineFragment, count: maxHeight),
                                        alignment: .default,
                                        width: actualColumns[currentCount + k].width)
                )
            }
            
            //let a2 = DispatchTime.now().uptimeNanoseconds
            for columnData in columnized.prefix(actualColumns.count).alignVertically {
                into.append(l + columnData.joined(separator: insideVerticalSeparator) + r)
            }
            if data.count > 0, hasVisibleColumns,i != lastValidIndex, frameRenderingOptions.contains(.insideHorizontalFrame) {
                into.append(lPad)
                into.append(frameStyle.insideLeftVerticalSeparator.element(for: frameRenderingOptions))
                into.append(
                    actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                        String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                               count: $0.width.value)
                    }).joined(separator: frameStyle.insideHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                )
                into.append(frameStyle.insideRightVerticalSeparator.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
            /*
             let a3 = DispatchTime.now().uptimeNanoseconds
             cost1 += (a1 - a0)
             cost2 += (a2 - a1)
             cost3 += (a3 - a2)
             */
        }
        
        
        // Bottom frame
        if frameRenderingOptions.contains(.bottomFrame) {
            into.append(lPad)
            into.append(frameStyle.bottomLeftCorner.element(for: frameRenderingOptions))
            if hasVisibleColumns {
                if data.count > 0 {
                    into.append(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            String(repeating: frameStyle.bottomHorizontalSeparator.element(for: frameRenderingOptions),
                                   count: $0.width.value)
                        }).joined(separator: frameStyle.bottomHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                    )
                }
                else {
                    into.append(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            String(repeating: frameStyle.bottomHorizontalSeparator.element(for: frameRenderingOptions),
                                   count: $0.width.value)
                        }).joined(separator: frameStyle.bottomHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                    )
                }
            }
            else {
                into.append(
                    String(repeating: frameStyle.bottomHorizontalSeparator.element(for: frameRenderingOptions),
                           count: titleColumnWidth)
                )
            }
            into.append(frameStyle.bottomRightCorner.element(for: frameRenderingOptions))
            into.append("\(rPad)\n")
        }
        /*
         print("missing column count cost", Double(cost1) / 1_000_000, "ms")
         print("           maxHeight cost", Double(cost2) / 1_000_000, "ms")
         print("              output cost", Double(cost3) / 1_000_000, "ms")
         */
    }
    public func render(leftPad:String = "", rightPad:String = "") -> String {
        var result = ""
        render(into: &result, leftPad: leftPad, rightPad: rightPad)
        return result
    }
    public func csv(delimiter:String = ";", withColumnHeaders:Bool = true, includingHiddenColumns:Bool = false) -> String {
        var result = ""
        if withColumnHeaders {
            let headers = columns
                .filter({
                    if includingHiddenColumns {
                        return true
                    }
                    else {
                        return $0.width != .hidden
                    }
                })
                .map({ $0.header?.string ?? ""})
                .joined(separator: delimiter)
            print(headers + (headers.isEmpty ? "" : delimiter), to: &result)
        }
        
        for row in data {
            var rowElements:[String] = []
            for (i,col) in row.enumerated() {
                guard columns.indices.contains(i) else {
                    break
                }
                guard (columns[i].width == .hidden && includingHiddenColumns == false) == false else {
                    continue
                }
                rowElements.append(col.string)
            }
            print(rowElements.joined(separator: delimiter) + String(repeating: delimiter, count: Swift.max(0, columns.count - row.count)) + delimiter, to: &result)
        }
        return result
    }
}
extension Tbl {
    // Convenience
    public init(_ title:Txt? = nil,
                columns:[Col] = [],
                strings:[[String]],
                frameStyle:FrameElements = .default,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        self.init(title, columns: columns,
                  cells: strings.map({ $0.map({ Txt($0) })}),
                  frameStyle: frameStyle,
                  frameRenderingOptions: frameRenderingOptions)
    }
    // Convenience
    public init(_ title:String,
                columns:[Col] = [],
                strings:[[String]],
                frameStyle:FrameElements = .default,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        self.init(Txt(title), columns: columns,
                  cells: strings.map({ $0.map({ Txt($0) })}),
                  frameStyle: frameStyle,
                  frameRenderingOptions: frameRenderingOptions)
    }
    // Convenience
    public init(_ title:String,
                columns:[Col] = [],
                cells:[[Txt]],
                frameStyle:FrameElements = .default,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        self.init(Txt(title), columns: columns,
                  cells: cells,
                  frameStyle: frameStyle,
                  frameRenderingOptions: frameRenderingOptions)
    }
    // DSL
    public init(_ title:Txt?,
                @TblBuilder _ makeTable: () -> (FrameElements?, FrameRenderingOptions?, [Col], [[Txt]])) {
        let (frameStyle, options, columns, data) = makeTable()
        self.init(title, columns: columns,
                  cells: data,
                  frameStyle: frameStyle ?? .default,
                  frameRenderingOptions: options ?? .all)
    }
}
