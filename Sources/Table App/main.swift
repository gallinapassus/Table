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
        cols.append([Txt("x", alignment: a),Txt("R\(i+1)C\(j+1) alignment \(astr)", alignment: a)].randomElement()!)
    }
    data.append(cols)
}
let cols = [
    Col(Txt("Column 1", alignment: .topLeft),      width: 8,  alignment: .topLeft),
    Col(Txt("Hidden 2", alignment: .topCenter),    width: .hidden,  alignment: .topRight),
    Col(Txt("Column 3", alignment: .bottomCenter), width: 12,  alignment: .topCenter),
    Col(Txt("Hidden 4", alignment: .bottomCenter), width: .hidden,  alignment: .topCenter),
    Col(Txt("Column 5", alignment: .bottomCenter), width: 16,  alignment: .topCenter),
    Col(Txt("Hidden 6", alignment: .bottomCenter), width: .hidden,  alignment: .topLeft),
]
let table = Tbl("On narrow table this title wraps on multiple lines?", columns: cols, data: data)
var t:String = ""
table.render(into: &t)
print(t)
