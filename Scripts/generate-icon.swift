#!/usr/bin/env swift
// Generates Resources/AppIcon.icns from scratch — a black rounded-square
// with a white checklist glyph and a thin red accent stripe, matching the
// app's in-UI theme. Run once locally when the design changes:
//   swift Scripts/generate-icon.swift
// Requires `iconutil` (part of Xcode command line tools, macOS only).

import AppKit
import Foundation

let fm = FileManager.default
let scriptDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
let repoRoot = scriptDir.deletingLastPathComponent()
let resourcesDir = repoRoot.appendingPathComponent("Resources")
let iconsetDir = resourcesDir.appendingPathComponent("AppIcon.iconset")
let icnsPath = resourcesDir.appendingPathComponent("AppIcon.icns")

try? fm.removeItem(at: iconsetDir)
try fm.createDirectory(at: iconsetDir, withIntermediateDirectories: true)

let red = NSColor(red: 0.92, green: 0.11, blue: 0.16, alpha: 1)
let black = NSColor.black
let white = NSColor.white

func drawIcon(size: CGFloat) -> NSImage {
    let image = NSImage(size: NSSize(width: size, height: size))
    image.lockFocus()

    let cornerRadius = size * 0.225 // approximates macOS Big Sur+ squircle
    let bgRect = NSRect(x: 0, y: 0, width: size, height: size)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
    black.setFill()
    bgPath.fill()

    // Thin red stripe along the bottom, inset to respect the rounded corners.
    let stripeHeight = size * 0.07
    let stripeInset = cornerRadius * 0.55
    let stripeRect = NSRect(
        x: stripeInset,
        y: size * 0.14,
        width: size - stripeInset * 2,
        height: stripeHeight
    )
    red.setFill()
    NSBezierPath(roundedRect: stripeRect, xRadius: stripeHeight / 2, yRadius: stripeHeight / 2).fill()

    // Centered checklist glyph, tinted white via a fill-through-mask.
    let symbolSize = size * 0.5
    let config = NSImage.SymbolConfiguration(pointSize: symbolSize, weight: .bold)
    if let symbol = NSImage(systemSymbolName: "checklist", accessibilityDescription: nil)?
        .withSymbolConfiguration(config) {
        let symbolRect = NSRect(
            x: (size - symbolSize) / 2,
            y: (size - symbolSize) / 2 + size * 0.06,
            width: symbolSize,
            height: symbolSize
        )
        let tinted = NSImage(size: symbolRect.size)
        tinted.lockFocus()
        white.setFill()
        NSRect(origin: .zero, size: symbolRect.size).fill()
        symbol.draw(in: NSRect(origin: .zero, size: symbolRect.size), from: .zero,
                     operation: .destinationIn, fraction: 1.0)
        tinted.unlockFocus()
        tinted.draw(in: symbolRect)
    }

    image.unlockFocus()
    return image
}

func writePNG(_ image: NSImage, to url: URL, size: CGFloat) {
    guard let tiff = image.tiffRepresentation,
          let rep = NSBitmapImageRep(data: tiff),
          let png = rep.representation(using: .png, properties: [:]) else {
        fatalError("Failed to render PNG at size \(size)")
    }
    try? png.write(to: url)
}

let specs: [(name: String, size: CGFloat)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for spec in specs {
    let img = drawIcon(size: spec.size)
    writePNG(img, to: iconsetDir.appendingPathComponent("\(spec.name).png"), size: spec.size)
}

print("Wrote \(specs.count) PNGs to \(iconsetDir.path)")

let task = Process()
task.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
task.arguments = ["-c", "icns", iconsetDir.path, "-o", icnsPath.path]
try task.run()
task.waitUntilExit()

if task.terminationStatus == 0 {
    print("Wrote \(icnsPath.path)")
} else {
    print("iconutil failed with status \(task.terminationStatus)")
    exit(1)
}
