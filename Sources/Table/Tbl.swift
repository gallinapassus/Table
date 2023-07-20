import Foundation

public class Tbl : Decodable {

    /// Table cell data
    public let data:[[Txt]]
    /// Table column definitions.
    public let columns:[Col]
    /// Table title
    public let title:Txt?
    
    /// Customizable line number generator
    ///
    /// If this function is defined, `Tbl` will automatically insert an additional
    /// column (to position 0). Column will not have a header and it has a
    /// `defaultColumnAlignment` set to bottom right (which can be
    /// overridden by the returned `Txt` if needed).
    ///
    /// This function will be called once for each row  selected for rendering.

    public var lineNumberGenerator:((Int) -> Txt)? = nil

    /// Variable `cellsMayHaveNewlines` affects table rendering speed and
    /// correctness.
    ///
    /// Default value is `true`
    ///
    /// **Rendering speed & correctness**
    ///
    /// Setting `cellsMayHaveNewlines` to `false` for cell data which doesn't contain
    /// newlines will result to fastest rendering speed and table columns will render with
    /// correct widths.
    ///
    /// Setting `cellsMayHaveNewlines` to `true` for cell data which doesn't contain
    /// newlines will result to slightly slower rendering speed. Table columns will render with
    /// correct widths.
    ///
    /// Setting `cellsMayHaveNewlines` to `false` for cell data which does contain
    /// newlines will result to fast rendering speed but table columns may render with
    /// incorrect widths.
    ///
    /// Setting `cellsMayHaveNewlines` to `true` for cell data which does contain
    /// newlines will result to slowest overall rendering speed. Table columns will render with
    /// correct widths.
    ///
    public var cellsMayHaveNewlines:Bool = true

    /// Initializes table
    ///
    /// - Parameters:
    ///     - title: Table title
    ///     - columns: Table column definitions
    ///     - cells: Table cell data
    ///

    public init(_ title:Txt? = nil,
                columns: [Col] = [],
                cells:[[Txt]]) {
        precondition(columns.count <= UInt16.max, "Maximum column count is limited to \(UInt16.max).")
        self.data = cells
        self.title = title
        if columns.isEmpty {
            // Let's treat empty column set as "automatic columns"
            let maxColCount = cells.reduce(0, { Swift.max($0, $1.count) })
            if maxColCount == 0 {
                // Actually, there is no data either, no columns then
                self.columns = []
            }
            else {
                let c = Col(width: .auto,
                            defaultAlignment: .topLeft,
                            contentHint: .repetitive)
                self.columns = Array(repeating: c, count: maxColCount)
            }
        }
        else {
            self.columns = columns
        }
    }
    /// Calculate actual column widths for dynamic columns
    ///
    /// All width types except `.value()` are dynamic.
    ///
    /// - Note: Fastest table rendering is achieved when all columns have
    /// fixed values. If columns contain even a single dynamic width column,
    /// a full scan of data cells is needed to calculate the actual column widths.

