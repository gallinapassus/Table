
import Foundation
import DebugKit

extension Array where Element == [Txt] {
    private func titleCellWidth(style:FrameStyle,
                                options:FramingOptions,
                                visibleColumns:[FixedCol]) -> Int? {
        // Do we have any visible columns?
        guard visibleColumns.isEmpty == false else {
            return nil
        }
        let ivsLen = style.insideVerticalSeparator(for: options).count
        if visibleColumns.allSatisfy({ $0.dynamicWidth == .collapsed }) ||
            visibleColumns.allSatisfy({ $0.width == 0 }) {
            return Swift.max(0, visibleColumns.count - 1) * ivsLen
        }
        let w:Int = visibleColumns
            .reduce(0, { $0 + $1.width }) + ((Swift.max(0, visibleColumns.count - 1)) * ivsLen)
        let ret:Int? = w < 1 ? nil : w
        return ret
    }
    /// Render Array elements as table
    /// - Parameters:
    ///   - title:Optional table title
    ///   - columns:Optional table table columns
    ///   - style: Frame style
    ///   - options: Framing options
    ///   - rows: Optional collection of row ranges to render,
    ///   default value of `nil` means, render all rows
    ///   - leftPad: Pad left side of the table with `String`
    ///   - rightPad: Pad right side of the table with `String`
    ///   - to: Receiver for the rendering result
    ///   - debugMask: Debug mask value, default (no debugging)
    ///   - lineNumberGenerator: Optional customizable line
    ///   number generator

