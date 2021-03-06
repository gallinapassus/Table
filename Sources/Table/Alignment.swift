
public enum Alignment : UInt8, RawRepresentable, CaseIterable, Codable {
    case topLeft, topRight, topCenter
    case bottomLeft, bottomRight, bottomCenter
    case middleLeft, middleRight, middleCenter
}
extension Alignment {
    public static let `default`:Alignment = .topLeft 
}
