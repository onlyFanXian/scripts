#!/usr/bin/env swift

import Foundation

// MARK: - 检查参数数量
// dropFirst去掉了命令本身。
let args = Array(CommandLine.arguments.dropFirst()) // 第一个参数是脚本路径
guard args.count == 2 else {
    print("❌ 用法: x-append-heic.swift 1.heic 2.heic")
    exit(1)
}

let path1 = URL(fileURLWithPath: args[0])
let path2 = URL(fileURLWithPath: args[1])

// MARK: - 检查扩展名是否为 heic
guard path1.pathExtension.lowercased() == "heic",
      path2.pathExtension.lowercased() == "heic" else {
    print("❌ 请先将图像转为 HEIC 格式后再拼接")
    exit(1)
}

// MARK: - 检查是否在同一目录
guard path1.deletingLastPathComponent() == path2.deletingLastPathComponent() else {
    print("❌ 仅支持位于同一目录的图像")
    exit(1)
}

let directory = path1.deletingLastPathComponent()
let outputFileName = "\(path1.deletingPathExtension().lastPathComponent)-\(path2.deletingPathExtension().lastPathComponent).heic"
let outputPath = directory.appendingPathComponent(outputFileName).path

// MARK: - 调用 magick 执行拼接
let process = Process()
process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/magick")
process.arguments = [path1.path, path2.path, "+append",outputPath]

do {
    try process.run()
    process.waitUntilExit()
    
    if process.terminationStatus == 0 {
        print("✅ 拼接成功: \(outputPath)")
    } else {
        print("❌ 拼接失败，退出码 \(process.terminationStatus)")
        exit(Int32(process.terminationStatus))
    }
} catch {
    print("❌ 执行 magick 失败: \(error.localizedDescription)")
    exit(1)
}
