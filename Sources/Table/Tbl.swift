public struct Tbl {
    public let data:[[Txt]]
    public let columns:[Col]
    public let title:Txt?
    public let frameStyle:FrameElements
    public let frameRenderingOptions:FrameRenderingOptions
    private var actualColumns:[Col] = []
    public init(_ title:Txt? = nil, columns: [Col] = [], data:[[Txt]],
                frameStyle:FrameElements = .default,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        if columns.isEmpty {
            // Let's treat empty column set as "automatic columns"
            let maxColCount = data.reduce(0, { Swift.max($0, $1.count) })
            if maxColCount == 0 {
                // Actually, there is no data either, let's fake one
                self.columns = [Col(width: .auto, alignment: .topLeft)]
            }
            else {
                self.columns = Array(repeating: Col(width: .auto, alignment: .topLeft), count: maxColCount)
            }
        }
        else {
            // Silently cut-off the excess columns as
            // Tbl supports only UInt16.max columns.
            self.columns = Array(columns.prefix(Int(UInt16.max)))
        }
        self.data = data
        self.title = title
        self.frameStyle = frameStyle
        self.frameRenderingOptions = frameRenderingOptions

        // Calculate column widths for autowidth columns
        self.actualColumns = calculateAutowidths()

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
            for i in recalc {
                for r in data {
                    guard r.count > i else { continue }
                    let m = Swift.max(tmp[i].width.rawValue, r[i].count)
                    tmp[i].width = .value(m)
                }
                if tmp[i].width == .auto {
                    if let hdr = columns[i].header {
                        let smrt = Swift.min(hdr.count, columns.reduce(0, { $0 + ($1.header?.count ?? 0) }) / columns.count)
                        tmp[i].width = .value(Swift.max(1, smrt))
                    }
                    else {
                        tmp[i].width = 0
                    }
                }
            }
            return tmp
        }
    }
    public init(_ title:String, columns: [Col], data:[[Txt]],
                frameStyle:FrameElements = .default,
                frameRenderingOptions:FrameRenderingOptions = .all) {
        self.init(Txt(title, alignment: .middleCenter), columns: columns, data: data,
                  frameStyle: frameStyle, frameRenderingOptions: frameRenderingOptions)
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
    private var hasHeaderLabels:Bool {
        !columns.allSatisfy({ $0.header == nil })
    }
    private var titleColumnWidth:Int {
        let w = Swift.max(0, actualColumns
            .reduce(0, { $0 + $1.width.rawValue }) +
            ((actualColumns.count - 1) *
                frameStyle.insideVerticalSeparator.element(for: frameRenderingOptions).count))
        if w == 0 {
            return title?.count ?? 0
        }
        else {
            return w
        }
    }
    public func render(into: inout String, leftPad:String = "", rightPad:String = "") {
        let lPad = leftPad
            .filter({ $0.isNewline == false })
        let rPad = rightPad
            .filter({ $0.isNewline == false })


        // Top frame
        if frameRenderingOptions.contains(.topFrame) {
            if title != nil {
                into.append(lPad)
                into.append(frameStyle.topLeftCorner.element(for: frameRenderingOptions))
                into.append(
                    String(repeating: frameStyle.topHorizontalSeparator.element(for: frameRenderingOptions),
                           count: titleColumnWidth)
                )
                into.append(frameStyle.topRightCorner.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
            else if hasHeaderLabels || data.count > 0 {
                into.append(lPad)
                into.append(frameStyle.topLeftCorner.element(for: frameRenderingOptions))
                into.append(
                    actualColumns.map({
                        String(repeating: frameStyle.topHorizontalSeparator.element(for: frameRenderingOptions),
                               count: $0.width.rawValue)
                    }).joined(separator: frameStyle.topHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                )
                into.append(frameStyle.topRightCorner.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
            else {
                into.append(lPad)
                into.append(frameStyle.topLeftCorner.element(for: frameRenderingOptions))
                into.append(
                    String(repeating: frameStyle.topHorizontalSeparator.element(for: frameRenderingOptions),
                           count: titleColumnWidth)
                )
                into.append(frameStyle.topRightCorner.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
        }


        // Title
        if let title = title {
            let alignedTitle = title
                .fragment(fallback: .middleCenter, width: titleColumnWidth, wrapping: .word)
                .verticallyAligned

            for f in alignedTitle {
                into.append(
                    lPad +
                        frameStyle.leftVerticalSeparator.element(for: frameRenderingOptions) +
                        f.joined(separator: frameStyle.insideVerticalSeparator.element(for: frameRenderingOptions)) +
                        frameStyle.rightVerticalSeparator.element(for: frameRenderingOptions) +
                        "\(rPad)\n")
            }
        }


        // Title & column header divider
        if title != nil, hasHeaderLabels, frameRenderingOptions.contains(.insideHorizontalFrame) {
            into.append(lPad)
            into.append(frameStyle.insideLeftVerticalSeparator.element(for: frameRenderingOptions))
            into.append(
                actualColumns.map({
                    String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                           count: $0.width.rawValue)
                }).joined(separator: frameStyle.topHorizontalVerticalSeparator.element(for: frameRenderingOptions))
            )
            into.append(frameStyle.insideRightVerticalSeparator.element(for: frameRenderingOptions))
            into.append("\(rPad)\n")
        }


        // Column headers
        if hasHeaderLabels {

            let alignedColumnHeaders = actualColumns
                .compactMap({ column in
                    return (column.header ?? Txt("")).fragment(for: column)
                })
                .dropFirst(0) // <= Convert Array to ArraySlice
                .alignVertically
            for f in alignedColumnHeaders {
                into.append(
                    lPad +
                        frameStyle.leftVerticalSeparator.element(for: frameRenderingOptions) +
                        f.joined(separator: frameStyle.insideVerticalSeparator.element(for: frameRenderingOptions)) +
                        frameStyle.rightVerticalSeparator.element(for: frameRenderingOptions) +
                        "\(rPad)\n")
            }
        }


        // Divider, before data
        if frameRenderingOptions.contains(.insideHorizontalFrame), data.count > 0 {
            if hasHeaderLabels { // --+--
                into.append(lPad)
                into.append(frameStyle.insideLeftVerticalSeparator.element(for: frameRenderingOptions))
                into.append(
                    actualColumns.map({
                        String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                               count: $0.width.rawValue)
                    }).joined(separator: frameStyle.insideHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                )
                into.append(frameStyle.insideRightVerticalSeparator.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
            else if title != nil { // --v--
                into.append(lPad)
                into.append(frameStyle.insideLeftVerticalSeparator.element(for: frameRenderingOptions))
                into.append(
                    actualColumns.map({
                        String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                               count: $0.width.rawValue)
                    }).joined(separator: frameStyle.topHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                )
                into.append(frameStyle.insideRightVerticalSeparator.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
        }

        // Data rows
        var cache:[UInt32:[Int:HorizontallyAligned]] = [:]
        var cacheHits:Int = 0
        var cacheMisses:Int = 0
        // Assign elements before entering "busy" loop,
        // so that they are not evaluated each iteration
        let leftVerticalSeparator = frameStyle.leftVerticalSeparator.element(for: frameRenderingOptions)
        let rightVerticalSeparator = frameStyle.rightVerticalSeparator.element(for: frameRenderingOptions)
        let insideVerticalSeparator = frameStyle.insideVerticalSeparator.element(for: frameRenderingOptions)
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
            for columnData in columnized.prefix(actualColumns.count).alignVertically {
                into.append(lPad)
                into.append(leftVerticalSeparator)
                into.append(columnData.joined(separator: insideVerticalSeparator))
                into.append(rightVerticalSeparator)
                into.append("\(rPad)\n")
            }
            if i != data.index(before: data.endIndex), frameRenderingOptions.contains(.insideHorizontalFrame) {
                //into.append("ins" + insideDivider)
                into.append(lPad)
                into.append(frameStyle.insideLeftVerticalSeparator.element(for: frameRenderingOptions))
                into.append(
                    actualColumns.map({
                        String(repeating: frameStyle.insideHorizontalSeparator.element(for: frameRenderingOptions),
                               count: $0.width.rawValue)
                    }).joined(separator: frameStyle.insideHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                )
                into.append(frameStyle.insideRightVerticalSeparator.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
        }


        // Bottom frame
        if frameRenderingOptions.contains(.bottomFrame) {
            if data.count > 0 || hasHeaderLabels {
                into.append(lPad)
                into.append(frameStyle.bottomLeftCorner.element(for: frameRenderingOptions))
                into.append(
                    actualColumns.map({
                        String(repeating: frameStyle.bottomHorizontalSeparator.element(for: frameRenderingOptions),
                               count: $0.width.rawValue)
                    }).joined(separator: frameStyle.bottomHorizontalVerticalSeparator.element(for: frameRenderingOptions))
                )
                into.append(frameStyle.bottomRightCorner.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
            else {
                into.append(lPad)
                into.append(frameStyle.bottomLeftCorner.element(for: frameRenderingOptions))
                into.append(
                    String(repeating: frameStyle.bottomHorizontalSeparator.element(for: frameRenderingOptions),
                           count: titleColumnWidth)
                )
                into.append(frameStyle.bottomRightCorner.element(for: frameRenderingOptions))
                into.append("\(rPad)\n")
            }
        }
    }
    public func render(leftPad:String = "", rightPad:String = "") -> String {
        var result = ""
        render(into: &result, leftPad: leftPad, rightPad: rightPad)
        return result
    }
}
