
public enum Alignment : UInt8, RawRepresentable, CaseIterable, Codable, Hashable {
    case topLeft, topRight, topCenter
    case bottomLeft, bottomRight, bottomCenter
    case middleLeft, middleRight, middleCenter
}
