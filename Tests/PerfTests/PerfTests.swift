import XCTest
//@testable
import Table

let pangram = "The quick brown fox jumps over the lazy dog"

final class TablePerformanceTests : XCTestCase {
    // MARK: -
    // MARK: Performance tests
    lazy var perfDataSource:[[Txt]] = {
        let src = [
            ["A blessing in disguise", "by itself"],
            ["A dime a dozen", "by itself"],
            ["Beat around the bush", "as part of the sentence"],
            ["Better late than never", "by itself"],
            ["Bite the bullet", "as part of the sentence"],
            ["Break a leg", "as part of the sentence"],
            ["Call it a day", "by itself"],
            ["Cutting corners", "by itself"],
            ["Easy does it"], // <- second column data missing intentionally
            ["Get out of hand", "by itself"],
            ["Get something out of your system", "by itself"],
            ["Get your act together", "as part of the sentence"],
            ["Give someone the benefit of the doubt", "as part of the sentence"],
            ["Go back to the drawing board", "as part of the sentence"],
            ["Hang in there", "by itself"],
            ["Hit the sack", "as part of the sentence"]
        ]
        var result:[[Txt]] = []
        for i in 0..<2000 {
            for (j,arr) in src.enumerated() {
                result.append(arr.map({ Txt("[\(i),\(j)]" + $0) }))
            }
        }
        return result
    }()
    // MacBook Pro (15-inch, 2016)
    // Processor 2,9 GHz Quad-Core Intel Core i7
    // Memory 16GB 2133 MHz LPDDR3
    // Radeon Pro 460 4GB, Intel HD Graphics 530 1536 MB
    // macOS Big Sur 11.5.2
    // Xcode version 12.5.1 (12E507)
    // Apple Swift version 5.4.2 (swiftlang-1205.0.28.2 clang-1205.0.19.57)
    func test_Tbl_PerformanceCharWrapping() {
        var data:[[Txt]] = []
        for _ in 0..<2 {
            data.append(contentsOf: perfDataSource)
        }
        
        let cols = [
            Col(width: 8, defaultAlignment: .topLeft, defaultWrapping: .char, contentHint: .unique),
            Col(width: 6, defaultAlignment: .topCenter, defaultWrapping: .char, contentHint: .repetitive),
        ]
        
        measure {
            // Tbl.init is intentionally included as part of the
            // work is done there.
            _ = Tbl("Title", columns: cols, cells: data).render()
        }
    }
    func test_Tbl_PerformanceCutWrapping() {
        var data:[[Txt]] = []
        for _ in 0..<2 {
            data.append(contentsOf: perfDataSource)
        }
        
        let cols = [
            Col(width: 8, defaultAlignment: .topLeft, defaultWrapping: .cut, contentHint: .unique),
            Col(width: 6, defaultAlignment: .topCenter, defaultWrapping: .cut, contentHint: .repetitive),
        ]
        
        measure {
            // Tbl.init is intentionally included as part of the
            // work is done there.
            _ = Tbl("Title", columns: cols, cells: data).render()
        }
    }
    func test_Tbl_PerformanceWordWrapping() {
        var data:[[Txt]] = []
        for _ in 0..<2 {
            data.append(contentsOf: perfDataSource)
        }
        
        let cols = [
            Col(width: 8, defaultAlignment: .topLeft, defaultWrapping: .word, contentHint: .unique),
            Col(width: 6, defaultAlignment: .topCenter, defaultWrapping: .word, contentHint: .repetitive),
        ]
        
        measure {
            // Tbl.init is intentionally included as part of the
            // work is done there.
            _ = Tbl("Title", columns: cols, cells: data).render()
        }
    }
    func testPerformance() throws {
        
        func perfData(rows:Int, columns:Int) -> [[Txt]] {
            let row = Array(repeating: Txt(pangram), count: columns)
            return Array(repeating: row, count: rows)
        }
        
        func makeGibberishWord() -> String {
            let lo = (2..<8).randomElement()!
            let len = (1..<4).randomElement()!
            var word = ""
            for _ in 0..<lo {
                word.append("aeioukl".randomElement()!.description)
            }
            for _ in 0..<len {
                word.append("aeioukl".randomElement()!.description)
            }
            return word
        }
        func gibberish(rowCount:Int, columnCount:Int) -> [[Txt]] {
            precondition(rowCount > 0 && columnCount > 0)
            var res:[[Txt]] = []
            for _ in 0..<rowCount {
                var row:[Txt] = []
                for _ in 0..<columnCount {
                    let wcount = (1...16).randomElement()!
                    var cell:[String] = []
                    for _ in 0..<wcount {
                        cell.append(makeGibberishWord())
                        let re = [" ", "  ", "   ", "\n", "\n\n"].randomElement()!
                        cell.append(re)
                    }
                    row.append(Txt(cell.joined(), wrapping: .word))
                }
                res.append(row)
            }
            return res
        }
        
        let rc = 100
        let cc = 10
        var cells:[[Txt]] = []
        let data:[[Txt]] = perfData(rows: rc, columns: cc)
        let trimmingOpts = [
            TrimmingOptions(rawValue: 0),
            .all,
            [.inlineConsecutiveWhiteSpaces, .leadingWhiteSpaces, .trailingWhiteSpaces],
            [.inlineConsecutiveWhiteSpaces, .inlineConsecutiveNewlines]
        ]
        for ct in ColumnContentHint.allCases {
            for t in trimmingOpts {
                for a in Alignment.allCases {
                    for w in [Width.auto, .fixed(12), .in(12...24), .range(12..<25), .min(16), .max(16)] {
                        for wr in Wrapping.allCases {
                            let cols = (1...cc).map {
                                Col(
                                    "Column \($0)",
                                    width: w,
                                    defaultAlignment: a,
                                    defaultWrapping: wr,
                                    trimming: t,
                                    contentHint: ct
                                )
                            }
                            let telem = [
                                "[\(rc)x\(cc)]",
                                "\(ct)",
                                "\(t.rawValue)",
                                "\(a)",
                                "\(w)",
                                "\(wr)",
                            ]
                            let t0 = DispatchTime.now().uptimeNanoseconds
                            let tbl = Tbl(
                                "\(telem.map({$0}).joined(separator: "\n"))",
                                columns: cols,
                                cells: data
                            )
                            _ = tbl.render(style: .default)
                            let t1 = DispatchTime.now().uptimeNanoseconds
                            //print(r)
                            let render_ms = Double(t1 - t0) / 1_000_000
                            
                            cells.append(
                                telem.map({ Txt($0) }) +
                                [Txt(render_ms.description, alignment: .topRight)]
                            )
                        }
                    }
                }
            }
        }
        let sorted = cells.sorted { l, r in
            Double(l.last!.string)! < Double(r.last!.string)!
        }
        let columns = [
            "#",
            "Table dimensions [RxC]",
            "Content Hint",
            "Trim",
            "Alignment",
            "Width",
            "Wrapping",
            "Duration (ms)",
        ].map({ Col(Txt($0, alignment: .bottomLeft)) })
        let t = Tbl("Performance Summary", columns: columns, cells: sorted, lineNumberGenerator: defaultLnGen)
        let summary = t.render(style: .roundedPadded)
        let tgt = "/tmp/summary.txt"
        try summary.write(toFile: tgt, atomically: true, encoding: .utf8)
        print("Summary written to \(tgt)")
    }
}
