import XCTest
@testable import Table

final class TableTests: XCTestCase {
    func testExample() {
        var data:[[Txt]] = []
        for i in 0..<5 {
            var cols:[Txt] = []
            for j in 0..<8 {
                let a:Alignment?
                if Bool.random() {
                    a = Alignment.allCases.randomElement()!
                }
                else {
                    a = nil
                }
                cols.append(Txt("row\(i+1) column\(j+1) alignment = \(a as Any)", a))
            }
            data.append(cols)
        }
        let cols = [
            Col(header: Txt("Column 1", .topLeft),      width: 3,  alignment: .topLeft),
            Col(header: Txt("Column 2", .topCenter),    width: 5,  alignment: .topRight),
            Col(header: Txt("Column 3", .bottomCenter), width: 4,  alignment: .topCenter),
            Col(header: Txt("Column 4", .bottomCenter), width: 8,  alignment: .topCenter),
            Col(header: Txt("Column 5", .bottomCenter), width: 12, alignment: .topCenter),
            Col(header: Txt("Column 6", .bottomCenter), width: 7,  alignment: .topCenter),
            Col(header: Txt("", .bottomCenter), width: 10, alignment: .topCenter),
            Col(header: Txt("Column 8", .bottomCenter), width: 0,  alignment: .topCenter),
        ]
        let table = Tbl(Txt("Table Title"), columns: cols, data: data)
        var str:String = ""
        table.render(into: &str)
        print(str)
    }
}