    private func calculateAutowidths(for columns:[Col],
                                     from data: [[Txt]],
                                     newlines:Bool) -> [Col] {
        // Find out column indexes which must be calculated
        let recalc:[Int] = columns.enumerated().compactMap({ (i,c) in
            switch c.width {
            case .value: return nil // fixed, no need to calculate
            default: return i       // dynamic, columns[i] must be calculated
            }
        })

        guard recalc.isEmpty == false else { return columns }

        var tmp = columns
        for i in recalc {
            // Minimum width for this cell
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
            // Calculate the optimal column widths for dynamic
            // width columns from cell data. A single pass through
            // cell data is needed.
            var hi = 0
            for row in data {

                // Optimization: continue, if current row has
                // fewer cells than what the current recalc index is.
                guard row.count > i else { continue }

                // Are we expecting cell data to contain newlines
                if newlines {
                    // yes, cell data may contain newlines
                    // now, split the column cell at newlines
                    // and find out the lower and upper range
                    // of these row cell fragments
                    row[i]
                        .split(separator: "\n", omittingEmptySubsequences: false)
                        .forEach({
                            lo = Swift.min(lo, $0.count)
                            hi = Swift.max(hi, $0.count)
                        })
                }
                else {
                    // no, cell data does not contain newlines
                    // quickly find out the lower and upper range
                    // for this row cell
                    lo = Swift.min(lo, row[i].count)
                    hi = Swift.max(hi, row[i].count)
                }
            }
            //print("[\(i)] min ... max = \(lo) ... \(hi)")

            // Set the actual column width, based on the
            // given column width definitions and calculations
            // from cell data
            switch tmp[i].width {
            case .min(let min):
                tmp[i].width = .value(Swift.max(min, lo))
            case .max(let max):
                tmp[i].width = .value(Swift.min(max, hi))
            case .in(let closedRange):
                tmp[i].width = .value(Swift.max(Swift.min(closedRange.upperBound, hi), closedRange.lowerBound))
            case .range( let range):
                tmp[i].width = .value(Swift.max(Swift.min(range.upperBound - 1, hi), range.lowerBound))
            case .auto:
                tmp[i].width = .value(Swift.max(0, hi))
            case .value: break
            case .hidden: break
            }
        }

        // Insert additional line number column (at index 0)
        // if lineNumberGenerator function is defined.
        //
        // This implementation is a compromise between 'line
        // numbers will always fit vertically on a single
        // line' and 'don't waste time in generating all line
        // numbers in advance just to know their widths'.
        //
        // Required column width is calculated with the
        // assumption that last line number is the one requiring
        // the longest column width. This assumption can of course
        // be wrong in some cases and will result to a column
        // width which is too narrow. In those cases, line number
        // doesn't fit on a single line, but will be fragmented
        // over multiple lines (vertically).
        if let lnGen = lineNumberGenerator {
            let lastLineNumber = lnGen(data.count)
            let fragments = lastLineNumber
                .split(separator: "\n",
                       maxSplits: lastLineNumber.string.count,
                       omittingEmptySubsequences: false)
            var requiredWidth:Int = 0
            fragments.forEach({
                requiredWidth = Swift.max(requiredWidth, $0.count)
            })
            let autoLNcolumn = Col(width: .value(requiredWidth),
                                   defaultAlignment: .bottomRight,
                                   defaultWrapping: .cut,
                                   contentHint: .unique)
            tmp.insert(autoLNcolumn, at: 0)
        }

        return tmp
    }

    /// Calculate title column width and actual column widths (for dynamic width columns)

    private func calculateTitleAndColumnWidths(frameStyle:FrameStyle,
                                               framingOptions:FramingOptions) -> ([Col],Int) {

        let actualColumnWidths = calculateAutowidths(
            for: columns,
            from: data,
            newlines: cellsMayHaveNewlines)
        let visibleColumnCount = actualColumnWidths.filter({ $0.width.value > Width.hidden.value }).count - 1
        let calculatedWidth = actualColumnWidths.filter({ $0.width.value > Width.hidden.value })
            .reduce(Swift.max(0, visibleColumnCount) * frameStyle.insideVerticalSeparator(for: framingOptions).count,
                    { $0 + $1.width.value })
        return (actualColumnWidths, calculatedWidth)
    }

