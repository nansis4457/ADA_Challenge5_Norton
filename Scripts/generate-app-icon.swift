#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

private let pixelSize = 1_024
private let outputPath = CommandLine.arguments.dropFirst().first
    ?? "ADA_Challenge5_Norton/ADA_Challenge5_Norton/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

private func color(_ hex: UInt32, alpha: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xff) / 255,
        green: CGFloat((hex >> 8) & 0xff) / 255,
        blue: CGFloat(hex & 0xff) / 255,
        alpha: alpha
    )
}

guard let bitmap = CGContext(
    data: nil,
    width: pixelSize,
    height: pixelSize,
    bitsPerComponent: 8,
    bytesPerRow: pixelSize * 4,
    space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
) else {
    fatalError("앱 아이콘 비트맵을 만들 수 없습니다.")
}

bitmap.setFillColor(color(0xFFF1F4))
bitmap.fill(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))

// Figma `Sweat Character / Stage=4`와 같은 220×240 좌표계를 쓴다.
let scale: CGFloat = 3.45
let offset = CGPoint(x: 132.5, y: 98)

bitmap.saveGState()
bitmap.translateBy(x: offset.x, y: CGFloat(pixelSize) - offset.y)
bitmap.scaleBy(x: scale, y: -scale)

func rect(_ x: CGFloat, _ y: CGFloat, _ width: CGFloat, _ height: CGFloat) -> CGRect {
    CGRect(x: x, y: y, width: width, height: height)
}

func fillEllipse(_ value: CGRect, _ fill: CGColor) {
    bitmap.setFillColor(fill)
    bitmap.fillEllipse(in: value)
}

func fillRoundedRect(_ value: CGRect, radius: CGFloat, fill: CGColor) {
    bitmap.setFillColor(fill)
    bitmap.addPath(CGPath(roundedRect: value, cornerWidth: radius, cornerHeight: radius, transform: nil))
    bitmap.fillPath()
}

fillEllipse(rect(58, 221, 104, 14), color(0x201E1D, alpha: 0.12))

for x in [86.0, 118.0] {
    fillRoundedRect(rect(x, 168, 16, 52), radius: 8, fill: color(0xD6006C, alpha: 0.65))
}

let body = rect(38, 40, 144, 144)
fillEllipse(body, color(0xFFC0D0))

bitmap.saveGState()
bitmap.clip(to: rect(36, 38, 148, 67))
fillEllipse(body, color(0xFF90B1, alpha: 0.55))
bitmap.restoreGState()

bitmap.setStrokeColor(color(0xD6006C))
bitmap.setLineWidth(2.5)
bitmap.strokeEllipse(in: body)

for x in [86.0, 134.0] {
    fillEllipse(rect(x - 19, 84, 38, 44), color(0xFFFFFF))
    fillEllipse(rect(x - 7, 103, 14, 14), color(0x201E1D))
}

let mouth = CGMutablePath()
mouth.move(to: CGPoint(x: 96, y: 148))
mouth.addQuadCurve(to: CGPoint(x: 124, y: 148), control: CGPoint(x: 110, y: 137))
bitmap.addPath(mouth)
bitmap.setStrokeColor(color(0x201E1D))
bitmap.setLineWidth(4)
bitmap.setLineCap(.round)
bitmap.strokePath()

func fillDrop(x: CGFloat, y: CGFloat, dropScale: CGFloat, alpha: CGFloat) {
    let path = CGMutablePath()
    path.move(to: CGPoint(x: x, y: y))
    path.addCurve(
        to: CGPoint(x: x, y: y + 18 * dropScale),
        control1: CGPoint(x: x + 6 * dropScale, y: y + 9 * dropScale),
        control2: CGPoint(x: x + 6 * dropScale, y: y + 14 * dropScale)
    )
    path.addCurve(
        to: CGPoint(x: x, y: y),
        control1: CGPoint(x: x - 6 * dropScale, y: y + 14 * dropScale),
        control2: CGPoint(x: x - 6 * dropScale, y: y + 9 * dropScale)
    )
    path.closeSubpath()
    bitmap.addPath(path)
    bitmap.setFillColor(color(0x38A6CF, alpha: alpha))
    bitmap.fillPath()
}

fillDrop(x: 170, y: 70, dropScale: 1.05, alpha: 0.9)
fillDrop(x: 42, y: 88, dropScale: 0.9, alpha: 0.8)
fillDrop(x: 150, y: 158, dropScale: 0.8, alpha: 0.7)

bitmap.restoreGState()

guard let image = bitmap.makeImage() else {
    fatalError("앱 아이콘 이미지를 만들 수 없습니다.")
}

let representation = NSBitmapImageRep(cgImage: image)
guard let png = representation.representation(using: .png, properties: [:]) else {
    fatalError("앱 아이콘을 PNG로 변환할 수 없습니다.")
}

let outputURL = URL(fileURLWithPath: outputPath)
try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)
try png.write(to: outputURL, options: .atomic)
print(outputURL.path)