    public func render(title:Txt? = nil,
                       columns:[Col]? = nil,
                       style:FrameStyle = .default,
                       options:FramingOptions = .all,
                       rows:[Range<Int>]? = nil,
                       leftPad:String = "",
                       rightPad:String = "",
                       to out: inout String,
                       debugMask:DebugTopicSet = [],
                       lineNumberGenerator:((Int)->Txt)? = nil) {

        if let ranges = rows {
            ranges.forEach {
                guard $0.lowerBound >= 0, $0.upperBound <= count else {
                    let msg = "Range \($0) out of bounds"
                    dbg(.error, debugMask, msg)
                    fatalError(msg)
                }
            }
        }

        let rnges = rows
        
        // Pre-format cells and get fixed width columns
        let t0 = DispatchTime.now().uptimeNanoseconds
        let (preFormattedRowRanges, fixedColumns) = preFormat(
            title: title,
            columns: columns ?? [],
            cells: self,
            ranges: rnges,
            debugMask: debugMask,
            lnGen: lineNumberGenerator)
        let t1 = DispatchTime.now().uptimeNanoseconds
        let ms = Double(t1 - t0) / 1_000_000
        if debugMask.contains(.columns) {
            dbg(.columns, "Provided columns:")
            columns?.forEach({ dbg(.columns, "  \($0)") })
            dbg(.columns, "Derived columns:")
            fixedColumns.forEach({ dbg(.columns, "  \($0)") })
        }
        dbg(.telemetry, debugMask, "Table pre-formatting took \(ms) ms")

        let hasTitle = title != nil
        let visibleColumns = fixedColumns.filter({ $0.isVisible })
        let hasVisibleColumns = visibleColumns.isEmpty == false
        dbg(.columns, debugMask, "visible column count \(visibleColumns.count), hasVisibleColumns = \(hasVisibleColumns)")
        let hasData = isEmpty == false
        let hasSomeColumnHeaders = fixedColumns
            .filter({ $0.isVisible && $0.header != nil })
            .isEmpty == false && fixedColumns.isEmpty == false
        
        let titleWidth = titleCellWidth(style: style, options: options, visibleColumns: visibleColumns) ?? title?.count ?? 0
        
        
        // Seprators etc.
        let leftVerticalSeparator = style.leftVerticalSeparator(for: options)
        let rightVerticalSeparator = style.rightVerticalSeparator(for: options)
        let l = "\(leftPad)\(leftVerticalSeparator)"
        let r = "\(rightVerticalSeparator)\(rightPad)\n"
        let insideVerticalSeparator = style.insideVerticalSeparator(for: options)
        // Cache
        var cache:[String:[CellHash:[String]]] = [:]
        var cacheHit:Int = 0
        var cacheMiss:Int = 0
        var cacheWrite:Int = 0
        // Output
        // MARK: Top frame
        if options.contains(.topFrame) {
            out.write(leftPad)
            out.write(style.topLeftCorner(for: options))
            if hasTitle {
                out.write(
                    String(repeating: style.topHorizontalSeparator(for: options),
                           count: titleWidth)
                )
            }
            else if (hasVisibleColumns) {
                out.write(
                    visibleColumns.map({
                        String(repeating: style.topHorizontalSeparator(for: options),
                               count: $0.width)
                    }).joined(separator: style.topHorizontalVerticalSeparator(for: options))
                )
            }
            out.write(style.topRightCorner(for: options))
            out.write("\(rightPad)\n")
        }

        // MARK: Title
        if let title = title {
            // title obeys newlines as well
            let splitted = title.string
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map {
                    Txt(String($0), alignment: title.alignment, wrapping: title.wrapping)
                }
            // get title fragments
            let titleFragments:[[String]] = splitted.map {
                $0.halign(defaultAlignment: title.alignment ?? .bottomCenter,
                          defaultWrapping: title.wrapping ?? .word,
                          width: titleWidth)
            }
            //dbg(.info, debugMask, prefix: "title", "w=\(titleWidth) \(splitted.description) -> \(titleFragments)")

            // output title
            for fragments in titleFragments {
                for fragment in fragments {
                    out.write(
                        leftPad +
                        style.leftVerticalSeparator(for: options) +
                        fragment +
                        style.rightVerticalSeparator(for: options) +
                        "\(rightPad)\n")
                }
            }
            
            // Divider between title and column headers -or-
            // divider between title and data
            
            if options.contains(.insideHorizontalFrame),
               (hasVisibleColumns && hasSomeColumnHeaders) || hasData || hasTitle {
                out.write(leftPad)
                out.write(style.insideLeftVerticalSeparator(for: options))
                if hasVisibleColumns && (hasSomeColumnHeaders || hasData) {
                    out.write(
                        fixedColumns
                            .filter({ $0.isVisible })
                            .map({
                                return String(repeating: style.insideHorizontalSeparator(for: options),
                                              count: Swift.max(0, $0.width))
                            }).joined(separator: style.topHorizontalVerticalSeparator(for: options))
                    )
                }
                else {
                    out.write(
                        String(repeating: style.insideHorizontalSeparator(for: options),
                               count: titleWidth)
                    )
                }
                out.write(style.insideRightVerticalSeparator(for: options))
                out.write("\(rightPad)\n")
            }
        }

        // MARK: Column headers
        if hasSomeColumnHeaders, hasVisibleColumns {
            // Get horizontally aligned column headers
            let alignedColumnHeaders:[[String]] = visibleColumns
                .map({ column in
                    if column.dynamicWidth == .collapsed ||
                        column.width == 0 {
                        return [""]
                    }
                    let colHeader = column.header ?? Txt(String(repeating: " ", count: column.width))
                    let fragmentedColHeader:[String] = colHeader
                        .halign(
                            defaultAlignment: colHeader.alignment ?? column.defaultAlignment,
                            defaultWrapping: colHeader.wrapping ?? column.defaultWrapping,
                            width: column.width
                        )
                    return fragmentedColHeader
                })
            // Find out max column height
            let maxColHeight = alignedColumnHeaders
                .reduce(0, { Swift.max($0, $1.count) })
            // Align columns vertically
            let valignedColumnHeaders = alignedColumnHeaders.enumerated()
                .map {
                    let colHeaderAlignment =
                    visibleColumns[$0].header?.alignment ?? // alignment from header Txt
                    visibleColumns[$0].defaultAlignment // alignment from column
                    let valigned = $1.valign(colHeaderAlignment, height: maxColHeight)
                    return valigned
                }
            for f in valignedColumnHeaders.transposed() {
                out.write(leftPad)
                out.write(style.leftVerticalSeparator(for: options))
                out.write(f.joined(separator: style.insideVerticalSeparator(for: options)))
                out.write(style.rightVerticalSeparator(for: options))
                out.write("\(rightPad)\n")
            }
            
            // Divider, before data
            if options.contains(.insideHorizontalFrame) {
                out.write(leftPad)
                
                out.write(style.insideLeftVerticalSeparator(for: options))
                if hasSomeColumnHeaders && hasVisibleColumns {
                    out.write(
                        fixedColumns
                            .filter({ $0.isVisible })
                            .map({
                                String(repeating: style.insideHorizontalSeparator(for: options),
                                       count: $0.width)
                            }).joined(separator: style.insideHorizontalVerticalSeparator(for: options))
                    )
                }
                else if title != nil {
                    if hasVisibleColumns {
                        out.write(
                            fixedColumns
                                .filter({ $0.isVisible })
                                .map({
                                    String(repeating: style.insideHorizontalSeparator(for: options),
                                           count: $0.width)
                                }).joined(separator: style.topHorizontalVerticalSeparator(for: options))
                        )
                    }
                    else {
                        out.write(
                            String(repeating: style.insideHorizontalSeparator(for: options),
                                   count: titleWidth)
                        )
                    }
                }
                out.write(style.insideRightVerticalSeparator(for: options))
                out.write("\(rightPad)\n")
            }
        }
        // MARK: Row ranges
        let ranges:[Range<Int>] = rnges ?? (hasData ? [0..<count] : [0..<0])
        for (rri, rowRange) in ranges.enumerated() {
            let lastValidIndex = Swift.max(0, rowRange.upperBound - 1)
            dbg(.info, debugMask, "Row range (\(rri)): \(rowRange)")
            guard hasData else {
                dbg(.info, debugMask, "No data")
                continue
            }
            for (ri, sourceRow) in zip(rowRange.lowerBound..., preFormattedRowRanges[rri]) {
                var formattedRow:[(Alignment?,[String])] = []
                var rowHeight = 0
                // Pad source row with missing elements, making all rows
                // to have same amount of elements.
                var row:[[Txt]] = sourceRow
                for i in row.count..<(row.count + Swift.max(0, fixedColumns.count - sourceRow.count)) {
                    if fixedColumns[i].dynamicWidth == .collapsed {
                        row.append([])
                    }
                    else {
                    let txt = Txt(String(repeating: " ", count: fixedColumns[i].width))
                        if rowRange.isEmpty {
                            row.append([])
                        }
                        else {
                            row.append([txt])
                        }
                    }
                }

                guard row.count == fixedColumns.count else {
                    let msg = "internal inconsistency error"
                    dbg(.error, debugMask, msg)
                    fatalError(msg)
                }
                // Process the single row column by column
                var _key:String? = nil
                var _hash:CellHash? = nil
                for (ci,col) in row.enumerated() {
                    let fixedColumn = fixedColumns[ci]
                    guard fixedColumn.isVisible else {
                        formattedRow.append((nil, []))
                        continue
                    }

                    if fixedColumn.contentHint == .repetitive,
                       ci < sourceRow.count,
                       let txt = sourceRow[ci].first {
                        _key = txt.string
                        _hash = CellHash(
                            width: fixedColumn.width,
                            alignment: txt.alignment ?? fixedColumn.defaultAlignment,
                            wrapping: txt.wrapping ?? fixedColumn.defaultWrapping,
                            trimming: fixedColumn.trimming
                        )
                        if let _ = cache[_key!]?[_hash!] {
                            cacheHit += 1
                        }
                        else {
                            cacheMiss += 1
                        }
                        dbg(.cache, debugMask, "(\(ri),\(ci)) \(cacheHit) \(cacheMiss) \(cacheWrite) \(cache.count)")
                    }

                    var combined:[String] = []
                    if fixedColumn.width == 0 {
                        combined.append("")
                    }
                    else {
                        for (_, fragment) in col.enumerated() {
                            let haligned = fragment.halign(
                                defaultAlignment: fixedColumn.defaultAlignment,
                                defaultWrapping: fixedColumn.defaultWrapping,
                                width: fixedColumn.width
                            )
                            combined.append(contentsOf: haligned)
                        }
                    }
                    rowHeight = Swift.max(rowHeight, combined.count)
                    formattedRow.append((col.first?.alignment, combined))
                }
                var valigned:[[String]] = []
                guard row.count == formattedRow.count else {
                    let msg = "internal inconsistency error"
                    dbg(.error, debugMask, msg)
                    fatalError(msg)
                }
                
                // Align vertically
                for (i,fr) in formattedRow.enumerated() {
                    let fc = fixedColumns[i]
                    guard fc.isVisible else {
                        continue
                    }
                    //dbg(.cache, debugMask, "column(\(i)), contentHint = \(fc.contentHint)")
                    //dbg(.cache, debugMask, "\(fr.1)")
                    //dbg(.cache, debugMask, "\(sourceRow)")
                    let verticallyAligned = fr.1.valign(fr.0 ?? fc.defaultAlignment, height: rowHeight)
                    valigned.append(verticallyAligned)
                    if let key = _key, let hash = _hash {
                        cache[key, default: [:]][hash] = verticallyAligned
                        cacheWrite += 1
                    }
                }
                // MARK: Individual row
                for fragment in valigned.transposed() {
                    out.write(l + fragment.joined(separator: insideVerticalSeparator) + r)
                }
                // MARK: Dividers between individual rows
                if hasData,
                   hasVisibleColumns,
                   ri < lastValidIndex,
                   options.contains(.insideHorizontalFrame) {
                    out.write(leftPad)
                    out.write(style.insideLeftVerticalSeparator(for: options))
                    out.write(
                        fixedColumns
                            .filter({ $0.isVisible })
                            .map({
                            String(repeating: style.insideHorizontalSeparator(for: options),
                                   count: $0.width)
                        }).joined(separator: style.insideHorizontalVerticalSeparator(for: options))
                    )
                    out.write(style.insideRightVerticalSeparator(for: options))
                    out.write("\(rightPad)\n")
                }
            }
            // MARK: Dividers between row ranges
            if hasData,
               hasVisibleColumns,
               rri < ranges.index(before: ranges.endIndex),
               options.contains(.insideHorizontalFrame) {
                out.write(leftPad)
                out.write(style.insideLeftVerticalSeparator(for: options))
                out.write(
                    fixedColumns
                        .map({
                            String(repeating: style.insideHorizontalRowRangeSeparator(for: options),
                                   count: $0.width)
                        }).joined(separator: style.insideHorizontalVerticalSeparator(for: options))
                )
                out.write(style.insideRightVerticalSeparator(for: options))
                out.write("\(rightPad)\n")
            }

        }
        
        // MARK: Bottom frame
        if options.contains(.bottomFrame) {
            out.write(leftPad)
            out.write(style.bottomLeftCorner(for: options))
            if hasVisibleColumns {
                out.write(
                    visibleColumns
                        .map({
                            String(repeating: style.bottomHorizontalSeparator(for: options),
                                   count: $0.width)
                        }).joined(separator: style.bottomHorizontalVerticalSeparator(for: options))
                )
            }
            else {
                out.write(
                    String(repeating: style.bottomHorizontalSeparator(for: options),
                           count: titleWidth)
                )
            }
            out.write(style.bottomRightCorner(for: options))
            out.write("\(rightPad)\n")
        }
        for (str,v) in cache {
            dbg(.cache, debugMask, "\(str)")
            for (hash,cell) in v {
                dbg(.cache, debugMask, "    \(hash) | \(cell)")
            }
        }
    }
    /// Render Array elements as table
    /// - Returns: A new String containing the rendered table.
    public func render(title:Txt? = nil,
                       columns:[Col]? = nil,
                       style:FrameStyle = .default,
                       options:FramingOptions = .all,
                       rows rnges:[Range<Int>]? = nil,
                       leftPad:String = "",
                       rightPad:String = "",
                       debugMask:DebugTopicSet = [],
                       lineNumberGenerator:((Int)->Txt)? = nil,
                       lineNumberColumn:Col? = nil) -> String {
        var str = ""
        render(title: title, columns: columns, style: style,
             options: options, rows: rnges, leftPad: leftPad,
             rightPad: rightPad, to: &str, debugMask: debugMask,
             lineNumberGenerator: lineNumberGenerator)
        return str
    }
}
fileprivate func preFormat(title:Txt?,
                           columns cols:[Col],
                           cells:[[Txt]],
                           ranges:[Range<Int>]?,
                           debugMask:DebugTopicSet = [],
                           lnGen:((Int)->Txt)? = nil) -> ([[[[Txt]]]], [FixedCol]) {
        
    var prefmttedRange:[[[[Txt]]]] = []
    var rowElementCountHistogram:[Int:Int] = [:]
    var dict:[Int:Col] = Dictionary<Int,Col>(uniqueKeysWithValues: cols.enumerated().map({ $0 }))
    var columnFixedWidth:[Int:Int] = [:]
    let defCol = Col(width: .auto, defaultAlignment: .topLeft, defaultWrapping: .char, trimming: [])
    var minRowElementCount:Int = Int.max - 1
    var maxRowElementCount:Int = Int.min + 1

    guard cells.isEmpty == false else {
        dbg(.cells, debugMask, "Table has no data cells")
        guard cols.isEmpty == false else {
            let c = Col(
                title ?? Txt(),
                width: .fixed(title?.count ?? 0),
                defaultAlignment: title?.alignment ?? .middleCenter,
                defaultWrapping: title?.wrapping ?? .char,
                contentHint: .unique
            )
            return ([], [FixedCol(c, width: title?.count ?? 0, ref: 0, hidden: true)])
        }
        let hcols = cols
            .filter({ $0.dynamicWidth != .hidden })
            .map({
                let (h,hw) = { header,dw in
                    switch dw {
                    case .hidden, .collapsed: return ("", 0)
                    case .min(let w): return (header?.string ?? "", w)
                    case .max(let w): return (header?.string ?? "", w)
                    case .fixed(let w): return (header?.string ?? "", w)
                    case .range(let r):
                        let hdr = header?.string ?? ""
                        return (hdr, Swift.min(Swift.max(hdr.count, r.lowerBound), r.upperBound - 1))
                    case .in(let r):
                        let hdr = header?.string ?? ""
                        return (hdr, Swift.min(Swift.max(hdr.count, r.lowerBound), r.upperBound))
                    case .auto:
                        let hdr = header?.string ?? ""
                        return (hdr, hdr.count)
                    }
                }($0.header, $0.dynamicWidth)
                let c = Col(
                    h,
                    width: $0.dynamicWidth,
                    defaultAlignment: $0.header?.alignment ?? $0.defaultAlignment,
                    defaultWrapping: $0.header?.wrapping ?? $0.defaultWrapping,
                    contentHint: $0.contentHint
                )
                return FixedCol(c, width: hw, ref: 0, hidden: false)
            })
        return ([], hcols)
    }

    for (rri,range) in zip(0..., ranges ?? [0..<cells.count]) {

        var prefmtted:[[[Txt]]] = []

        guard range.isEmpty == false else {
            dbg(.info, debugMask, "EMPTY RANGE \(range) at range index \(rri)")
            prefmttedRange.append([[[]]])
            for (ci,ccc) in cols.enumerated() {
                columnFixedWidth[ci] = ccc.header?.count ?? 0
            }
            continue
        }

        for (ri, partialRow) in cells[range].enumerated() {
            //dbg(.debug, debugMask, prefix: pfx, "ROW \(ri): \(partialRow)")
            minRowElementCount = Swift.min(minRowElementCount, partialRow.count) + (lnGen == nil ? 0 : 1)
            maxRowElementCount = Swift.max(maxRowElementCount, partialRow.count) + (lnGen == nil ? 0 : 1)
            rowElementCountHistogram[partialRow.count, default: 0] += 1
            
            var row:[Txt]
            if let lnGen = lnGen {
                row = [lnGen(range.lowerBound + ri)] + partialRow
            }
            else {
                row = partialRow
            }
            if dict.count < maxRowElementCount {
                // We have more data cells on the row than
                // what we have defined Cols.
                // => Add missing Cols with default settings
                (dict.count..<maxRowElementCount)
                    .forEach {
                        dbg(.columns, debugMask, "Adding missing column")
                        dict[$0] = defCol
                    }
            }
            if row.count < cols.count {
                // This row doesn't have enough cells
                // Let's add required amount of empty cells
                let missing:[Txt] = Array<Txt>(repeating: Txt(), count: Swift.max(0, cols.count - row.count))
                row.append(contentsOf: missing)
                dbg(.cells, debugMask, "row(\(ri + range.lowerBound)): adding \(missing.count) cell(s)")
            }
            
            var fmrow:[[Txt]] = []
            for (ci,unformattedcell) in zip(0..., row) {
                
                guard [Width.hidden, .collapsed].contains(dict[ci]!.dynamicWidth) == false else {
                    columnFixedWidth[ci] = 0
                    fmrow.append([""]) // collapsed or hidden -> we don't need cell data, overwrite with ""
                    //dbg(.debug, debugMask, prefix: pfx, "  R\(ri)C\(ci) \(dict[ci]!.dynamicWidth): → skip")
                    continue
                }
                var lo:Int = {
                    switch dict[ci]!.dynamicWidth {
                    case .min(let v): return v
                    case .range(let r): return r.lowerBound
                    case .in(let r): return r.lowerBound
                    default: return 0
                    }
                }()
                var hi = 0

                // Here we pre-format the row
                // In practice, pre-formatting means just trimming
                // and fragmenting (at newlines)
                let trimmedAndFragmented:[Txt] = unformattedcell.string
                    .trimAndFrag(dict[ci]!.trimming)
                    .map { str in
                        // Update lo & hi values on the same loop as we
                        // map Strings back to Txt
                        lo = Swift.min(lo, str.count)
                        hi = Swift.max(hi, str.count)
                        return Txt(str,
                                   alignment: unformattedcell.alignment,
                                   wrapping: unformattedcell.wrapping)
                    }
                fmrow.append(trimmedAndFragmented)

                // Update the fixed width value for the column
                switch dict[ci]!.dynamicWidth {
                case .min(let min):
                    columnFixedWidth[ci] = Swift
                        .max(columnFixedWidth[ci, default: 0],
                             Swift.max(min, hi))
                case .max(let max):
                    columnFixedWidth[ci] = Swift
                        .max(columnFixedWidth[ci, default: 0],
                             Swift.min(max, hi))
                case .in(let closedRange):
                    columnFixedWidth[ci] = Swift
                        .max(columnFixedWidth[ci, default: 0],
                             Swift.max(Swift.min(closedRange.upperBound, hi), closedRange.lowerBound))
                case .range( let range):
                    columnFixedWidth[ci] = Swift
                        .max(columnFixedWidth[ci, default: 0],
                             Swift.max(Swift.min(range.upperBound - 1, hi), range.lowerBound))
                case .auto:
                    columnFixedWidth[ci] = Swift
                        .max(columnFixedWidth[ci, default: 0],
                             Swift.max(0, hi))
                case .fixed(let v):
                    columnFixedWidth[ci] = v
                case .collapsed:
                    columnFixedWidth[ci] = 0
                case .hidden:
                    continue
                }
            }
            prefmtted.append(fmrow) // ← Add preformatted row
        }
        prefmttedRange.append(prefmtted)
    }

    // Generate FixedCol's from calculated column widths
    let fixedColumns:[FixedCol] = columnFixedWidth
        .sorted(by: { $0.key < $1.key })
        .map({
            FixedCol(
                dict[$0.key]!,
                width: $0.value,
                ref: $0.key,
                hidden: dict[$0.key]!.dynamicWidth == .hidden
            )
        })

    return (prefmttedRange, fixedColumns)
}
