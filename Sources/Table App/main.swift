import Table

var data:[[Txt]] = []
for i in 0..<50000 {
    var cols:[Txt] = []
    let cmax = [1,2,3,4,5/*,6,7,8,9,10,11*/].randomElement()!
    for j in 0..<cmax {
        let a:Alignment?
        if Bool.random() {
            a = Alignment.allCases.randomElement()!
        }
        else {
            a = nil
        }
        let astr = a == nil ? "nil" : "\(a!)"
        cols.append([Txt("x", align: a),Txt("R\(i+1)C\(j+1) alignment \(astr)", align: a)].randomElement()!)
    }
    data.append(cols)
}
let cols = [
    Col(Txt("Column 1", align: .topLeft),      width: 8,  columnDefaultAlignment: .topLeft),
    Col(Txt("Hidden 2", align: .topCenter),    width: .hidden,  columnDefaultAlignment: .topRight),
    Col(Txt("Column 3", align: .bottomCenter), width: 12,  columnDefaultAlignment: .topCenter),
    Col(Txt("Hidden 4", align: .bottomCenter), width: .hidden,  columnDefaultAlignment: .topCenter),
    Col(Txt("Column 5", align: .bottomCenter), width: 16,  columnDefaultAlignment: .topCenter),
    Col(Txt("Hidden 6", align: .bottomCenter), width: .hidden,  columnDefaultAlignment: .topLeft),
]
let table = Tbl("On narrow table this title wraps on multiple lines?", columns: cols, cells: data)
var t:any TextOutputStream = ""
table.render(to: &t)
print(t)
