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
        self.columns = columns
    }
    private func renderColumnRow(_ cols:[FixedCol]) -> [[String]] {
        let vc = cols.filter({ $0.isVisible })
        var ha:[HorizontallyAligned] = []
        var horizontallyAligned:[[String]] = []
        var lc = 0
        for fc in vc {
            let l = (fc.header ?? Txt("")).halign(for: fc)
            horizontallyAligned.append(l)
            lc = Swift.max(lc, l.count)
            let h = HorizontallyAligned(
                lines: l,
                alignment: fc.header?.alignment ?? fc.defaultAlignment,
                width: fc.width
            )
            ha.append(h)
        }
        return ha[...].alignVertically(height: lc)
    }

    /// Calculate title column width and actual column widths (for dynamic width columns)
    private func calculateTitleAndColumnWidths(frameStyle:FrameStyle, framingOptions:FramingOptions) -> (fixedColumns:[FixedCol], titleWidth: Int) {
        
        let (fixedCols, minRec, maxRec, histogram) = columns.collectTableInfo(
            using: data,
            cellDataContainsNewlines: cellsMayHaveNewlines,
            lineNumberGenerator: lineNumberGenerator
        )
        let verticalDividerCount = Swift.max(0, fixedCols.filter({$0.isHidden == false && $0.width > 0 }).count - 1)
        let sepLen = frameStyle.insideVerticalSeparator(for: framingOptions).count
        print("minRowElementCount", minRec, "maxRowElementCount", maxRec)
        print("rowElementCountHistogram", histogram)
        print("verticalDividerCount", verticalDividerCount, "sepLen", sepLen)
        let calculatedTitleWidth = fixedCols
            .reduce(verticalDividerCount * sepLen, { $0 + $1.width })

        // In general the entire table width is a sum of
        // visible column widths.
        
        guard data.isEmpty == false, maxRec > 0, calculatedTitleWidth > 0 else {
            // Not a single data cell exist => there won't
            // be any data rows to display, hence we'll
            // ignore the column space requirements and
            // return the required title width entirely
            // based on the title itself.
            guard title != nil else {
                return (fixedCols, 0)
            }
            return (fixedCols, titleMaxLen)
        }
        // At least one data cell exits => return a title
        // width which is based on how much space is
        // required by columns
        return (fixedCols, calculatedTitleWidth)
    }
    private var titleMaxLen:Int {
        guard let title = title else {
            return 0
        }
        return title
            .split(separator: "\n", omittingEmptySubsequences: false)
            .reduce(0, { Swift.max($0, $1.count) })
    }
    private func titleWidth(for frameStyle:FrameStyle, options:FramingOptions, fixedCols:[FixedCol]) -> Int {
        let visible = fixedCols.filter({ $0.isHidden == false })
        let visibleVerticalDividerCount = Swift.max(0, visible.count - 1)
        let separatorLen = frameStyle.insideVerticalSeparator(for: options).count
        let calculatedTitleWidth = fixedCols
            .reduce(
                visibleVerticalDividerCount * separatorLen,
                { $0 + $1.width }
            )
        return calculatedTitleWidth
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

        
        // Expensive: O(n)
        // Sweeps over all data cells once.
        // n = total number of elements in 2d array
        // Example: [[],[1],[2,3]] => n = 3
        let info = columns.collectTableInfo(
            using: data,
            cellDataContainsNewlines: cellsMayHaveNewlines,
            lineNumberGenerator: lineNumberGenerator
        )
//        print("fixed-columns  :", info.columns.map({ ($0.header ?? "nil", $0.width) }))
//        for a in renderColumnRow(info.columns) {
//            print(a.joined(separator: " "))
//        }
        let hasTitle = title != nil
        let fixedColumns = info.columns
        //let minRowElementCount = info.minRowElementCount
        let maxRowElementCount = info.maxRowElementCount
        //let rowElementCountHistogram = info.rowElementCountHistogram
        let hasData = data.isEmpty == false && maxRowElementCount > 0
        let hasSomeColumnHeaders = fixedColumns
            .filter({ $0.isHidden == false && $0.header != nil })
            .isEmpty == false && fixedColumns.isEmpty == false
        let visibleColumns = fixedColumns
            .filter({ $0.isHidden == false })
        //let hasSomeVisibleColumns = visibleColumns.isEmpty == false
        let hasVisibleColumns = visibleColumns.isEmpty == false//!fixedColumns.allSatisfy({ $0.isHidden })
        
        let titleWidth:Int
        // In general the entire table width is a sum of
        // visible column widths.
        //let tableWidthFromColumns = visibleColumns.reduce(0, { $0 + $1.width })
        if hasData {
            // At least one data cell exits => return a title
            // width which is based on how much space is
            // required by columns
            titleWidth = self.titleWidth(
                for: style,
                options: options,
                fixedCols: visibleColumns
            )
        }
        else {
            // If there is no data - we should show columns to
            // their respective widths (using column header itself
            // as it would be the cell data).
            
            let fakeCells:[[Txt]] = [
                visibleColumns
                    .filter({ $0.isHidden == false })
                    .map({ $0.header ?? Txt("") })
            ]
            let fake = columns.collectTableInfo(
                using: fakeCells,
                lineNumberGenerator: lineNumberGenerator)
            let fakeVisibleColumns = fake
                .columns
                .filter({ $0.isHidden == false })
            let len = fakeVisibleColumns
                .reduce(0, { $0 + $1.width == 0 ? $1.header?.string.count ?? 0 : $1.width })
            let b = Swift.max(0, fakeVisibleColumns.count - 1)
            let c = style.insideVerticalSeparator(for: options).count
            
            if fakeVisibleColumns.isEmpty == false {
                titleWidth = len + (b * c)
            }
            else {
                titleWidth = titleMaxLen
            }
        }

//        print("========================================")
//        print("hasData:", hasData)
//        print("hasTitle:", hasTitle, "'\(title?.string ?? "nil")'")
//        print("columns:")
//        visibleColumns
//            .forEach({ print(" ", "'\($0.header?.string ?? "nil")'", "width:", $0.width, "ref:", $0.ref) })
//
//        print("hasVisibleColumns:", hasVisibleColumns, visibleColumns.count)
//        print("hasSomeColumnHeaders:", hasSomeColumnHeaders)
//        print("titleColumnWidth:", titleWidth)
//        print("lngen:", lineNumberGenerator as Any)
//        print("========================================")

        var rnges:[Range<Int>] = []
        // Validate row ranges
        for range in ranges ?? [(0..<data.count)] {
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
        //print(fixedColumns.map({ ($0.header?.string, $0.width) }))
        
        let lngen = lineNumberGenerator ?? { i in Txt(i.description) }

        // Output the table

        
        // MARK: Top frame
        if options.contains(.topFrame) {
            output.write(lPad)
            output.write(style.topLeftCorner(for: options))
            if hasTitle {
                output.write(
                    String(repeating: style.topHorizontalSeparator(for: options),
                           count: titleWidth)
                )
            }
            else if (hasVisibleColumns) {
                output.write(
                    visibleColumns.map({
                        String(repeating: style.topHorizontalSeparator(for: options),
                               count: $0.width)
                    }).joined(separator: style.topHorizontalVerticalSeparator(for: options))
                )
            }
            output.write(style.topRightCorner(for: options))
            output.write("\(rPad)\n")
        }


        // MARK: Title
        if let title = title {
            // title obeys newlines as well
            let splitted = title.string
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map {
                    Txt(String($0), alignment: title.alignment, wrapping: title.wrapping)
                }
            let base = ColumnBase(
                defaultAlignment: title.alignment ?? .middleCenter,
                defaultWrapping: title.wrapping ?? .word,
                contentHint: .unique
            )

            let col = FixedCol(base, width: titleWidth, ref: -1, hidden: false)
            // get title fragments
            let titleFragments:[String] = splitted.flatMap { $0.fragment(for: col).lines }
            // output title
            for fragment in titleFragments {
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
               (hasVisibleColumns && hasSomeColumnHeaders) || hasData || hasTitle {
                output.write(lPad)
                output.write(style.insideLeftVerticalSeparator(for: options))
                if hasVisibleColumns && (hasSomeColumnHeaders || hasData) {
                    output.write(
                        fixedColumns
                            .map({
                            return String(repeating: style.insideHorizontalSeparator(for: options),
                                          count: Swift.max(0, $0.width))
                        }).joined(separator: style.topHorizontalVerticalSeparator(for: options))
                    )
                }
                else {
                    output.write(
                        String(repeating: style.insideHorizontalSeparator(for: options),
                               count: titleWidth)
                    )
                }
                output.write(style.insideRightVerticalSeparator(for: options))
                output.write("\(rPad)\n")
            }
        }


        // MARK: Column headers
        if hasSomeColumnHeaders, hasVisibleColumns {
            let alignedColumnHeaders = fixedColumns
                .compactMap({ column in
                    return (column.header ?? Txt("")).fragment(for: column)
                })
                .dropFirst(0) // <= Convert Array to ArraySlice
                .alignVertically(height: 0)
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
                if hasSomeColumnHeaders && hasVisibleColumns {
                    output.write(
                        fixedColumns
                            .map({
                                String(repeating: style.insideHorizontalSeparator(for: options),
                                       count: $0.width)
                            }).joined(separator: style.insideHorizontalVerticalSeparator(for: options))
                    )
                }
                else if title != nil {
                    if hasVisibleColumns {
                        output.write(
                            fixedColumns
                                .map({
                                    String(repeating: style.insideHorizontalSeparator(for: options),
                                           count: $0.width)
                                }).joined(separator: style.topHorizontalVerticalSeparator(for: options))
                        )
                    }
                    else {
                        output.write(
                            String(repeating: style.insideHorizontalSeparator(for: options),
                                   count: titleWidth)
                        )
                    }
                }
                output.write(style.insideRightVerticalSeparator(for: options))
                output.write("\(rPad)\n")
            }
        }


        // Helper function to get newline splitted fragments
        func getNewlineSplittedFragments(for visibleColumnIndex:Int, row:[Txt]) -> [String] {

            let columnIndex = visibleColumnIndex + (lineNumberGenerator == nil ? 0 : 1)
            let columnWidth:Int = fixedColumns[visibleColumnIndex].width
            let alignment = visibleColumnIndex < row.count ? (row[visibleColumnIndex].alignment ?? fixedColumns[columnIndex].defaultAlignment) : fixedColumns[columnIndex].defaultAlignment
            let wrapping = visibleColumnIndex < row.count ? (row[visibleColumnIndex].wrapping ?? fixedColumns[columnIndex].defaultWrapping) : fixedColumns[columnIndex].defaultWrapping

            let splits = (visibleColumnIndex < row.count ? row[visibleColumnIndex].string : "")
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map({ ele in
                    let str = String(repeating: " ", count: columnWidth)
                    guard ele.isEmpty else {
                        return Txt(String(ele), alignment: alignment, wrapping: wrapping)
                    }
                    return Txt(str, alignment: alignment, wrapping: wrapping)
                })

            let combined:[String] = splits.flatMap({ $0.fragment(for: fixedColumns[columnIndex]).lines })
            return combined
        }


        // MARK: Data rows
        for (ri, rnge) in zip(0..., rnges) {
//            var cache:[UInt32:[Int:HorizontallyAligned]] = [:]
//            var cacheHits:Int = 0
//            var cacheMisses:Int = 0

            let lastValidIndex = rnge.upperBound - 1
//            let actualVisibleColumns = fixedColumns/*.filter({ $0.dynamicWidth.isVisible })*/
//            let actualVisibleColumnCount = fixedColumns.count
//            let visibleColumnIndexes = fixedColumns.map({ $0.ref })
//            let visibleColumnIndexes = fixedColumns
//                .enumerated()
//                .map({ $0.offset })
//                .prefix(Swift.min(actualVisibleColumnCount, Int(UInt16.max)))
            /*
            let (avcc, vci, avc) = calcVisibleColumns(for: actualColumns, from: data, newlines: cellsMayHaveNewlines)
            print("XXX:", actualVisibleColumnCount, "==", avcc,
                  visibleColumnIndexes, "==", vci,
                  actualVisibleColumns == avc)*/
            // Main loop to render row/column data
            for (rowRangeIndex, row) in zip(rnge.lowerBound..., data[rnge]) {

                guard row.isEmpty == false else { continue }
//                guard row.count <= (fixedColumns.first?.ref ?? row.count) else {
//                    fatalError("\(row.count) < \(fixedColumns.first?.ref) ?? \(row.count)")//continue
//                }
                var mxHeight = 0
                var clmnzed:[HorizontallyAligned] = []
                for v in fixedColumns {
                    let cell = v.ref < 0 ? lngen(rowRangeIndex) : (v.ref < row.count ? row[v.ref] : Txt(""))
                    let alignment = v.ref < 0 ? cell.alignment ?? v.defaultAlignment : cell.alignment ?? v.defaultAlignment
                                        
                    let splits = cell
                        .split(separator: "\n", omittingEmptySubsequences: false)
                        .map({ ele in
                            let str = String(repeating: " ", count: v.width)
                            guard ele.isEmpty else {
                                return Txt(String(ele),
                                           alignment: cell.alignment ?? v.defaultAlignment,
                                           wrapping: cell.wrapping ?? v.defaultWrapping)
                            }
                            return Txt(str,
                                       alignment: cell.alignment ?? v.defaultAlignment,
                                       wrapping: cell.wrapping ?? v.defaultWrapping)
                        })
                    
                    let combined:[String] = splits
                        .flatMap {
                            $0.fragment(for: v).lines
                        }
                    let ha = HorizontallyAligned(
                        lines: combined,
                        alignment: alignment,
                        width: v.width,
                        wrapping: v.defaultWrapping
                    )
                    clmnzed.append(ha)
                    mxHeight = Swift.max(mxHeight, ha.lines.count)
                }
                // Generate empty cells for missing column data.
                let missingColumnCount = Swift.max(0, fixedColumns.count - clmnzed.count)
                let currentCount = clmnzed.count - (lineNumberGenerator == nil ? 0 : 1)
                for k in 0..<missingColumnCount {
                    let len:Int = fixedColumns[currentCount + k].width
                    let emptyLineFragment = String(repeating: " ", count: len)
                    clmnzed.append(
                        HorizontallyAligned(
                            lines: Array(repeating: emptyLineFragment, count: mxHeight),
                            alignment: .topLeft,
                            width: fixedColumns[currentCount + k].width
                        )
                    )
                }

                for columnData in clmnzed.prefix(fixedColumns.count).alignVertically(height: mxHeight) {
                    output.write(l + columnData.joined(separator: insideVerticalSeparator) + r)
                }
//                var horizontallyAlignedCells:[[String]] = []
//                var requiredRowHeight = 0
                // Sweep 1
                //print("ACTUAL COLUMNS:", actualColumns)
                //print("ACTUAL VISIBLE COLUMNS:", actualVisibleColumns)
                /*
                for columnIndex in visibleColumnIndexes {
                    let cell = columnIndex < row.count ? row[columnIndex] : Txt("")
                    let defwrp = fixedColumns[columnIndex].defaultWrapping
                    let defalign = fixedColumns[columnIndex].defaultAlignment
                    let lines:[String] = cell
                        .getHAlignedCell(defaultWrapping: defwrp,
                                         defaultAlignment: defalign,
                                         width: fixedColumns[columnIndex].width)
                    //lines.forEach({ print("XYZ  : '\($0)'") })
                    requiredRowHeight = Swift.max(requiredRowHeight, lines.count)
                    horizontallyAlignedCells.append(lines)
                }*/
                //print("REQRH: \(requiredRowHeight)")
                // Sweep 2
                /*
                var horizontallyAndVerticallyAlignedCells:[[String]] = []
                for (i,cell) in zip(visibleColumnIndexes, horizontallyAlignedCells) {
                    let padder = String(repeating: ".", count: fixedColumns[i].width)
                    let padAmount = requiredRowHeight - cell.count
                    switch fixedColumns[i].defaultAlignment {
                    case .topLeft, .topRight, .topCenter:
                        horizontallyAndVerticallyAlignedCells
                            .append(Array(repeating: padder, count: padAmount) + cell)
                    case .bottomLeft, .bottomRight, .bottomCenter:
                        horizontallyAndVerticallyAlignedCells
                            .append(cell + Array(repeating: padder, count: padAmount))
                    case .middleLeft, .middleRight, .middleCenter:
                        break
                    }                    
                }*/
//                print("H&V:")
//                horizontallyAndVerticallyAlignedCells
//                    .transposed()
//                    .forEach({ print("H&V:\t'\($0)'") })

                // Storage for columnized cell data
                var columnized:ArraySlice<HorizontallyAligned> = []

                // Column index offset
                // lineNumberGenerator in use => offset = 1
                // lineNumberGenerator not in use => offset = 0
                //let offset = lineNumberGenerator == nil ? 0 : 1

                // Calculate required number of "terminal" rows
                // for this table row
                /*
                let maxHeight:Int = visibleColumnIndexes
                    .filter { $0 < row.count }
                    .map {
                        let columnIndex = $0 + offset
                        if fixedColumns[$0].contentHint == .repetitive {
                            // Data in this column "may" be repetitive
                            // Let's cache the values
                            
                            // We have to take width and alignment into
                            // account as differences in them will result
                            // different output (even if the cell string
                            // would be the same).
                            
                            // Combine width & alignment
                            let u32:UInt32 = (UInt32(fixedColumns[columnIndex].width) << 16) +
                            UInt32(row[$0].alignment?.rawValue ?? fixedColumns[columnIndex].defaultAlignment.rawValue)

                            // Try to get value from the cache
                            if let fromCache = cache[u32]?[row[$0].string.hashValue] {
                                // We've got it
                                columnized.append(fromCache)
                                cacheHits += 1 // internal stats
                                // return line count
                                return fromCache.lines.count
                            }
                            else {
                                // Not found from cache

                                // Generate the new cell (obeying newlines)
                                let fragments = getNewlineSplittedFragments(for: $0, row: row)
                                let alignment = row[$0].alignment ?? fixedColumns[columnIndex].defaultAlignment
                                let ha = HorizontallyAligned(
                                    lines: fragments,
                                    alignment: alignment,
                                    width: fixedColumns[columnIndex].width,
                                    wrapping: fixedColumns[$0].defaultWrapping
                                )
                                columnized.append(ha)

                                // Write to cache
                                cache[u32, default:[:]][row[$0].string.hashValue] = ha
                                cacheMisses += 1
                                return fragments.count
                            }
                        }
                        else {
                            // Cells in this column are "hinted" to be unique
                            // => don't use cache
                            let fragments = getNewlineSplittedFragments(for: $0, row: row)
                            let a = row[$0].alignment ?? fixedColumns[columnIndex].defaultAlignment
                            let ha = HorizontallyAligned(lines: fragments,
                                                         alignment: a,
                                                         width: fixedColumns[columnIndex].width,
                                                         wrapping: fixedColumns[$0].defaultWrapping)
                            columnized.append(ha)
                            return fragments.count
                        }
                    }
                    .reduce(0, { Swift.max($0, $1) })
                 */

                // Generate custom line numbers?
                if lineNumberGenerator != nil {
                    let fragments:Txt
                    if let lnGen = lineNumberGenerator {
                        fragments = lnGen(rowRangeIndex)
                    }
                    else {
                        fragments = Txt(rowRangeIndex.description)
                    }
                    columnized.insert(
                        HorizontallyAligned(lines: fragments.fragment(for: fixedColumns[0]).lines,
                                            alignment: .bottomRight,
                                            width: fixedColumns[0].width,
                                            wrapping: .char), at: 0)
                }


                // Generate empty cells for missing column data.
                /*
                let missingColumnCount = Swift.max(0, actualVisibleColumnCount - columnized.count)
                let currentCount = columnized.count - offset
                for k in 0..<missingColumnCount {
                    let len:Int = actualVisibleColumns[currentCount + k]!.width
                    let emptyLineFragment = String(repeating: " ", count: len)
                    columnized.append(
                        HorizontallyAligned(lines: Array(repeating: emptyLineFragment, count: maxHeight),
                                            alignment: .topLeft,
                                            width: fixedColumns[currentCount + k]!.width)
                    )
                }*/


                // Output row, line-by-line
                /*
                for columnData in columnized.prefix(fixedColumns.count).alignVertically(height: maxHeight) {
                    output.write(l + columnData.joined(separator: insideVerticalSeparator) + r)
                }
                 */

                // MARK: Dividers between rows
                if data.count > 0,
                   hasVisibleColumns,
                   rowRangeIndex < lastValidIndex,
                   options.contains(.insideHorizontalFrame) {
                    output.write(lPad)
                    output.write(style.insideLeftVerticalSeparator(for: options))
                    output.write(
                        fixedColumns.map({
                            String(repeating: style.insideHorizontalSeparator(for: options),
                                   count: $0.width)
                        }).joined(separator: style.insideHorizontalVerticalSeparator(for: options))
                    )
                    output.write(style.insideRightVerticalSeparator(for: options))
                    output.write("\(rPad)\n")
                }
            }
            // MARK: Dividers between row ranges
            if data.count > 0,
               hasVisibleColumns,
               ri < rnges.index(before: rnges.endIndex),
               options.contains(.insideHorizontalFrame) {
                output.write(lPad)
                output.write(style.insideLeftVerticalSeparator(for: options))
                output.write(
                    fixedColumns
                        .map({
                            String(repeating: style.insideHorizontalRowRangeSeparator(for: options),
                                   count: $0.width)
                        }).joined(separator: style.insideHorizontalVerticalSeparator(for: options))
                )
                output.write(style.insideRightVerticalSeparator(for: options))
                output.write("\(rPad)\n")
            }
        }


        // MARK: Bottom frame
        if options.contains(.bottomFrame) {
            output.write(lPad)
            output.write(style.bottomLeftCorner(for: options))
            if hasVisibleColumns {
                if data.count > 0 {
                    output.write(
                        visibleColumns
                            .map({
                                String(repeating: style.bottomHorizontalSeparator(for: options),
                                       count: $0.width)
                            }).joined(separator: style.bottomHorizontalVerticalSeparator(for: options))
                    )
                }
                else {
                    output.write(
                        visibleColumns
                            .map({
                                String(repeating: style.bottomHorizontalSeparator(for: options),
                                       count: $0.width)
                            }).joined(separator: style.bottomHorizontalVerticalSeparator(for: options))
                    )
                }
            }
            else {
                output.write(
                    String(repeating: style.bottomHorizontalSeparator(for: options),
                           count: titleWidth)
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
                        return $0.dynamicWidth != .hidden
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
                guard (columns[i].dynamicWidth == .hidden && includingHiddenColumns == false) == false else {
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
// MARK: -
import DebugKit

internal let maxColumnCount:Int = Int(UInt16.max)
/// Default line number generator
///
/// Generates default line numbers (base-10). Default
/// line number generator generates line numbers starting
/// from 1.
///
/// - Note: lineNumberGenerator function is called for
/// each line (on given ranges) with two arguments, first
/// argument is the line number and second argument is
/// the column width.
public let defaultLnGen:(Int) -> Txt = { n in
    return n == -1 ? Txt("#", alignment: .bottomCenter) : Txt((1 + n).description)
}
extension DebugTopic {
    // Topics
    public static let info = DebugTopic(level: 0, "info")
    public static let warning = DebugTopic(level: 1, "warning")
    public static let error = DebugTopic(level: 2, "error")
    public static let telemetry = DebugTopic(level: 3, "telemetry")
    public static let cache = DebugTopic(level: 4, "cache")
    public static let debug = DebugTopic(level: 5, "debug")
    // A allTopics "mask" including all topics
    public static let allTopics:DebugTopicSet = [
        .info, .warning, .error, .telemetry, .cache, .debug
    ]
}
// MARK: -
public final class Tbl2 {
    /// Table cell data
    public let cells:[[Txt]]
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

    private let lineNumberGenerator:((Int)->Txt)?

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
    
    public var debugMask:DebugTopicSet = []
    
    /// Initializes table
    ///
    /// - Parameters:
    ///     - title: Table title
    ///     - columns: Table column definitions
    ///     - cells: Table cell data
    ///
    
    public init(_ title:Txt? = nil,
                columns: [Col] = [],
                cells:[[Txt]],
                lineNumberGenerator:((Int)->Txt)? = nil) {
        
        precondition(columns.count <= maxColumnCount, "Maximum column count is limited to \(maxColumnCount).")

        self.cells = cells
        self.title = title
        self.columns = columns
        self.lineNumberGenerator = lineNumberGenerator

        dbg(.info, debugMask, prefix: "\(type(of: self))", "\(columns.count) columns")
        dbg(.info, debugMask, prefix: "\(type(of: self))", "\(cells.reduce(0, { $0 + $1.count })) cells")
    }
    // DSL
    public convenience init(
        _ title:Txt?,
        @TblBuilder _ makeTable: () -> ([Col], [[Txt]])) {
            let (columns, cells) = makeTable()
            self.init(title, columns: columns, cells: cells)
    }
    private func titleCellWidth(style:FrameStyle,
                                options:FramingOptions,
                                for columns:[FixedCol]) -> Int {
        let ivsLen = style.insideVerticalSeparator(for: options).count
        let titleCellWidth = columns.reduce(0, { $0 + $1.width }) + ((columns.count - 1) * ivsLen)
        dbg(.debug, debugMask, prefix: "\(type(of: self))", "\(#function) returning \(titleCellWidth)")
        return titleCellWidth
    }
    public func render(style:FrameStyle = .default,
                      options:FramingOptions = .all,
                      rows ranges:[Range<Int>]? = nil,
                      leftPad:String = "",
                      rightPad:String = "",
                      to out: inout String) {

        cells.renx(
            title: title,
            columns: columns,
            style: style,
            options: options,
            rows: ranges,
            leftPad: leftPad,
            rightPad: rightPad,
            to: &out,
            debugMask: debugMask,
            lineNumberGenerator: lineNumberGenerator)
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
        var result: String = ""
        render(style: style,
               options: options,
               rows: ranges,
               leftPad: leftPad,
               rightPad: rightPad,
               to: &result)
        return result
    }
    /// Convert table data to CSV format
    /// - Returns: `String` containing table data formatted as CSV
    public func csv(delimiter:String = ";", withColumnHeaders:Bool = true, includingHiddenColumns:Bool = false) -> String {
        let maxRowCellCount = cells.reduce(0, { Swift.max($0, $1.count) })
        var result = ""
        let c:[Col] = columns + Array(repeating: Col(""), count: Swift.max(0, maxRowCellCount - columns.count))
        if withColumnHeaders {
            let headers = c
                .filter({
                    if includingHiddenColumns {
                        return true
                    }
                    else {
                        return $0.dynamicWidth != .hidden
                    }
                })
                .map({ $0.header?.string ?? ""})
                .joined(separator: delimiter)
            print(headers + (headers.isEmpty ? "" : delimiter), to: &result)
        }
        
        for row in cells {
            var rowElements:[String] = []
            for (i,col) in row.enumerated() {
                guard c.indices.contains(i),
                      (c[i].dynamicWidth == .hidden && includingHiddenColumns == false) == false else {
                    continue
                }
                rowElements.append(col.string)
            }
            print(rowElements.joined(separator: delimiter) + String(repeating: delimiter, count: Swift.max(0, c.count - row.count)) + delimiter, to: &result)
        }
        return result
    }
}
extension Tbl2 : Encodable, Decodable {
    enum CodingKeys : CodingKey {
        case debugMask, cellsMayHaveNewlines, cells, columns, title
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(cellsMayHaveNewlines, forKey: .cellsMayHaveNewlines)
        try container.encode(debugMask, forKey: .debugMask)
        try container.encode(cells, forKey: .cells)
        try container.encode(columns, forKey: .columns)
        try container.encode(title, forKey: .title)
        // NOTE: Automatic line number generator is not included in encoded object
        // TODO: Allow setting of lineNumberGenerator after init
    }
    public convenience init(from decoder:Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let cellsMayHaveNewlines = try container.decode(Bool.self, forKey: .cellsMayHaveNewlines)
        let debugMask = try container.decode(DebugTopicSet.self, forKey: .debugMask)
        let cells = try container.decode([[Txt]].self, forKey: .cells)
        let columns = try container.decode([Col].self, forKey: .columns)
        let title = try container.decode(Txt.self, forKey: .title)
        self.init(title, columns: columns, cells: cells, lineNumberGenerator: nil)
        self.cellsMayHaveNewlines = cellsMayHaveNewlines
        self.debugMask = debugMask
    }
}
extension Tbl2 : Equatable {
    /// - Note: Ignores automatic line numbering
    public static func == (lhs: Tbl2, rhs: Tbl2) -> Bool {
        lhs.cells == rhs.cells &&
        lhs.columns == rhs.columns &&
        lhs.title == rhs.title &&
        lhs.cellsMayHaveNewlines == rhs.cellsMayHaveNewlines
    }
}
