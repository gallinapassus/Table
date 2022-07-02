public struct FrameElements : Equatable, Codable {
    
    public struct Element : CustomStringConvertible, ExpressibleByStringLiteral, Equatable, Codable {
        public static func == (lhs: FrameElements.Element, rhs: FrameElements.Element) -> Bool {
            lhs.element == rhs.element
        }
        
        public typealias StringLiteralType = String

        public var description: String { element }
        private (set) public var element:String
        public var customEvaluation:((FrameRenderingOptions) -> String)? = nil
        private func defaultLogic(_ options:FrameRenderingOptions) -> String {
            "#"
        }
        public init(stringLiteral value:StringLiteralType) {
            self.element = value
        }
        public init(_ value:String) {
            self.element = value
        }
        public enum CodingKeys : CodingKey {
            case element
        }
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.element = try container.decode(String.self, forKey: .element)
        }
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(self.element, forKey: .element)
        }
        public func element(for options:FrameRenderingOptions) -> String {
            return customEvaluation?(options) ?? defaultLogic(options)
        }
    }
    public var topLeftCorner:                     Element
    public var topHorizontalSeparator:            Element
    public var topHorizontalVerticalSeparator:    Element
    public var topRightCorner:                    Element
    public var leftVerticalSeparator:             Element
    public var rightVerticalSeparator:            Element
    public var insideLeftVerticalSeparator:       Element
    public var insideHorizontalSeparator:         Element
    public var insideRightVerticalSeparator:      Element
    public var insideHorizontalVerticalSeparator: Element
    public var insideVerticalSeparator:           Element
    public var bottomLeftCorner:                  Element
    public var bottomHorizontalSeparator:         Element
    public var bottomHorizontalVerticalSeparator: Element
    public var bottomRightCorner:                 Element
    public init(
        topLeftCorner:                     Element,
        topHorizontalSeparator:            Element,
        topHorizontalVerticalSeparator:    Element,
        topRightCorner:                    Element,
        leftVerticalSeparator:             Element,
        rightVerticalSeparator:            Element,
        insideLeftVerticalSeparator:       Element,
        insideHorizontalSeparator:         Element,
        insideRightVerticalSeparator:      Element,
        insideHorizontalVerticalSeparator: Element,
        insideVerticalSeparator:           Element,
        bottomLeftCorner:                  Element,
        bottomHorizontalSeparator:         Element,
        bottomHorizontalVerticalSeparator: Element,
        bottomRightCorner:                 Element
    ) {
        let pairs = [
            (topLeftCorner, bottomLeftCorner),
            (topLeftCorner, leftVerticalSeparator),
            (topLeftCorner, insideLeftVerticalSeparator),

            (topRightCorner, bottomRightCorner),
            (topRightCorner, rightVerticalSeparator),
            (topRightCorner, insideRightVerticalSeparator),

            (topHorizontalSeparator, bottomHorizontalSeparator),
            (topHorizontalSeparator, insideHorizontalSeparator),

            (leftVerticalSeparator, insideLeftVerticalSeparator),

            (rightVerticalSeparator, insideRightVerticalSeparator),

            (topHorizontalVerticalSeparator, bottomHorizontalVerticalSeparator),
            (topHorizontalVerticalSeparator, insideHorizontalVerticalSeparator),
        ]
        for (l,r) in pairs {
            precondition(l.element.count == r.element.count, "\(FrameElements.self) \"\(l)\" and \"\(r)\" have different string lengths and would produce misaligned frame.")
        }
        for mustBeSingleChar in [topHorizontalSeparator, insideHorizontalSeparator, bottomHorizontalSeparator] {
            precondition(mustBeSingleChar.element.count == 1, "\(FrameElements.self) \"\(mustBeSingleChar)\" length must be 1.")
        }
        self.topLeftCorner                     = topLeftCorner
        self.topHorizontalSeparator            = topHorizontalSeparator
        self.topHorizontalVerticalSeparator    = topHorizontalVerticalSeparator
        self.topRightCorner                    = topRightCorner
        self.leftVerticalSeparator             = leftVerticalSeparator
        self.rightVerticalSeparator            = rightVerticalSeparator
        self.insideLeftVerticalSeparator       = insideLeftVerticalSeparator
        self.insideHorizontalSeparator         = insideHorizontalSeparator
        self.insideRightVerticalSeparator      = insideRightVerticalSeparator
        self.insideHorizontalVerticalSeparator = insideHorizontalVerticalSeparator
        self.insideVerticalSeparator           = insideVerticalSeparator
        self.bottomLeftCorner                  = bottomLeftCorner
        self.bottomHorizontalSeparator         = bottomHorizontalSeparator
        self.bottomHorizontalVerticalSeparator = bottomHorizontalVerticalSeparator
        self.bottomRightCorner                 = bottomRightCorner

        self.topLeftCorner.customEvaluation = topLeftCorner.customEvaluation ?? _topLeftCorner
        self.topHorizontalSeparator.customEvaluation = topHorizontalSeparator.customEvaluation ?? _topHorizontalSeparator
        self.topHorizontalVerticalSeparator.customEvaluation = topHorizontalVerticalSeparator.customEvaluation ?? _topHorizontalVerticalSeparator
        self.topRightCorner.customEvaluation = topRightCorner.customEvaluation ?? _topRightCorner
        self.leftVerticalSeparator.customEvaluation = leftVerticalSeparator.customEvaluation ?? _leftVerticalSeparator
        self.rightVerticalSeparator.customEvaluation = rightVerticalSeparator.customEvaluation ?? _rightVerticalSeparator
        self.insideLeftVerticalSeparator.customEvaluation = insideLeftVerticalSeparator.customEvaluation ?? _insideLeftVerticalSeparator
        self.insideHorizontalSeparator.customEvaluation = insideHorizontalSeparator.customEvaluation ?? _insideHorizontalSeparator
        self.insideRightVerticalSeparator.customEvaluation = insideRightVerticalSeparator.customEvaluation ?? _insideRightVerticalSeparator
        self.insideHorizontalVerticalSeparator.customEvaluation = insideHorizontalVerticalSeparator.customEvaluation ?? _insideHorizontalVerticalSeparator
        self.insideVerticalSeparator.customEvaluation = insideVerticalSeparator.customEvaluation ?? _insideVerticalSeparator
        self.bottomLeftCorner.customEvaluation = bottomLeftCorner.customEvaluation ?? _bottomLeftCorner
        self.bottomHorizontalSeparator.customEvaluation = bottomHorizontalSeparator.customEvaluation ?? _bottomHorizontalSeparator
        self.bottomHorizontalVerticalSeparator.customEvaluation = bottomHorizontalVerticalSeparator.customEvaluation ?? _bottomHorizontalVerticalSeparator
        self.bottomRightCorner.customEvaluation =  bottomRightCorner.customEvaluation ?? _bottomRightCorner
    }

    private func _topLeftCorner(o:FrameRenderingOptions) -> String {
        o.contains([.leftFrame, .topFrame]) ? topLeftCorner.element : ""
    }
    private func _topHorizontalSeparator(o:FrameRenderingOptions) -> String {
        (o.contains(.topFrame) || o.contains(.inside)) ? topHorizontalSeparator.element : " "
    }
    private func _topHorizontalVerticalSeparator(o:FrameRenderingOptions) -> String {
        o.contains([.topFrame, .inside]) || o.contains(.inside) ? topHorizontalVerticalSeparator.element : ""
    }
    private func _topRightCorner(o:FrameRenderingOptions) -> String {
        o.contains([.rightFrame, .topFrame]) ? topRightCorner.element : ""
    }
    private func _leftVerticalSeparator(o:FrameRenderingOptions) -> String {
        o.contains(.leftFrame) ? leftVerticalSeparator.element : ""
    }
    private func _rightVerticalSeparator(o:FrameRenderingOptions) -> String {
        o.contains(.rightFrame) ? rightVerticalSeparator.element : ""
    }
    private func _insideLeftVerticalSeparator(o:FrameRenderingOptions) -> String {
        o.contains(.leftFrame) ? insideLeftVerticalSeparator.element : ""
    }
    private func _insideHorizontalSeparator(o:FrameRenderingOptions) -> String {
        (o.contains(.insideHorizontalFrame) || o.contains(.leftFrame) || o.contains(.rightFrame)) ? insideHorizontalSeparator.element : " "
    }
    private func _insideRightVerticalSeparator(o:FrameRenderingOptions) -> String {
        o.contains(.rightFrame) ? insideRightVerticalSeparator.element : ""
    }
    private func _insideHorizontalVerticalSeparator(o:FrameRenderingOptions) -> String {
        o.contains(.insideHorizontalFrame) && o.contains(.insideVerticalFrame) ?
            insideHorizontalVerticalSeparator.element : ""
    }
    private func _insideVerticalSeparator(o:FrameRenderingOptions) -> String {
        o.contains(.insideVerticalFrame) ? insideVerticalSeparator.element : ""
    }
    private func _bottomLeftCorner(o:FrameRenderingOptions) -> String {
        o.contains([.leftFrame, .bottomFrame]) ? bottomLeftCorner.element : ""
    }
    private func _bottomHorizontalSeparator(o:FrameRenderingOptions) -> String {
        o.contains(.bottomFrame) ? bottomHorizontalSeparator.element : " "
    }
    private func _bottomHorizontalVerticalSeparator(o:FrameRenderingOptions) -> String {
        o.contains([.bottomFrame, .insideVerticalFrame]) ? bottomHorizontalVerticalSeparator.element : ""
    }
    private func _bottomRightCorner(o:FrameRenderingOptions) -> String {
        o.contains([.rightFrame, .bottomFrame]) ? bottomRightCorner.element : ""
    }
}
extension FrameElements {
    public static var squared: Self {
        FrameElements(
            topLeftCorner:                        "┌",
            topHorizontalSeparator:               "─",
            topHorizontalVerticalSeparator:       "┬",
            topRightCorner:                       "┐",
            leftVerticalSeparator:                "│",
            rightVerticalSeparator:               "│",
            insideLeftVerticalSeparator:          "├",
            insideHorizontalSeparator:            "─",
            insideRightVerticalSeparator:         "┤",
            insideHorizontalVerticalSeparator:    "┼",
            insideVerticalSeparator:              "│",
            bottomLeftCorner:                     "└",
            bottomHorizontalSeparator:            "─",
            bottomHorizontalVerticalSeparator:    "┴",
            bottomRightCorner:                    "┘"
        )
    }

