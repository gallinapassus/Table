import XCTest
//@testable import Table
import Table

final class TableTests: XCTestCase {
    func testExample() {
        var data:[[Txt]] = []
        for i in 0..<50 {
            var cols:[Txt] = []
            let cmax = [1,2,3,4,5,6,7,8,9,10,11].randomElement()!
            for j in 0..<cmax {
                let a:Alignment?
                if Bool.random() {
                    a = Alignment.allCases.randomElement()!
                }
                else {
                    a = nil
                }
                let astr = a == nil ? "nil" : "\(a!)"
                cols.append(Txt("row\(i+1) column\(j+1) alignment \(astr)", a))
            }
            data.append(cols)
        }
        let cols = [
        //    Col(header: nil, width: 5, alignment: .topRight),
        //    Col(header: nil, width: 6, alignment: .topRight),
        //    Col(header: nil, width: 15, alignment: .topRight),
            Col(header: Txt("Column 1", .topLeft),      width: 4,  alignment: .topLeft),
            Col(header: Txt("Column 2", .topCenter),    width: 5,  alignment: .topRight),
            Col(header: Txt("Column 3", .bottomCenter), width: 4,  alignment: .topCenter),
            Col(header: Txt("Column 4", .bottomCenter), width: 8,  alignment: .topCenter),
            Col(header: Txt("Column 5", .bottomCenter), width: 12,  alignment: .topCenter),
            Col(header: Txt("Col6",     .middleCenter), width: 8,  alignment: .topCenter),
            Col(header: Txt("",         .bottomCenter), width: 6, alignment: .topCenter),
            Col(header: Txt("Column 8", .bottomCenter), width: 0,  alignment: .topLeft),
        ]
        //let table = Tbl("On narrow table this title wraps on multiple lines?", columns: cols, data: data)
        let table = Tbl(Txt("On narrow table this title wraps on multiple lines?", .middleCenter), columns: cols, data: data)
        //let table = Tbl(nil, data, cols)
        var t:String = ""
        table.render(into: &t)
        print(t)
    }
    func testPerformance() {
        var data:[[Txt]] = []
        let rnd = ["by itself", "as part of the sentence"]
        let sentences = [
            ["A blessing in disguise", rnd.randomElement()!],
            ["A dime a dozen", rnd.randomElement()!],
            ["Beat around the bush", rnd.randomElement()!],
            ["Better late than never", rnd.randomElement()!],
            ["Bite the bullet", rnd.randomElement()!],
            ["Break a leg", rnd.randomElement()!],
            ["Call it a day", rnd.randomElement()!],
            ["Cut somebody some slack", rnd.randomElement()!],
            ["Cutting corners", rnd.randomElement()!],
            ["Easy does it", rnd.randomElement()!],
            ["Get out of hand", rnd.randomElement()!],
            ["Get something out of your system", rnd.randomElement()!],
            ["Get your act together", rnd.randomElement()!],
            ["Give someone the benefit of the doubt", rnd.randomElement()!],
            ["Go back to the drawing board", rnd.randomElement()!],
            ["Hang in there", rnd.randomElement()!],
            ["Hit the sack", rnd.randomElement()!],
        ]

        for _ in 0..<50000 {
            let cols:[Txt] = sentences.randomElement()!.map { Txt($0, Alignment.allCases.randomElement()!) }
            data.append(cols)
        }
        let cols = [
            Col(header: nil, width: 8, alignment: .topLeft, contentHint: .unique),
            Col(header: nil, width: 6, alignment: .topCenter, contentHint: .repetitive),
        ]
        // Release version times:
        // average: 0.788 -> print(..., to: &into)
        // average: 0.668 -> into.append()
        // average: 0.639 -> transposed() tweak
        // average: 0.415 -> .char wrapping as default
        measure {
            let table = Tbl("Title", columns: cols, data: data)
            var t = ""
            table.render(into: &t)
        }
    }
    func test_x() {

        do {
            let data:[[Txt]] = [
                ["123", Txt("You can't make an omelet without breaking some eggs", .topLeft, .cut), Txt("x", .topCenter), Txt("x", .topRight)],
                ["123", Txt("x", .middleLeft), Txt("x", .middleCenter), Txt("x", .middleRight)],
                ["123", Txt("x", .bottomLeft), Txt("x", .bottomCenter), Txt("x", .bottomRight)],
            ]
            let width:Width = 10

            let cols = [
                Col(header: nil,
                    width: 1, alignment: .topLeft, wrapping: .word),
                Col(header: Txt("Column default alignment .bottomCenter, wrapping .word", .bottomCenter),
                    width: 6, alignment: .topLeft, wrapping: .cut),
                Col(header: Txt("Column default alignment .topLeft, wrapping .word", .bottomCenter),
                    width: width, alignment: .topLeft, wrapping: .word),
                Col(header: Txt("Column default alignment .topLeft, wrapping .word", .bottomCenter),
                    width: width, alignment: .topLeft, wrapping: .word),
            ]
            let table = Tbl(Txt("Table title, alignment .middleLeft, frame style .rounded, frame rendering options .all", .middleLeft),
                            columns: cols, data: data, frameStyle: .default, frameRenderingOptions: .all)
            var t = ""
            table.render(into: &t)
            print(t)
        }
        do {
            let data:[[Txt]] = [
                ["123", Txt("You can't make an omelet without breaking some eggs", .topLeft, .cut), Txt("x", .topCenter), Txt("x", .topRight)],
                ["123", Txt("x", .middleLeft), Txt("x", .middleCenter), Txt("x", .middleRight)],
                ["123", Txt("x", .bottomLeft), Txt("x", .bottomCenter), Txt("x", .bottomRight)],
            ]
            let width:Width = 10

            let cols = [
                Col(header: nil,
                    width: 0, alignment: .topLeft, wrapping: .word),
                Col(header: Txt("Column default alignment .topLeft, wrapping .word", .bottomCenter),
                    width: 12, alignment: .topLeft, wrapping: .cut),
                Col(header: Txt("Column default alignment .topLeft, wrapping .word", .bottomCenter),
                    width: width, alignment: .topLeft, wrapping: .word),
                Col(header: Txt("Column default alignment .topLeft, wrapping .word", .bottomCenter),
                    width: width, alignment: .topLeft, wrapping: .word),
            ]
            let table = Tbl(nil,
                            columns: cols, data: data, frameStyle: .default, frameRenderingOptions: .all)
            var t = ""
            table.render(into: &t)
            print(t)
        }
        do {
            let data:[[Txt]] = [
                ["123", Txt("You can't make an omelet without breaking some eggs", .topLeft, .word), Txt("x", .topCenter), Txt("x", .topRight)],
                ["123", Txt("x", .middleLeft), Txt("x", .middleCenter), Txt("x", .middleRight)],
                ["123", Txt("x", .bottomLeft), Txt("x", .bottomCenter), Txt("x", .bottomRight)],
            ]
            let width:Width = 3

            let cols = [
                Col(header: nil,//"#",
                    width: 1, alignment: .topLeft, wrapping: .word),
                Col(header: nil,//"Left",
                    width: 16, alignment: .topLeft, wrapping: .word),
                Col(header: nil,//"Center",
                    width: width, alignment: .topLeft, wrapping: .word),
                Col(header: "Right",
                    width: width, alignment: .topLeft, wrapping: .word),
            ]
            let table = Tbl(Txt("Table title, alignment .middleLeft, frame style .rounded, frame rendering options .all", .middleLeft, .word),
                            columns: cols, data: data, frameStyle: .squaredDouble,
                            frameRenderingOptions: [.all])
            var t = ""
            table.render(into: &t, leftPad:" \n-> ", rightPad: "\n <- ")
            print(t)
        }
        do {
            let data:[[Txt]] = [
                [".......",
                 Txt("no alignment, follows column alignment"),
                 Txt("no alignment, follows column alignment"),
                 Txt("Has alignment .topRight", .topRight)],
                [".......",
                 Txt("no alignment, follows column alignment"),
                 Txt("Has alignment .middleCenter", .middleCenter),
                 Txt("Has alignment .middleRight", .middleRight)],
                [".......",
                 Txt("no alignment, follows column alignment"),
                 Txt("no alignment, follows column alignment"),
                 Txt("Has alignment .bottomRight", .bottomRight)],
            ]
            let width = 10

            let cols = [
                Col(header: nil,
                    width: 1, alignment: .topLeft, wrapping: .word),
                Col(header: Txt("Column default alignment .topLeft, wrapping .word", .bottomCenter),
                    width: .value(width), alignment: .topLeft, wrapping: .word),
                Col(header: Txt("Column default alignment .bottomRight, wrapping .word", .bottomCenter),
                    width: .value(width), alignment: .bottomRight, wrapping: .word),
                Col(header: Txt("Column default alignment .topLeft, wrapping .word", .bottomCenter),
                    width: .value(width), alignment: .topLeft, wrapping: .word),
            ]
            let table = Tbl(Txt("Table title, alignment .middleLeft, frame style .rounded, frame rendering options .all", .middleLeft),
                            columns: cols, data: data, frameStyle: .rounded, frameRenderingOptions: .all)
            var t = ""
            table.render(into: &t)
            print(t)
        }
        do {
            let qbf = "Quick brown fox jumped over the lazy dog."
            let data:[[Txt]] = [
                ["123", Txt("x", .topLeft), Txt("x", .topCenter), Txt("x", .topRight), Txt(qbf.prefix(11).description)],
                ["123", Txt("x", .middleLeft), Txt("x", .middleCenter), Txt("x", .middleRight), Txt(qbf.prefix(22).description)],
                ["123", Txt("x", .bottomLeft), Txt("x", .bottomCenter), Txt("x", .bottomRight), Txt(qbf)],
            ]
            let width = 3

            let cols = [
                Col(header: nil,
                    width: 1, alignment: .topLeft, wrapping: .word),
                Col(header: Txt(" 1 ", .bottomCenter),
                    width: .value(width), alignment: .topLeft, wrapping: .word),
                Col(header: Txt(" 2 ", .topCenter),
                    width: .value(width), alignment: .topLeft, wrapping: .word),
                Col(header: Txt(" 3 ", .bottomCenter),
                    width: .value(width), alignment: .topLeft, wrapping: .word),
                Col(header: Txt("Autowidth column, default alignment .topLeft, wrapping .word", .bottomLeft),
                    width: 0, alignment: .topLeft, wrapping: .word),
            ]
            let table = Tbl(Txt("Table title, alignment .middleLeft, frame style .rounded, frame rendering options .all", .middleLeft),
                            columns: cols, data: data, frameStyle: .rounded, frameRenderingOptions: .all)
            var t = ""
            table.render(into: &t)
            print(t)
        }
        do {
            let data:[[Txt]] = [
                ["123", Txt("x", .topLeft), Txt("x", .topCenter), Txt("x", .topRight)],
                ["123", Txt("x", .middleLeft), Txt("x", .middleCenter), Txt("x", .middleRight)],
                ["123", Txt("x", .bottomLeft), Txt("x", .bottomCenter), Txt("x", .bottomRight)],
            ]
            let width:Width = 5

            let cols = [
                Col(header: "#", width: 1, alignment: .topLeft),
                Col(header: "Col 1", width: width, alignment: .bottomCenter),
                Col(header: "Col 2", width: width, alignment: .bottomCenter),
                Col(header: "Col 3", width: width, alignment: .bottomCenter),
            ]
            let table = Tbl("Table title",
                            columns: cols,
                            data: data,
                            frameStyle: .roundedPadded)
            var t = ""
            table.render(into: &t)
            print(t)
        }
    }
}
