
import Foundation
import DebugKit

extension Array where Element == [Txt] {
    private func titleCellWidth(style:FrameStyle,
                                options:FramingOptions,
                                visibleColumns:[FixedCol]) -> Int? {
        // Do we have any visible columns?
        guard visibleColumns.isEmpty == false else {
            dbg(.debug, prefix: "titleCellWidth", "no visible columns, return nil")
            return nil
        }
        let ivsLen = style.insideVerticalSeparator(for: options).count
        if visibleColumns.allSatisfy({ $0.dynamicWidth == .collapsed }) ||
            visibleColumns.allSatisfy({ $0.width == 0 }) {
            return /*0*/Swift.max(0, visibleColumns.count - 1) * ivsLen
        }
        let w:Int = visibleColumns
            .reduce(0, { $0 + $1.width }) + ((Swift.max(0, visibleColumns.count - 1)) * ivsLen)
        let ret:Int? = w < 1 ? nil : w
        return ret
    }
    public func renx(title:Txt? = nil,
                     columns:[Col]? = nil,
                     style:FrameStyle = .default,
                     options:FramingOptions = .all,
                     rows:[Range<Int>]? = nil,
                     leftPad:String = "",
                     rightPad:String = "",
                     to out: inout String,
                     debugMask:DebugTopicSet = [],
                     lineNumberGenerator:((Int)->Txt)? = nil) {

        dbg(.debug, debugMask, "Validating ranges \(rows)")
        if let ranges = rows {
            ranges.forEach {
                guard $0.lowerBound >= 0, $0.upperBound <= count else {
                    fatalError("Range \($0) out of bounds")
                }
            }
        }

        let rnges = rows
        
        // Pre-format cells and get fixed width columns
        let t0 = DispatchTime.now().uptimeNanoseconds
        let (preFormattedRowRanges, fixedColumns) = preFormatx(
            title: title,
            columns: columns ?? [],
            cells: self,
            ranges: rnges,
            debugMask: debugMask,
            lnGen: lineNumberGenerator)
        let t1 = DispatchTime.now().uptimeNanoseconds
        let ms = Double(t1 - t0) / 1_000_000
        if debugMask.contains(.debug) {
            fixedColumns.forEach({
                dbg(.debug, prefix:"FixedColumn", "\($0)")
            })
        }
        dbg(.telemetry, debugMask, prefix: "\(type(of: self))", "pre-formatting took \(ms) ms")

        let hasTitle = title != nil
        let visibleColumns = fixedColumns.filter({ $0.isVisible })
        let hasVisibleColumns = visibleColumns.isEmpty == false
        dbg(.info, debugMask, prefix: "visibleColumns", "visible column count \(visibleColumns.count) hasVisibleColumns = \(hasVisibleColumns)")
        let hasData = isEmpty == false //&& maxRowElementCount > 0
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

        dbg(.debug, debugMask, "titleWidth = \(titleWidth)")
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
            dbg(.info, debugMask, prefix: "title", "w=\(titleWidth) \(splitted.description) -> \(titleFragments)")

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
            dbg(.info, debugMask, prefix: "visibleColumns", "alignedColumnHeaders: \(alignedColumnHeaders)")
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
            dbg(.debug, debugMask, "Row range (\(rri)): \(rowRange) \(lastValidIndex)")
            guard hasData else {
                dbg(.debug, debugMask, "No data, skip rest.")
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
                    dbg(.debug, debugMask, "appending (\(i)) \(txt.string, visibleWhitespaces: true, quoted: true)")
                        if rowRange.isEmpty {
                            row.append([])
                        }
                        else {
                            row.append([txt])
                        }
                    }
                }
                dbg(.debug, debugMask, "row is now \(row)")

                guard row.count == fixedColumns.count else {
                    fatalError("internal inconsistency error")
                }
                // Process the single row column by column
                for (ci,col) in row.enumerated() {
                    let fixedColumn = fixedColumns[ci]
                    guard fixedColumn.isVisible else {
                        formattedRow.append((nil, []))
                        dbg(.debug, debugMask, "skip")
                        continue
                    }
                    
                    dbg(.cache, debugMask, "column hash (\(fixedColumn.hashValue))")
                    dbg(.cache, debugMask, "search (\(ri),\(ci)) \(col)")

                    var combined:[String] = []
                    if fixedColumn.width == 0 {
                        combined.append("")
                    }
                    else {
                        for (/*fi*/_,fragment) in col.enumerated() {
                            let haligned = fragment.halign(
                                defaultAlignment: fixedColumn.defaultAlignment,
                                defaultWrapping: fixedColumn.defaultWrapping,
                                width: fixedColumn.width
                            )
                            dbg(.debug, debugMask,
                                "halign \(fragment.string, visibleWhitespaces: true, quoted: true)->\(haligned)")
                            combined.append(contentsOf: haligned)
                        }
                    }
                    rowHeight = Swift.max(rowHeight, combined.count)
                    formattedRow.append((col.first?.alignment, combined))
                }
                var valigned:[[String]] = []
                guard row.count == formattedRow.count else {
                    fatalError("internal inconsistency error")
                }
                
