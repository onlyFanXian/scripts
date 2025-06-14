#!/usr/bin/swift

import Foundation

// MARK: - 工具函数

func isSetFolder(_ name: String) -> Bool {
    return name.range(of: #" Set\.\d+$"#, options: .regularExpression) != nil
}

func uniqueDestinationURL(base: URL, fileName: String) -> URL {
    let fm = FileManager.default
    let name = (fileName as NSString).deletingPathExtension
    let ext = (fileName as NSString).pathExtension

    var candidate = base.appendingPathComponent(fileName)
    var count = 1
    while fm.fileExists(atPath: candidate.path) {
        candidate = base.appendingPathComponent("\(name)_\(count).\(ext)")
        count += 1
    }
    return candidate
}

// MARK: - 主程序

let fm = FileManager.default

guard CommandLine.arguments.count >= 2 else {
    print("❗️用法: ./merge_sets.swift 路径")
    exit(1)
}

let rootPath = CommandLine.arguments[1]
let rootURL = URL(fileURLWithPath: rootPath)

guard let enumerator = fm.enumerator(at: rootURL, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
    print("无法遍历: \(rootPath)")
    exit(1)
}

for case let url as URL in enumerator {
    guard let isDir = try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory, isDir == true else { continue }

    let folderName = url.lastPathComponent
    guard isSetFolder(folderName) else { continue }

    let parent = url.deletingLastPathComponent()
    let baseName = folderName.replacingOccurrences(of: #" Set\.\d+$"#, with: "", options: .regularExpression)
    let targetDir = parent.appendingPathComponent(baseName)

    try? fm.createDirectory(at: targetDir, withIntermediateDirectories: true)

    if let files = try? fm.contentsOfDirectory(atPath: url.path) {
        for file in files {
            let src = url.appendingPathComponent(file)
            let dst = uniqueDestinationURL(base: targetDir, fileName: file)
            do {
                try fm.moveItem(at: src, to: dst)
            } catch {
                print("⚠️ 无法移动 \(file): \(error)")
            }
        }
    }

    print("处理: \(folderName) → \(targetDir.lastPathComponent)")
}

print("✅ 所有 Set 文件夹已合并完毕。")
