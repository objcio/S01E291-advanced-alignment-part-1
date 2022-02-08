//
//  ContentView.swift
//  TreesWithAlignment
//
//  Created by Chris Eidhof on 07.02.22.
//

import SwiftUI

struct Tree<A>: Identifiable {
    init(_ value: A, children: [Tree<A>] = []) {
        self.value = value
        self.children = children
    }
    
    var value: A
    var children: [Tree<A>] = []
    let id = UUID()
}

let sample = Tree("Root", children: [
    Tree("First Child With Some More Text"),
    Tree("Second"),
])

struct Line: Shape {
    var from: CGPoint
    var to: CGPoint
    
    func path(in rect: CGRect) -> Path {
        Path { p in
            p.move(to: from)
            p.addLine(to: to)
        }
    }
}

struct FrameKey: PreferenceKey {
    static var defaultValue: [UUID: CGRect] { [:] }
    static func reduce(value: inout [UUID : CGRect], nextValue: () -> [UUID : CGRect]) {
        value.merge(nextValue(), uniquingKeysWith: { $1 })
    }
}

extension View {
    func measureFrame(in coordinateSpace: CoordinateSpace, id: UUID) -> some View {
        background(GeometryReader { proxy in
            Color.clear.preference(key: FrameKey.self, value: [id: proxy.frame(in: coordinateSpace)])
        })
    }
}

struct Diagram<A, Node: View>: View {
    var tree: Tree<A>
    @ViewBuilder var node: (A) -> Node
    
    let coordinateSpace = "diagram"
    
    var body: some View {
        VStack(spacing: 20) {
            node(tree.value)
                .measureFrame(in: .named(coordinateSpace), id: tree.id)
            HStack(spacing: 20) {
                ForEach(tree.children) { child in
                    Diagram(tree: child, node: node)
                        .measureFrame(in: .named(coordinateSpace), id: child.id)
                }
            }
        }
        .backgroundPreferenceValue(FrameKey.self) { frames in
            let rootFrame = frames[tree.id]!
            let childFrames: [(UUID, CGRect)] = frames.filter { $0.key != tree.id }
            ForEach(childFrames, id: \.0) { (_, childFrame) in
                Line(from: rootFrame[.bottom], to: childFrame[.top])
                    .stroke(lineWidth: 1)
            }
        }
        .coordinateSpace(name: coordinateSpace)
        .preference(key: FrameKey.self, value: [:])
    }
}

extension CGRect {
    subscript(point: UnitPoint) -> CGPoint {
        CGPoint(x: minX + point.x * width, y: minY + point.y * height)
    }
}

struct ContentView: View {
    var body: some View {
        Diagram(tree: sample) { value in
            Text(value)
                .fixedSize()
                .padding()
                .background(.tertiary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