    /// Render table
    /// - Parameters:
    ///   - style: Frame style
    ///   - options: Framing options
    ///   - rows: Range of table rows to render, `nil` means all rows
    ///   - leftPad: Pad left side of the table with static `String`
    ///   - rightPad: Pad right side of the table with static `String`
    ///   - output: An output stream to receive the rendering result.
    public func render(style:FrameStyle = .default,
                       options:FramingOptions = .all,
                       rows ranges:[Range<Int>]? = nil,
                       leftPad:String = "",
                       rightPad:String = "",
                       to output: inout TextOutputStream) {

        let hasData = !data.isEmpty
        var rnges:[Range<Int>] = []
        // Validate row ranges
        for range in ranges ?? [(0..<data.count)]{
            guard range.lowerBound >= 0,
                  range.upperBound <= data.count else {
                fatalError("range \(range) out of bounds")
            }
            rnges.append(range)
        }


        // Assign elements before entering "busy" loop,
        // so that they are not evaluated each iteration

        // Cleanup static left/right padding strings from newlines
        let lPad = leftPad
            .filter({ $0.isNewline == false })
        let rPad = rightPad
            .filter({ $0.isNewline == false })


        // Seprators etc.
        let leftVerticalSeparator = style.leftVerticalSeparator(for: options)
        let rightVerticalSeparator = style.rightVerticalSeparator(for: options)
        let l = "\(lPad)\(leftVerticalSeparator)"
        let r = "\(rightVerticalSeparator)\(rPad)\n"
        let insideVerticalSeparator = style.insideVerticalSeparator(for: options)
        let (actualColumns,titleColumnWidth) = calculateTitleAndColumnWidths(
            frameStyle: style, framingOptions: options)
        let hasVisibleColumns = !actualColumns.allSatisfy({ $0.width == .hidden }) && actualColumns.reduce(0, { $0 + $1.width.value}) >= 0
        let hasHeaderLabels = !actualColumns.allSatisfy({ $0.header == nil })
        let hasTitle = title != nil


        // Output the table

        // Top frame
        if options.contains(.topFrame) {
            output.write(lPad)
            output.write(style.topLeftCorner(for: options))
            if hasTitle {
                output.write(
                    String(repeating: style.topHorizontalSeparator(for: options),
                           count: titleColumnWidth)
                )
            }
            else if (hasHeaderLabels && hasVisibleColumns) || (hasVisibleColumns && hasData) {
                output.write(
                    actualColumns.map({
                        String(repeating: style.topHorizontalSeparator(for: options),
                               count: $0.width.value)
                    }).joined(separator: style.topHorizontalVerticalSeparator(for: options))
                )
            }
            output.write(style.topRightCorner(for: options))
            output.write("\(rPad)\n")
        }


        // Title
        if let title = title {
            let splitted = title.string.split(separator: "\n", omittingEmptySubsequences: false)
                .map({
                    Txt(String($0),
                        alignment: title.alignment,
                        wrapping: title.wrapping)
                })
            var combined:[HorizontallyAligned] = []
            for split in splitted {
                let foo = split.fragment(for: Col(width: .value(titleColumnWidth), defaultAlignment: title.alignment ?? .middleCenter, defaultWrapping: title.wrapping ?? .word, contentHint: .unique))
                combined.append(foo)
            }
            let alignedTitle = HorizontallyAligned(lines: combined.flatMap({ $0.lines }), alignment: title.alignment ?? .middleCenter,
                                                   wrapping: title.wrapping ?? .word)

            for fragment in alignedTitle.lines {
                output.write(
                    lPad +
                    style.leftVerticalSeparator(for: options) +
                    fragment +
                    style.rightVerticalSeparator(for: options) +
                    "\(rPad)\n")
            }


            // Divider between title and column headers -or-
            // divider between title and data
            
            if options.contains(.insideHorizontalFrame),
               (hasVisibleColumns && hasHeaderLabels) || hasData || hasTitle {
                output.write(lPad)
                output.write(style.insideLeftVerticalSeparator(for: options))
                if hasVisibleColumns && (hasHeaderLabels || hasData) {
                    output.write(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            return String(repeating: style.insideHorizontalSeparator(for: options),
                                          count: Swift.max(0, $0.width.value))
                        }).joined(separator: style.topHorizontalVerticalSeparator(for: options))
                    )
                }
                else {
                    output.write(
                        String(repeating: style.insideHorizontalSeparator(for: options),
                               count: titleColumnWidth)
                    )
                }
                output.write(style.insideRightVerticalSeparator(for: options))
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
                output.write(style.leftVerticalSeparator(for: options))
                output.write(f.joined(separator: style.insideVerticalSeparator(for: options)))
                output.write(style.rightVerticalSeparator(for: options))
                output.write("\(rPad)\n")
            }
            
            
            
