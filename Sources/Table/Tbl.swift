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
    public var frameStyle:FrameStyle
    public var frameRenderingOptions:FrameRenderingOptions
    private var actualColumns:[Col] = []
    private let hasData:Bool
    private let hasVisibleColumns:Bool
    private let hasHeaderLabels:Bool
    private let hasTitle:Bool
    /// Initializes table
    ///
    /// - Parameters:
    ///     - title: Table title
    ///     - columns: Table column definitions
    ///     - cells: Table cell data
    ///     - frameStyle: Frame style for rendering
    ///     - frameRenderingOptions: Frame rendering options (default: all)
    ///     - cellsMayHaveNewlines: Boolean value indicating if table cell data may contain newlines
    ///     (default: true).
    ///
    /// - Note: Main purpose of `cellsMayHaveNewlines` setting is performance optimisation.
    ///     For large tables, there should be a performance benefit in setting this `false` for
    ///     tables which have one or more autowidth / range columns defined and which
    ///     cell data is known to be clean from newlines.

    public init(_ title:Txt? = nil,
                columns: [Col] = [],
                cells:[[Txt]],
                frameStyle:FrameStyle = .default,
                frameRenderingOptions:FrameRenderingOptions = .all,
                cellsMayHaveNewlines:Bool = true) {
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
        self.actualColumns = Tbl
            .calculateAutowidths(for: self.columns,
                                 from: cells,
                                 newlines: cellsMayHaveNewlines)
        self.hasVisibleColumns = !actualColumns.allSatisfy({ $0.width == .hidden }) && self.actualColumns.reduce(0, { $0 + $1.width.value}) >= 0
        self.hasHeaderLabels = !actualColumns.allSatisfy({ $0.header == nil })
        self.hasTitle = title != nil
    }
    private static func calculateAutowidths(for columns:[Col],
                                            from data: [[Txt]],
                                            newlines:Bool) -> [Col] {
        // Figure out actual column widths
        //print("got", columns.map({ $0.width }))
        var tmp = columns
        let recalc:[Int] = columns.enumerated().compactMap({ (i,c) in
            switch c.width {
            case .value: return nil
            default: return i
            }
        })
        for i in recalc {
            var lo = columns.reduce(0, {
                switch $1.width {
                case .auto: return $0
                case .min(let m): return $0 + m
                case .max(let m): return $0 + m
                case .range(let r): return $0 + r.lowerBound
                case .in(let r): return $0 + r.lowerBound
                case .value(let v): return $0 + v
                case .hidden: return $0
                }
            })
            var hi = 0
            for row in data {
                guard row.count > i else {
                    continue
                }
                if newlines {
                    row[i]
                        .split(separator: "\n", omittingEmptySubsequences: false)
                        .forEach({
                            lo = Swift.min(lo, $0.count)
                            hi = Swift.max(hi, $0.count)
                        })
                }
                else {
                    lo = Swift.min(lo, row[i].count)
                    hi = Swift.max(hi, row[i].count)
                }
            }
            //print("[\(i)] min ... max = \(lo) ... \(hi)")
            switch tmp[i].width {
            case .min(let min):
                tmp[i].width = .value(Swift.max(min, lo))
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
    private func calculateTitleColumnWidth() -> Int {
        let visibleColumnCount = actualColumns.filter({ $0.width.value > Width.hidden.value }).count - 1
        let calculatedWidth = actualColumns.filter({ $0.width.value > Width.hidden.value })
            .reduce(Swift.max(0, visibleColumnCount) * frameStyle.insideVerticalSeparator(for: frameRenderingOptions).count,
                    { $0 + $1.width.value })
        return calculatedWidth
    }
    /// Render table
    /// - Parameters:
    ///   - rowRanges: Range of table rows to render, default `nil` means all rows
    ///   - leftPad: Pad left side of the table with `String`
    ///   - rightPad: Pad right side of the table with `String`
    ///   - output: An output stream to receive the rendering result.
    public func render(rowRanges:[Range<Int>]? = nil,
                       leftPad:String = "",
                       rightPad:String = "",
                       to output: inout TextOutputStream) {

        var rnges:[Range<Int>] = []
        for range in rowRanges ?? [(0..<data.count)]{
            guard range.lowerBound >= 0,
                  range.upperBound <= data.count else {
                fatalError("range \(range) out of bounds")
            }
            rnges.append(range)
        }

        let lPad = leftPad
            .filter({ $0.isNewline == false })
        let rPad = rightPad
            .filter({ $0.isNewline == false })


        // Assign elements before entering "busy" loop,
        // so that they are not evaluated each iteration
        let leftVerticalSeparator = frameStyle.leftVerticalSeparator(for: frameRenderingOptions)
        let rightVerticalSeparator = frameStyle.rightVerticalSeparator(for: frameRenderingOptions)
        let l = "\(lPad)\(leftVerticalSeparator)"
        let r = "\(rightVerticalSeparator)\(rPad)\n"
        let insideVerticalSeparator = frameStyle.insideVerticalSeparator(for: frameRenderingOptions)
        let titleColumnWidth = calculateTitleColumnWidth()


        // Top frame
        if frameRenderingOptions.contains(.topFrame) {
            output.write(lPad)
            output.write(frameStyle.topLeftCorner(for: frameRenderingOptions))
            if hasTitle {
                output.write(
                    String(repeating: frameStyle.topHorizontalSeparator(for: frameRenderingOptions),
                           count: titleColumnWidth)
                )
            }
            else if (hasHeaderLabels && hasVisibleColumns) || (hasVisibleColumns && hasData) {
                output.write(
                    actualColumns.map({
                        String(repeating: frameStyle.topHorizontalSeparator(for: frameRenderingOptions),
                               count: $0.width.value)
                    }).joined(separator: frameStyle.topHorizontalVerticalSeparator(for: frameRenderingOptions))
                )
            }
            output.write(frameStyle.topRightCorner(for: frameRenderingOptions))
            output.write("\(rPad)\n")
        }


        // Title
        if let title = title {
            let splitted = title.string.split(separator: "\n", omittingEmptySubsequences: false)
                .map({ Txt(String($0), align: title.align, wrapping: title.wrapping) })
            var combined:[HorizontallyAligned] = []
            for split in splitted {
                let foo = split.fragment(for: Col(width: .value(titleColumnWidth), columnDefaultAlignment: title.align ?? .middleCenter, wrapping: title.wrapping ?? .word, contentHint: .unique))
                combined.append(foo)
            }
            let alignedTitle = HorizontallyAligned(lines: combined.flatMap({ $0.lines }), alignment: title.align ?? .middleCenter,
                                                   wrapping: title.wrapping ?? .word)

            for fragment in alignedTitle.lines {
                output.write(
                    lPad +
                    frameStyle.leftVerticalSeparator(for: frameRenderingOptions) +
                    fragment +
                    frameStyle.rightVerticalSeparator(for: frameRenderingOptions) +
                    "\(rPad)\n")
            }


            // Divider between title and column headers -or-
            // divider between title and data
            
            if frameRenderingOptions.contains(.insideHorizontalFrame),
               (hasVisibleColumns && hasHeaderLabels) || hasData || hasTitle {
                output.write(lPad)
                output.write(frameStyle.insideLeftVerticalSeparator(for: frameRenderingOptions))
                if hasVisibleColumns && (hasHeaderLabels || hasData) {
                    output.write(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            return String(repeating: frameStyle.insideHorizontalSeparator(for: frameRenderingOptions),
                                          count: Swift.max(0, $0.width.value))
                        }).joined(separator: frameStyle.topHorizontalVerticalSeparator(for: frameRenderingOptions))
                    )
                }
                else {
                    output.write(
                        String(repeating: frameStyle.insideHorizontalSeparator(for: frameRenderingOptions),
                               count: titleColumnWidth)
                    )
                }
                output.write(frameStyle.insideRightVerticalSeparator(for: frameRenderingOptions))
                output.write("\(rPad)\n")
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
                output.write(lPad)
                output.write(frameStyle.leftVerticalSeparator(for: frameRenderingOptions))
                output.write(f.joined(separator: frameStyle.insideVerticalSeparator(for: frameRenderingOptions)))
                output.write(frameStyle.rightVerticalSeparator(for: frameRenderingOptions))
                output.write("\(rPad)\n")
            }
            
            
            
            // Divider, before data
            if frameRenderingOptions.contains(.insideHorizontalFrame) {
                output.write(lPad)
                output.write(frameStyle.insideLeftVerticalSeparator(for: frameRenderingOptions))
                if hasHeaderLabels && hasVisibleColumns {
                    output.write(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            String(repeating: frameStyle.insideHorizontalSeparator(for: frameRenderingOptions),
                                   count: $0.width.value)
                        }).joined(separator: frameStyle.insideHorizontalVerticalSeparator(for: frameRenderingOptions))
                    )
                }
                else if title != nil {
                    if hasVisibleColumns {
                        output.write(
                            actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                                String(repeating: frameStyle.insideHorizontalSeparator(for: frameRenderingOptions),
                                       count: $0.width.value)
                            }).joined(separator: frameStyle.topHorizontalVerticalSeparator(for: frameRenderingOptions))
                        )
                    }
                    else {
                        output.write(
                            String(repeating: frameStyle.insideHorizontalSeparator(for: frameRenderingOptions),
                                   count: titleColumnWidth)
                        )
                    }
                }
                output.write(frameStyle.insideRightVerticalSeparator(for: frameRenderingOptions))
                output.write("\(rPad)\n")
            }
        }


        // Data rows
        for (ri, rnge) in zip(0..., rnges) {
            var cache:[UInt32:[Int:HorizontallyAligned]] = [:]
            var cacheHits:Int = 0
            var cacheMisses:Int = 0
            
            let lastValidIndex = rnge.upperBound - 1
            let actualVisibleColumns = actualColumns.filter({ $0.width.value > Width.hidden.value })
            let actualVisibleColumnCount = actualVisibleColumns.count
            let visibleColumnIndexes = actualColumns
                .enumerated()
                .filter({ $0.element.width.value > Width.hidden.value || $0.element.width == .auto })
                .map({ $0.offset })
                .prefix(Swift.min(actualVisibleColumnCount, Int(UInt16.max)))
            // Main loop to render row/column data
            var i = rnge.lowerBound
            for row in data[rnge] {
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
                                let w = actualColumns[$0].width.value
                                let a = row[$0].align ?? actualColumns[$0].columnAlignment
                                let wr = row[$0].wrapping ?? actualColumns[$0].wrapping
                                let splits = row[$0].string
                                    .split(separator: "\n", omittingEmptySubsequences: false)
                                    .map({ ele in
                                        ele.isEmpty ? Txt(String(repeating: " ", count: w), align: a, wrapping: wr)
                                        :
                                        Txt(String(ele), align: a, wrapping: wr)
                                    })
                                var combined:[String] = []
                                for split in splits {
                                    combined.append(contentsOf: split.fragment(for: actualColumns[$0]).lines)
                                }
                                let fragmented = HorizontallyAligned(lines: combined,
                                                                     alignment: a,
                                                                     width: actualColumns[$0].width,
                                                                     wrapping: actualColumns[$0].wrapping)
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
                for k in 0..<missingColumnCount {
                    let len = actualVisibleColumns[currentCount + k].width.value
                    let emptyLineFragment = String(repeating: " ", count: len)
                    columnized.append(
                        HorizontallyAligned(lines: Array(repeating: emptyLineFragment, count: maxHeight),
                                            alignment: .default,
                                            width: actualColumns[currentCount + k].width)
                    )
                }
                
                for columnData in columnized.prefix(actualColumns.count).alignVertically {
                    output.write(l + columnData.joined(separator: insideVerticalSeparator) + r)
                }
                // Dividers between rows
                if data.count > 0,
                   hasVisibleColumns,
                   i < lastValidIndex,
                   frameRenderingOptions.contains(.insideHorizontalFrame) {
                    output.write(lPad)
                    output.write(frameStyle.insideLeftVerticalSeparator(for: frameRenderingOptions))
                    output.write(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            String(repeating: frameStyle.insideHorizontalSeparator(for: frameRenderingOptions),
                                   count: $0.width.value)
                        }).joined(separator: frameStyle.insideHorizontalVerticalSeparator(for: frameRenderingOptions))
                    )
                    output.write(frameStyle.insideRightVerticalSeparator(for: frameRenderingOptions))
                    output.write("\(rPad)\n")
                }
                i += 1
            }
            // Dividers between row ranges
            if data.count > 0,
               hasVisibleColumns,
               ri < rnges.index(before: rnges.endIndex),
               frameRenderingOptions.contains(.insideHorizontalFrame) {
                output.write(lPad)
                output.write(frameStyle.insideLeftVerticalSeparator(for: frameRenderingOptions))
                output.write(
                    actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                        String(repeating: frameStyle.insideHorizontalRowRangeSeparator(for: frameRenderingOptions),
                               count: $0.width.value)
                    }).joined(separator: frameStyle.insideHorizontalVerticalSeparator(for: frameRenderingOptions))
                )
                output.write(frameStyle.insideRightVerticalSeparator(for: frameRenderingOptions))
                output.write("\(rPad)\n")
            }
        }

        // Bottom frame
        if frameRenderingOptions.contains(.bottomFrame) {
            output.write(lPad)
            output.write(frameStyle.bottomLeftCorner(for: frameRenderingOptions))
            if hasVisibleColumns {
                if data.count > 0 {
                    output.write(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            String(repeating: frameStyle.bottomHorizontalSeparator(for: frameRenderingOptions),
                                   count: $0.width.value)
                        }).joined(separator: frameStyle.bottomHorizontalVerticalSeparator(for: frameRenderingOptions))
                    )
                }
                else {
                    output.write(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            String(repeating: frameStyle.bottomHorizontalSeparator(for: frameRenderingOptions),
                                   count: $0.width.value)
                        }).joined(separator: frameStyle.bottomHorizontalVerticalSeparator(for: frameRenderingOptions))
                    )
                }
            }
            else {
                output.write(
                    String(repeating: frameStyle.bottomHorizontalSeparator(for: frameRenderingOptions),
                           count: titleColumnWidth)
                )
            }
            output.write(frameStyle.bottomRightCorner(for: frameRenderingOptions))
            output.write("\(rPad)\n")
        }
    }
    /// Render table
    /// - Parameters:
    ///     - rowRanges: Collection of row ranges to render, default value of `nil` means all rows
    ///     - leftPad: Pad left side of the table with `String`
    ///     - rightPad: Pad right side of the table with `String`
    /// - Returns: `String` containing rendered table
    public func render(rowRanges:[Range<Int>]? = nil,
                       leftPad:String = "", rightPad:String = "") -> String {
        var result: any TextOutputStream = ""
        render(rowRanges: rowRanges, leftPad: leftPad, rightPad: rightPad, to: &result)
        return result as! String
    }
    /// Render table
    /// - Parameters:
    ///     - range: Range of table rows to render, default `nil` means all rows
    ///     - leftPad: Pad left side of the table with `String`
    ///     - rightPad: Pad right side of the table with `String`
    /// - Returns: `String` containing rendered table
    public func render(rows range:Range<Int>, leftPad:String = "", rightPad:String = "") -> String {
        var result: any TextOutputStream = ""
        render(rowRanges: [range],
               leftPad: leftPad, rightPad: rightPad,
               to: &result)
        return result as! String
    }
    /// Render table
    /// - Parameters:
    ///   - range: Range of table rows to render, default `nil` means all rows
    ///   - leftPad: Pad left side of the table with `String`
    ///   - rightPad: Pad right side of the table with `String`
    ///   - output: An output stream to receive the rendering result.
    /// - Returns: `String` containing rendered table
    public func render(rows range:Range<Int>, leftPad:String = "", rightPad:String = "", to output:inout TextOutputStream) {
        render(rowRanges: [range],
               leftPad: leftPad, rightPad: rightPad,
               to: &output)
    }
    /// Convert table data to CSV format
    /// - Returns: `String` containing table data formatted as CSV
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
                frameStyle:FrameStyle = .default,
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
                frameStyle:FrameStyle = .default,
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
                frameStyle:FrameStyle = .default,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        self.init(Txt(title), columns: columns,
                  cells: cells,
                  frameStyle: frameStyle,
                  frameRenderingOptions: frameRenderingOptions)
    }
    // DSL
    public init(_ title:Txt?,
                @TblBuilder _ makeTable: () -> (FrameStyle?, FrameRenderingOptions?, [Col], [[Txt]])) {
        let (frameStyle, options, columns, data) = makeTable()
        self.init(title, columns: columns,
                  cells: data,
                  frameStyle: frameStyle ?? .default,
                  frameRenderingOptions: options ?? .all)
    }
}
