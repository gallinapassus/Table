
public enum Alignment : UInt8, RawRepresentable, CaseIterable, Codable, Hashable {
    case topLeft, topRight, topCenter
    case bottomLeft, bottomRight, bottomCenter
    case middleLeft, middleRight, middleCenter
}
extension Alignment : CustomStringConvertible {
    public var description: String {
        switch self {
        case .topLeft: return "topLeft"
        case .topRight: return "topRight"
        case .topCenter: return "topCenter"
        case .bottomLeft: return "bottomLeft"
        case .bottomRight: return "bottomRight"
        case .bottomCenter: return "bottomCenter"
        case .middleLeft: return "middleLeft"
        case .middleRight: return "middleRight"
        case .middleCenter: return "middleCenter"
        }
    }
}
