#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 2 else {
    fputs("usage: generate_icon.swift <output.icns>\n", stderr)
    exit(2)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1]).standardizedFileURL
let fileManager = FileManager.default
let iconsetURL = outputURL
    .deletingPathExtension()
    .appendingPathExtension("iconset")

try? fileManager.removeItem(at: iconsetURL)
try? fileManager.removeItem(at: outputURL)
try fileManager.createDirectory(
    at: iconsetURL,
    withIntermediateDirectories: true
)

let variants: [(pixels: Int, name: String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png")
]

for variant in variants {
    try drawIcon(
        pixels: variant.pixels,
        to: iconsetURL.appendingPathComponent(variant.name)
    )
}

let iconutil = Process()
iconutil.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
iconutil.arguments = ["-c", "icns", iconsetURL.path, "-o", outputURL.path]
try iconutil.run()
iconutil.waitUntilExit()

guard iconutil.terminationStatus == 0 else {
    fputs("iconutil failed\n", stderr)
    exit(Int32(iconutil.terminationStatus))
}

private func drawIcon(pixels: Int, to url: URL) throws {
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    guard let context = CGContext(
        data: nil,
        width: pixels,
        height: pixels,
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw IconError.renderFailed
    }

    let size = CGFloat(pixels)
    let bounds = CGRect(x: 0, y: 0, width: size, height: size)
    context.clear(bounds)
    context.setAllowsAntialiasing(true)
    context.setShouldAntialias(true)

    drawBackground(in: context, bounds: bounds, size: size)
    drawLock(in: context, bounds: bounds, size: size)

    guard let image = context.makeImage(),
          let destination = CGImageDestinationCreateWithURL(
            url as CFURL,
            UTType.png.identifier as CFString,
            1,
            nil
          ) else {
        throw IconError.renderFailed
    }

    CGImageDestinationAddImage(destination, image, nil)

    guard CGImageDestinationFinalize(destination) else {
        throw IconError.renderFailed
    }
}

private func drawBackground(in context: CGContext, bounds: CGRect, size: CGFloat) {
    let inset = size * 0.055
    let rect = bounds.insetBy(dx: inset, dy: inset)
    let radius = size * 0.22
    let path = CGPath(
        roundedRect: rect,
        cornerWidth: radius,
        cornerHeight: radius,
        transform: nil
    )

    context.saveGState()
    context.addPath(path)
    context.clip()

    let colors = [
        CGColor(red: 0.08, green: 0.35, blue: 0.88, alpha: 1),
        CGColor(red: 0.05, green: 0.66, blue: 0.69, alpha: 1)
    ] as CFArray
    let locations: [CGFloat] = [0, 1]
    let gradient = CGGradient(
        colorsSpace: CGColorSpaceCreateDeviceRGB(),
        colors: colors,
        locations: locations
    )
    context.drawLinearGradient(
        gradient!,
        start: CGPoint(x: rect.minX, y: rect.maxY),
        end: CGPoint(x: rect.maxX, y: rect.minY),
        options: []
    )
    context.restoreGState()

    context.addPath(path)
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.18))
    context.setLineWidth(max(1, size * 0.012))
    context.strokePath()
}

private func drawLock(in context: CGContext, bounds: CGRect, size: CGFloat) {
    let body = CGRect(
        x: bounds.midX - size * 0.20,
        y: bounds.minY + size * 0.25,
        width: size * 0.40,
        height: size * 0.28
    )
    let shackleRect = CGRect(
        x: bounds.midX - size * 0.17,
        y: body.maxY - size * 0.03,
        width: size * 0.34,
        height: size * 0.28
    )

    context.beginPath()
    context.addArc(
        center: CGPoint(x: shackleRect.midX, y: shackleRect.minY),
        radius: shackleRect.width * 0.5,
        startAngle: 0,
        endAngle: .pi,
        clockwise: false
    )
    context.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.92))
    context.setLineWidth(max(2, size * 0.055))
    context.setLineCap(.round)
    context.strokePath()

    let bodyPath = CGPath(
        roundedRect: body,
        cornerWidth: size * 0.055,
        cornerHeight: size * 0.055,
        transform: nil
    )
    context.addPath(bodyPath)
    context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.96))
    context.fillPath()

    context.setFillColor(CGColor(red: 0.07, green: 0.33, blue: 0.72, alpha: 1))
    context.fillEllipse(in: CGRect(
        x: bounds.midX - size * 0.035,
        y: body.midY - size * 0.01,
        width: size * 0.07,
        height: size * 0.07
    ))
    context.fill(CGRect(
        x: bounds.midX - size * 0.015,
        y: body.minY + size * 0.055,
        width: size * 0.03,
        height: size * 0.09
    ))
}

private enum IconError: Error {
    case renderFailed
}
