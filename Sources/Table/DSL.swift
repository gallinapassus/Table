import Foundation

public final class Columns {
    fileprivate var data:[Col]
    public init(@ColumnBuilder _ builder: () -> [Col]) {
        self.data = builder()
    }
}
public final class Rows {
    fileprivate var rows:[[Txt]]
    public init(@RowsBuilder _ builder: () -> [[Txt]]) {
        self.rows = builder()
    }
}
public final class Row {
    fileprivate var rowCells:[Txt]
    public init(_ cells: Txt...) {
        self.rowCells = cells
    }
}
@resultBuilder
public enum ColumnBuilder {
    public static func buildBlock(_ components: Col...) -> [Col] {
        components
    }
    public static func buildBlock(_ components: String...) -> [Col] {
        components.map({ Col($0) })
    }
}
@resultBuilder
public enum RowsBuilder {

    // Rows {
    //     [
    //         [Txt("1"), Txt("1988"), Txt("Mondeo")],
    //         [Txt("2"), Txt("1989"), Txt("Fiesta")]
    //     ]
    // }
    public static func buildBlock(_ components: [[Txt]]) -> [[Txt]] {
        components
    }
    
    
    // Rows {
    //     Row(Txt("#"), Txt("€"))
    //     Row(Txt("#"), Txt("€"), Txt("?"))
    // }
    public static func buildBlock(_ row: Row...) -> [[Txt]] {
        row.map({ $0.rowCells })
    }
    
    
    // Rows {
    //     ["1.", "1943", "A"]
    //     ["2.", "1934", "T"]
    //     ["3.", "", "D"]
    // }
    public static func buildBlock(_ row: [String]...) -> [[Txt]] {
        row.map({ $0.map({ Txt($0) }) })
    }
}
@resultBuilder
public enum RowCellBuilder {
    public static func buildBlock(_ components: Txt...) -> [Txt] {
        components
    }
}
@resultBuilder
public enum TblBuilder {
    public static func buildBlock(_ frameStyle: FrameElements,
                                  _ frameRenderingOptions: FrameRenderingOptions,
                                  _ columnDefinitions: Columns,
                                  _ data: Rows) -> (FrameElements, FrameRenderingOptions, [Col], [[Txt]]) {
        (frameStyle, frameRenderingOptions, columnDefinitions.data, data.rows)
    }
    public static func buildBlock(_ frameRenderingOptions: FrameRenderingOptions,
                                  _ columnDefinitions: Columns,
                                  _ data: Rows) -> (FrameElements, FrameRenderingOptions, [Col], [[Txt]]) {
        (.default, frameRenderingOptions, columnDefinitions.data, data.rows)
    }
    public static func buildBlock(_ frameStyle: FrameElements,
                                  _ columnDefinitions: Columns,
                                  _ data: Rows) -> (FrameElements, FrameRenderingOptions, [Col], [[Txt]]) {
        (frameStyle, .all, columnDefinitions.data, data.rows)
    }
    public static func buildBlock(_ columnDefinitions: Columns,
                                  _ data: Rows) -> (FrameElements, FrameRenderingOptions, [Col], [[Txt]]) {
        (.default, .all, columnDefinitions.data, data.rows)
    }
    public static func buildBlock(_ data: Rows) -> (FrameElements, FrameRenderingOptions, [Col], [[Txt]]) {
        (.default, .all, [], data.rows)
    }
    public static func buildBlock(_ frameStyle: FrameElements,
                                  _ frameRenderingOptions: FrameRenderingOptions,
                                  _ data: Rows) -> (FrameElements, FrameRenderingOptions, [Col], [[Txt]]) {
        (frameStyle, frameRenderingOptions, [], data.rows)
    }
    public static func buildBlock(_ frameStyle: FrameElements,
                                  _ data: Rows) -> (FrameElements, FrameRenderingOptions, [Col], [[Txt]]) {
        (frameStyle, .all, [], data.rows)
    }
    public static func buildBlock(_ frameRenderingOptions: FrameRenderingOptions,
                                  _ data: Rows) -> (FrameElements, FrameRenderingOptions, [Col], [[Txt]]) {
        (.default, frameRenderingOptions, [], data.rows)
    }
}
