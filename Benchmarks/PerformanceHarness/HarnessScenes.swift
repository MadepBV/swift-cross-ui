import Foundation
import ImageFormats
import SwiftCrossUI

/// A label row of the kind that fills a CAD app's inspector panels.
struct PropertyRow: View {
    var name: String
    var value: String
    var highlighted: Bool

    var body: some View {
        HStack(spacing: 4) {
            Text(name)
                .foregroundColor(highlighted ? .blue : .gray)
            Text(value)
                .foregroundColor(.black)
        }
        .padding(2)
    }
}

/// A navigator entry: a colour swatch plus two lines of text.
struct SidebarRow: View {
    var title: String
    var subtitle: String
    var color: Color

    var body: some View {
        HStack(spacing: 6) {
            color.frame(width: 12, height: 12)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                Text(subtitle)
                    .foregroundColor(.gray)
            }
        }
        .padding(3)
    }
}

/// A toolbar button.
struct ToolbarItem: View {
    var label: String

    var body: some View {
        Text(label)
            .padding(4)
            .background(Color.gray)
            .cornerRadius(3)
    }
}

/// An inspector panel: a stack of property rows.
struct PropertyPanel: View {
    var title: String
    var rowCount: Int
    var selection: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .foregroundColor(.black)
            ForEach(Array(0..<rowCount)) { index in
                PropertyRow(
                    name: HarnessData.propertyNames[index % HarnessData.propertyNames.count],
                    value: HarnessData.propertyValues[index % HarnessData.propertyValues.count],
                    highlighted: index == selection
                )
            }
        }
        .padding(4)
    }
}

/// The strings and colours the scenes are built from.
enum HarnessData {
    static let propertyNames = [
        "Diameter",
        "Length",
        "Bending radius",
        "Cover",
        "Grade",
        "Shape code",
        "Spacing",
        "Count",
        "Weight",
        "Layer",
    ]

    static let propertyValues = [
        "16 mm",
        "1 250 mm",
        "64 mm",
        "35 mm",
        "B500B",
        "21",
        "150 mm",
        "48",
        "19.7 kg",
        "Slab / top",
    ]

    static let sidebarTitles = [
        "Foundation",
        "Slab",
        "Column",
        "Beam",
        "Wall",
        "Stair",
        "Ramp",
        "Corbel",
        "Pile cap",
        "Capping beam",
    ]

    static let swatchColors: [Color] = [
        .blue,
        .green,
        .orange,
        .purple,
        .red,
        .yellow,
    ]

    /// Builds a viewport-sized RGBA buffer.
    ///
    /// `frame` perturbs the first pixel so that consecutive frames aren't
    /// bitwise identical, which is what a real 3D viewport produces.
    ///
    /// - Parameters:
    ///   - frame: The frame number.
    ///   - width: The buffer's width in pixels.
    ///   - height: The buffer's height in pixels.
    /// - Returns: The buffer as an image.
    static func makeViewport(
        frame: Int,
        width: Int = 640,
        height: Int = 1001
    ) -> ImageFormats.Image<RGBA> {
        var bytes = [UInt8](repeating: 0x20, count: width * height * 4)
        bytes[0] = UInt8(frame % 256)
        return ImageFormats.Image<RGBA>(width: width, height: height, bytes: bytes)
    }
}

/// A CAD-class window: a tool bar, a navigator, a large raster viewport and two
/// inspector panels. Roughly 500 text labels and a few thousand view graph
/// nodes.
struct CADWindow: View {
    /// The number of frames rendered so far. Drives the inspector selection.
    var frame: Int
    /// The viewport's pixels, handed in so that the driver controls whether
    /// they change from frame to frame.
    var viewport: ImageFormats.Image<RGBA>

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 2) {
                ForEach(Array(0..<16)) { index in
                    ToolbarItem(label: "Tool \(index)")
                }
            }
            .padding(4)

            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(0..<120)) { index in
                        SidebarRow(
                            title: HarnessData.sidebarTitles[
                                index % HarnessData.sidebarTitles.count
                            ],
                            subtitle: "id \(index)",
                            color: HarnessData.swatchColors[
                                index % HarnessData.swatchColors.count
                            ]
                        )
                    }
                }
                .frame(width: 220)

                Image(viewport)
                    .resizable()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                VStack(alignment: .leading, spacing: 0) {
                    PropertyPanel(
                        title: "Bar properties",
                        rowCount: 60,
                        selection: frame % 60
                    )
                    PropertyPanel(
                        title: "Placement",
                        rowCount: 60,
                        selection: (frame / 2) % 60
                    )
                }
                .frame(width: 260)
            }

            HStack(spacing: 8) {
                ForEach(Array(0..<6)) { index in
                    Text("Status field \(index)")
                        .foregroundColor(.gray)
                }
            }
            .padding(3)
        }
    }
}

/// A drafting overlay: a `Canvas` issuing a few hundred drawing commands, the
/// shape a CAD app's selection highlights, snap indicators, handles and section
/// markers take. Each command costs one backend widget.
struct DraftingOverlay: View {
    /// Perturbs the drawing so that the animating case actually changes.
    var phase: Double

    var body: some View {
        let phase = phase
        // Wrapped in a stack because a view's body is laid out as if it were a
        // `VStack`, which needs `TupleView` content.
        return VStack(spacing: 0) {
            Canvas { context, size in
                for index in 0..<200 {
                    let t = Double(index) / 200.0
                    let x = t * size.width
                    let y = (0.5 + 0.4 * Foundation.sin(t * 12 + phase)) * size.height
                    var path = Path()
                    path = path.addRectangle(
                        Path.Rect(x: x, y: y, width: 6, height: 6)
                    )
                    context.fill(path, with: .color(.blue))
                    context.stroke(path, with: .color(.black), lineWidth: 1)
                }
                for index in 0..<40 {
                    context.draw(
                        Text("d\(index)"),
                        at: CGPoint(x: Double(index) * 18, y: 12)
                    )
                }
            }
        }
    }
}

/// A long uniform list, the shape a bar schedule or a parts list takes.
struct LongList: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            ForEach(Array(0..<800)) { index in
                PropertyRow(
                    name: HarnessData.propertyNames[index % HarnessData.propertyNames.count],
                    value: HarnessData.propertyValues[index % HarnessData.propertyValues.count],
                    highlighted: false
                )
            }
        }
    }
}

/// The same geometry as ``DraftingOverlay``, drawn as two commands instead of
/// four hundred.
///
/// A controlled experiment against `canvas/animating`: identical number of
/// geometry writes (200 rectangles filled, the same 200 stroked), but two
/// backend widgets instead of four hundred. If a canvas's cost is the geometry
/// it uploads, the two scenes cost the same; if it is the number of native
/// elements being invalidated and re-rendered, this one is dramatically
/// cheaper.
struct MergedDraftingOverlay: View {
    var phase: Double

    var body: some View {
        let phase = phase
        return VStack(spacing: 0) {
            Canvas { context, size in
                var merged = Path()
                for index in 0..<200 {
                    let t = Double(index) / 200.0
                    let x = t * size.width
                    let y = (0.5 + 0.4 * Foundation.sin(t * 12 + phase)) * size.height
                    merged = merged.addRectangle(
                        Path.Rect(x: x, y: y, width: 6, height: 6)
                    )
                }
                context.fill(merged, with: .color(.blue))
                context.stroke(merged, with: .color(.black), lineWidth: 1)
                for index in 0..<40 {
                    context.draw(
                        Text("d\(index)"),
                        at: CGPoint(x: Double(index) * 18, y: 12)
                    )
                }
            }
        }
    }
}
