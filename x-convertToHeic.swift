#!/usr/bin/env swift

import Foundation

let supportedExtensions: Set<String> = ["jpg", "jpeg", "png", "tiff"]

let fileManager = FileManager.default
let queue = DispatchQueue.global(qos: .userInitiated)
let group = DispatchGroup()

func convertImage(at path: URL) {
    guard fileManager.fileExists(atPath: path.path) else { return }
    let ext = path.pathExtension.lowercased()
    guard supportedExtensions.contains(ext) else { return }

    let outputURL = path.deletingPathExtension().appendingPathExtension("heic")

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    process.arguments = [
        "--setProperty", "format", "heic",
        path.path,
        "--out", outputURL.path,
    ]

    do {
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            try fileManager.removeItem(at: path)
            print("✅ \(path.lastPathComponent) → \(outputURL.lastPathComponent)")
        } else {
            print("❌ 转换失败: \(path.lastPathComponent)")
        }
    } catch {
        print("❌ 错误: \(error.localizedDescription)")
    }
}

func processPath(_ inputPath: URL) {
    var filesToConvert: [URL] = []

    var isDir: ObjCBool = false
    if fileManager.fileExists(atPath: inputPath.path, isDirectory: &isDir) {
        if isDir.boolValue {
            if let enumerator = fileManager.enumerator(
                at: inputPath, includingPropertiesForKeys: nil)
            {
                for case let fileURL as URL in enumerator {
                    if supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                        filesToConvert.append(fileURL)
                    }
                }
            }
        } else {
            if supportedExtensions.contains(inputPath.pathExtension.lowercased()) {
                filesToConvert.append(inputPath)
            }
        }
    } else {
        print("❌ 路径无效")
        return
    }

    for fileURL in filesToConvert {
        group.enter()
        queue.async {
            convertImage(at: fileURL)
            group.leave()
        }
    }

    group.wait()
}

// MARK: - Main

let args = CommandLine.arguments
guard args.count == 2 else {
    print("用法: ./fast_sips.swift <文件或文件夹路径>")
    exit(1)
}

let inputPath = URL(fileURLWithPath: (args[1] as NSString).expandingTildeInPath)
processPath(inputPath)