    public static var rounded: Self {
        FrameElements(
            topLeftCorner:                        "╭",
            topHorizontalSeparator:               "─",
            topHorizontalVerticalSeparator:       "┬",
            topRightCorner:                       "╮",
            leftVerticalSeparator:                "│",
            rightVerticalSeparator:               "│",
            insideLeftVerticalSeparator:          "├",
            insideHorizontalSeparator:            "─",
            insideRightVerticalSeparator:         "┤",
            insideHorizontalVerticalSeparator:    "┼",
            insideVerticalSeparator:              "│",
            bottomLeftCorner:                     "╰",
            bottomHorizontalSeparator:            "─",
            bottomHorizontalVerticalSeparator:    "┴",
            bottomRightCorner:                    "╯"
        )
    }
    public static var roundedPadded: Self {
        FrameElements(
            topLeftCorner:                        "╭─",
            topHorizontalSeparator:               "─",
            topHorizontalVerticalSeparator:       "─┬─",
            topRightCorner:                       "─╮",
            leftVerticalSeparator:                "│ ",
            rightVerticalSeparator:               " │",
            insideLeftVerticalSeparator:          "├─",
            insideHorizontalSeparator:            "─",
            insideRightVerticalSeparator:         "─┤",
            insideHorizontalVerticalSeparator:    "─┼─",
            insideVerticalSeparator:              " │ ",
            bottomLeftCorner:                     "╰─",
            bottomHorizontalSeparator:            "─",
            bottomHorizontalVerticalSeparator:    "─┴─",
            bottomRightCorner:                    "─╯"
        )
    }
}
extension FrameElements {
    public static var `default`:Self {
        FrameElements(
            topLeftCorner:                        "+",
            topHorizontalSeparator:               "-",
            topHorizontalVerticalSeparator:       "+",
            topRightCorner:                       "+",
            leftVerticalSeparator:                "|",
            rightVerticalSeparator:               "|",
            insideLeftVerticalSeparator:          "+",
            insideHorizontalSeparator:            "-",
            insideRightVerticalSeparator:         "+",
            insideHorizontalVerticalSeparator:    "+",
            insideVerticalSeparator:              "|",
            bottomLeftCorner:                     "+",
            bottomHorizontalSeparator:            "-",
            bottomHorizontalVerticalSeparator:    "+",
            bottomRightCorner:                    "+"
        )
    }
    public static var ascii:Self {
        `default`
    }
    public static var singleSpace:Self {
        FrameElements(
            topLeftCorner:                        " ",
            topHorizontalSeparator:               " ",
            topHorizontalVerticalSeparator:       " ",
            topRightCorner:                       " ",
            leftVerticalSeparator:                " ",
            rightVerticalSeparator:               " ",
            insideLeftVerticalSeparator:          " ",
            insideHorizontalSeparator:            " ",
            insideRightVerticalSeparator:         " ",
            insideHorizontalVerticalSeparator:    " ",
            insideVerticalSeparator:              " ",
            bottomLeftCorner:                     " ",
            bottomHorizontalSeparator:            " ",
            bottomHorizontalVerticalSeparator:    " ",
            bottomRightCorner:                    " "
        )
    }
    public static var squaredDouble:Self {
        FrameElements(
            topLeftCorner:                        "╔",
            topHorizontalSeparator:               "═",
            topHorizontalVerticalSeparator:       "╦",
            topRightCorner:                       "╗",
            leftVerticalSeparator:                "║",
            rightVerticalSeparator:               "║",
            insideLeftVerticalSeparator:          "╠",
            insideHorizontalSeparator:            "═",
            insideRightVerticalSeparator:         "╣",
            insideHorizontalVerticalSeparator:    "╬",
            insideVerticalSeparator:              "║",
            bottomLeftCorner:                     "╚",
            bottomHorizontalSeparator:            "═",
            bottomHorizontalVerticalSeparator:    "╩",
            bottomRightCorner:                    "╝"
        )
    }
}
