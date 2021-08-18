import Table

var data:[[Txt]] = []
for i in 0..<100 {
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
        cols.append(Txt("99 matches?", alignment: a))
        cols.append(Txt("row\(i+1) column\(j+1) alignment \(astr)", alignment: a))
    }
    data.append(cols)
}
let cols = [
//    Col(header: nil, width: 5, alignment: .topRight),
//    Col(header: nil, width: 6, alignment: .topRight),
//    Col(header: nil, width: 15, alignment: .topRight),
    Col(Txt("Column 1", alignment: .topLeft),      width: 4,  alignment: .topLeft),
    Col(Txt("Column 2", alignment: .topCenter),    width: 0,  alignment: .topRight),
    Col(Txt("Column 3", alignment: .bottomCenter), width: 4,  alignment: .topCenter),
    Col(Txt("Column 4", alignment: .bottomCenter), width: 8,  alignment: .topCenter),
    Col(Txt("Column 5", alignment: .bottomCenter), width: 0,  alignment: .topCenter),
    Col(Txt("Col6",     alignment: .middleCenter), width: 8,  alignment: .topCenter),
    Col(Txt("",         alignment: .bottomCenter), width: 3,  alignment: .topCenter),
    Col(Txt("Column 8", alignment: .bottomCenter), width: 0,  alignment: .topLeft),
]
let table = Tbl("On narrow table this title wraps on multiple lines?", columns: cols, data: data)
var t:String = ""
table.render(into: &t)
print(t)
