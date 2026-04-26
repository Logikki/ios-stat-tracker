//
//  LossyArray.swift
//  stat-tracker
//
//  Created by Roni Koskinen on 26.4.2026.
//

public struct LossyArray<T: Decodable>: Decodable {
    let elements: [T]

    private struct Wrapper: Decodable {
        let value: T?
        init(from decoder: Decoder) throws { value = try? T(from: decoder) }
    }

    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        var elements: [T] = []
        while !container.isAtEnd {
            if let value = try container.decode(Wrapper.self).value {
                elements.append(value)
            }
        }
        self.elements = elements
    }
}