                // Align vertically
                for (i,fr) in formattedRow.enumerated() {
                    let fc = fixedColumns[i]
                    guard fc.isVisible else {
                        continue
                    }
                    valigned.append(fr.1.valign(fr.0 ?? fc.defaultAlignment, height: rowHeight))
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
                if hasData {
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
                        visibleColumns
                            .map({
                                String(repeating: style.bottomHorizontalSeparator(for: options),
                                       count: $0.width)
                            }).joined(separator: style.bottomHorizontalVerticalSeparator(for: options))
                    )
                }
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
    }
    public func renx(title:Txt? = nil,
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
        renx(title: title, columns: columns, style: style,
             options: options, rows: rnges, leftPad: leftPad,
             rightPad: rightPad, to: &str, debugMask: debugMask,
             lineNumberGenerator: lineNumberGenerator)
        return str
    }    
}
fileprivate func preFormatx(title:Txt?,
                            columns cols:[Col],
                            cells:[[Txt]],
                            ranges:[Range<Int>]?,
                            debugMask:DebugTopicSet = [],
                            lnGen:((Int)->Txt)? = nil) -> ([[[[Txt]]]], [FixedCol]) {
        
    let pfx = "preFormatx"
    if debugMask.contains(.debug) {
        cols.enumerated().forEach({
            let a = "\($0.element.defaultAlignment, aligned: Alignment.self)"
            let w = "\($0.element.defaultWrapping, aligned: Wrapping.self)"
            let l = "\($0.element.dynamicWidth, aligned: Width.self)"
            dbg(.debug, prefix: pfx, "\($0.offset): \(a), \(w), \(l), header = \($0.element.header)")
        })
        dbg(.debug, prefix: pfx, "rows (cell data) \(cells.isEmpty ? "no data" : "\(cells.count) rows")")
        cells.forEach({ dbg(.debug, prefix: pfx, "  \($0.map({ $0.string }))") })
    }


    var prefmttedRange:[[[[Txt]]]] = []
    var rowElementCountHistogram:[Int:Int] = [:]
    var dict:[Int:Col] = Dictionary<Int,Col>(uniqueKeysWithValues: cols.enumerated().map({ $0 }))
    var columnFixedWidth:[Int:Int] = [:]
    let defCol = Col(width: .auto, defaultAlignment: .topLeft, defaultWrapping: .char, trimming: [])
    var minRowElementCount:Int = Int.max
    var maxRowElementCount:Int = Int.min

    guard cells.isEmpty == false else {
        dbg(.debug, debugMask, "Table has no data cells \(cols)")
        guard cols.isEmpty == false else {
            dbg(.debug, debugMask, "Table has no columns (and no data either). Use title width.")
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
                return FixedCol(c, width: /*fixed ?? h.count*/hw, ref: 0, hidden: false)
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
            dbg(.debug, debugMask, prefix: pfx, "ROW \(ri): \(partialRow)")
            minRowElementCount = Swift.min(minRowElementCount, partialRow.count)
            maxRowElementCount = Swift.max(maxRowElementCount, partialRow.count)
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
                        dbg(.debug, debugMask, "Adding missing column")
                        dict[$0] = defCol
                    }
            }
            if row.count < cols.count {
                let missing:[Txt] = Array<Txt>(repeating: Txt(), count: Swift.max(0, cols.count - row.count))
                row.append(contentsOf: missing)
                dbg(.debug, debugMask, "Adding \(missing.count) cells -> \(row)")
            }
            
            var fmrow:[[Txt]] = []
            for (ci,unformattedcell) in zip(0..., row) {
                if dict[ci] == nil {
                    dict[ci] = defCol
                }
                
                guard [Width.hidden, .collapsed].contains(dict[ci]!.dynamicWidth) == false else {
                    columnFixedWidth[ci] = 0
                    fmrow.append([""]) // collapsed or hidden -> we don't need cell data, overwrite with ""
                    dbg(.debug, debugMask, prefix: pfx, "  R\(ri)C\(ci) \(dict[ci]!.dynamicWidth): → skip")
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

                let trimmedAndFragmented:[Txt] = unformattedcell.string
                    .trimAndFrag(dict[ci]!.trimming)
                    .map { str in
                        lo = Swift.min(lo, str.count)
                        hi = Swift.max(hi, str.count)
                        return Txt(str,
                                   alignment: unformattedcell.alignment,
                                   wrapping: unformattedcell.wrapping)
                    }
                if debugMask.contains(.debug) {
                    dbg(.debug, debugMask, prefix: pfx,
                        "IN  : \(unformattedcell.string, visibleWhitespaces: true, quoted: true)")
                    dbg(.debug, debugMask, prefix: pfx,
                        "TRIM: \(dict[ci]!.trimming)")
                    dbg(.debug, debugMask, prefix: pfx,
                        "OUT : \(trimmedAndFragmented)")
                }
                fmrow.append(trimmedAndFragmented)


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
            columnFixedWidth.sorted(by: { $0.key < $1.key }).enumerated().forEach({
                dbg(.debug, debugMask, prefix: pfx, "    C\($0.offset)\($0.element)")
            })
            prefmtted.append(fmrow)
        }
        prefmttedRange.append(prefmtted)
    }

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

    dbg(.debug, debugMask, "preformatted: \(prefmttedRange)")
    dbg(.debug, debugMask, "preformatted: \(fixedColumns.map({ $0.dynamicWidth}))")
    return (prefmttedRange, fixedColumns)
}