            // Divider, before data
            if options.contains(.insideHorizontalFrame) {
                output.write(lPad)
                output.write(style.insideLeftVerticalSeparator(for: options))
                if hasHeaderLabels && hasVisibleColumns {
                    output.write(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            String(repeating: style.insideHorizontalSeparator(for: options),
                                   count: $0.width.value)
                        }).joined(separator: style.insideHorizontalVerticalSeparator(for: options))
                    )
                }
                else if title != nil {
                    if hasVisibleColumns {
                        output.write(
                            actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                                String(repeating: style.insideHorizontalSeparator(for: options),
                                       count: $0.width.value)
                            }).joined(separator: style.topHorizontalVerticalSeparator(for: options))
                        )
                    }
                    else {
                        output.write(
                            String(repeating: style.insideHorizontalSeparator(for: options),
                                   count: titleColumnWidth)
                        )
                    }
                }
                output.write(style.insideRightVerticalSeparator(for: options))
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
            for (rri, row) in zip((rnge.lowerBound)..., data[rnge]) {
                var columnized:ArraySlice<HorizontallyAligned> = []
                let offset = lineNumberGenerator == nil ? 0 : 1
                let maxHeight:Int = visibleColumnIndexes
                    .filter { $0 < row.count }
                    .map {
                        let ci = $0 + offset
                        if actualColumns[$0].contentHint == .repetitive {
                            // Combine width & alignment
                            let u32:UInt32 = (UInt32(actualColumns[ci].width.value) << 16) +
                            UInt32(row[$0].alignment?.rawValue ?? actualColumns[ci].defaultAlignment.rawValue)
                            
                            if let fromCache = cache[u32]?[row[$0].string.hashValue] {
                                columnized.append(fromCache)
                                cacheHits += 1
                                return fromCache.lines.count
                            }
                            else {
                                let w = actualColumns[$0].width.value
                                let a = row[$0].alignment ?? actualColumns[ci].defaultAlignment
                                let wr = row[$0].wrapping ?? actualColumns[ci].defaultWrapping
                                let splits = row[$0].string
                                    .split(separator: "\n", omittingEmptySubsequences: false)
                                    .map({ ele in
                                        ele.isEmpty ? Txt(String(repeating: " ", count: w), alignment: a, wrapping: wr)
                                        :
                                        Txt(String(ele), alignment: a, wrapping: wr)
                                    })
                                var combined:[String] = []
                                for split in splits {
                                    combined.append(contentsOf: split.fragment(for: actualColumns[ci]).lines)
                                }
                                let fragmented = HorizontallyAligned(lines: combined,
                                                                     alignment: a,
                                                                     width: actualColumns[ci].width,
                                                                     wrapping: actualColumns[$0].defaultWrapping)
                                // Write to cache
                                cache[u32, default:[:]][row[$0].string.hashValue] = fragmented
                                columnized.append(fragmented)
                                cacheMisses += 1
                                return fragmented.lines.count
                            }
                        }
                        else {
                            let fragmented = row[$0].fragment(for: actualColumns[ci])
                            columnized.append(fragmented)
                            return fragmented.lines.count
                        }
                    }
                    .reduce(0, { Swift.max($0, $1) })
                if lineNumberGenerator != nil {
                    let fragments:Txt
                    if let lnGen = lineNumberGenerator {
                        fragments = lnGen(rri)
                    }
                    else {
                        fragments = Txt(rri.description)
                    }
                    columnized.insert(
                        HorizontallyAligned(lines: fragments.fragment(for: actualColumns[0]).lines,
                                            alignment: .bottomRight,
                                            width: actualColumns[0].width,
                                            wrapping: .char), at: 0)
                }
                let missingColumnCount = Swift.max(0, actualVisibleColumnCount - columnized.count)
                let currentCount = columnized.count - (lineNumberGenerator == nil ? 0 : 1)
                for k in 0..<missingColumnCount {
                    let len = actualVisibleColumns[currentCount + k].width.value
                    let emptyLineFragment = String(repeating: " ", count: len)
                    columnized.append(
                        HorizontallyAligned(lines: Array(repeating: emptyLineFragment, count: maxHeight),
                                            alignment: .topLeft,
                                            width: actualColumns[currentCount + k].width)
                    )
                }

                // Output row, line-by-line
                for columnData in columnized.prefix(actualColumns.count).alignVertically {
                    output.write(l + columnData.joined(separator: insideVerticalSeparator) + r)
                }
                // Dividers between rows
                if data.count > 0,
                   hasVisibleColumns,
                   i < lastValidIndex,
                   options.contains(.insideHorizontalFrame) {
                    output.write(lPad)
                    output.write(style.insideLeftVerticalSeparator(for: options))
                    output.write(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            String(repeating: style.insideHorizontalSeparator(for: options),
                                   count: $0.width.value)
                        }).joined(separator: style.insideHorizontalVerticalSeparator(for: options))
                    )
                    output.write(style.insideRightVerticalSeparator(for: options))
                    output.write("\(rPad)\n")
                }
                i += 1
            }
            // Dividers between row ranges
            if data.count > 0,
               hasVisibleColumns,
               ri < rnges.index(before: rnges.endIndex),
               options.contains(.insideHorizontalFrame) {
                output.write(lPad)
                output.write(style.insideLeftVerticalSeparator(for: options))
                output.write(
                    actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                        String(repeating: style.insideHorizontalRowRangeSeparator(for: options),
                               count: $0.width.value)
                    }).joined(separator: style.insideHorizontalVerticalSeparator(for: options))
                )
                output.write(style.insideRightVerticalSeparator(for: options))
                output.write("\(rPad)\n")
            }
        }


        // Bottom frame
        if options.contains(.bottomFrame) {
            output.write(lPad)
            output.write(style.bottomLeftCorner(for: options))
            if hasVisibleColumns {
                if data.count > 0 {
                    output.write(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            String(repeating: style.bottomHorizontalSeparator(for: options),
                                   count: $0.width.value)
                        }).joined(separator: style.bottomHorizontalVerticalSeparator(for: options))
                    )
                }
                else {
                    output.write(
                        actualColumns.filter({ $0.width.value > Width.hidden.value }).map({
                            String(repeating: style.bottomHorizontalSeparator(for: options),
                                   count: $0.width.value)
                        }).joined(separator: style.bottomHorizontalVerticalSeparator(for: options))
                    )
                }
            }
            else {
                output.write(
                    String(repeating: style.bottomHorizontalSeparator(for: options),
                           count: titleColumnWidth)
                )
            }
            output.write(style.bottomRightCorner(for: options))
            output.write("\(rPad)\n")
        }
    }
    /// Render table
    /// - Parameters:
    ///   - style: Frame style
    ///   - options: Framing options
    ///   - rows: Collection of row ranges to render, default value of `nil` means all rows
    ///   - leftPad: Pad left side of the table with `String`
    ///   - rightPad: Pad right side of the table with `String`
    /// - Returns: `String` containing rendered table
    public func render(style:FrameStyle = .default,
                       options:FramingOptions = .all,
                       rows ranges:[Range<Int>]? = nil,
                       leftPad:String = "",
                       rightPad:String = "") -> String {
        var result: any TextOutputStream = ""
        render(style: style,
               options: options,
               rows: ranges,
               leftPad: leftPad,
               rightPad: rightPad,
               to: &result)
        return result as! String
    }
    /// Render table
    /// - Parameters:
    ///   - style: Frame style
    ///   - options: Framing options
    ///   - rows: Range of table rows to render, `nil` means all rows
    ///   - leftPad: Pad left side of the table with `String`
    ///   - rightPad: Pad right side of the table with `String`
    /// - Returns: `String` containing rendered table
    public func render(frameStyle:FrameStyle = .default,
                       framingOptions:FramingOptions = .all,
                       rows range:Range<Int>,
                       leftPad:String = "",
                       rightPad:String = "") -> String {
        var result: any TextOutputStream = ""
        render(style: frameStyle,
               options: framingOptions,
               rows: [range],
               leftPad: leftPad, rightPad: rightPad,
               to: &result)
        return result as! String
    }
    /// Render table
    /// - Parameters:
    ///   - style: Frame style
    ///   - options: Framing options
    ///   - rows: Range of table rows to render, `nil` means all rows
    ///   - leftPad: Pad left side of the table with `String`
    ///   - rightPad: Pad right side of the table with `String`
    ///   - output: An output stream to receive the rendering result.
    /// - Returns: `String` containing rendered table
    public func render(style:FrameStyle = .default,
                       options:FramingOptions = .all,
                       rows range:Range<Int>,
                       leftPad:String = "",
                       rightPad:String = "",
                       to output:inout TextOutputStream) {
        render(style: style,
               options: options,
               rows: [range],
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
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.data = try container.decode([[Txt]].self, forKey: .data)
        self.columns = try container.decode([Col].self, forKey: .columns)
        self.title = try container.decode(Txt.self, forKey: .title)
    }
}
extension Tbl {
    // Convenience
    public convenience init(_ title:Txt? = nil,
                            columns:[Col] = [],
                            strings:[[String]]) {
        self.init(title, columns: columns,
                  cells: strings.map({ $0.map({ Txt($0) })}))
    }
    // Convenience
    public convenience init(_ title:String,
                            columns:[Col] = [],
                            strings:[[String]]) {
        self.init(Txt(title),
                  columns: columns,
                  cells: strings.map({ $0.map({ Txt($0) })}))
    }
    // Convenience
    public convenience init(_ title:String,
                            columns:[Col] = [],
                            cells:[[Txt]]) {
        self.init(Txt(title), columns: columns, cells: cells)
    }
    // DSL
    public convenience init(
        _ title:Txt?,
        @TblBuilder _ makeTable: () -> ([Col], [[Txt]])) {
        let (columns, data) = makeTable()
        self.init(title, columns: columns, cells: data)
    }
}
extension Tbl : Equatable {
    /// - Note: Ignores automatic line numbering
    public static func == (lhs: Tbl, rhs: Tbl) -> Bool {
        lhs.data == rhs.data &&
        lhs.columns == rhs.columns &&
        lhs.title == rhs.title
    }
}
extension Tbl : Encodable {

    enum CodingKeys : CodingKey {
        case data, columns, title, frameStyle, frameRenderingOptions
    }

    /// - Note: Doesn't include automatic line numbers in encoded data
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(data, forKey: .data)
        try container.encode(columns, forKey: .columns)
        try container.encode(title, forKey: .title)
    }

}
