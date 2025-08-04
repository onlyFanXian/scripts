#!/usr/bin/env swift

import Foundation

// 检查参数
guard CommandLine.arguments.count == 3 else {
    print("用法：setPhotoTime.swift \"起始时间\" \"/路径/到/目录\"")
    exit(1)
}

let startTimeString = CommandLine.arguments[1]  // "2023-07-01 10:00:00"
let folderPath = CommandLine.arguments[2]       // "/Users/xian/Pictures/写真"

let dateFormatter = DateFormatter()
dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
dateFormatter.locale = Locale(identifier: "en_US_POSIX")

guard let startDate = dateFormatter.date(from: startTimeString) else {
    print("❌ 起始时间格式错误，格式应为 yyyy-MM-dd HH:mm:ss")
    exit(1)
}

// 获取所有图片文件（HEIC/JPG/PNG），按文件名排序
let fileManager = FileManager.default
guard let fileURLs = try? fileManager.contentsOfDirectory(atPath: folderPath) else {
    print("❌ 无法读取目录")
    exit(1)
}

let imageExtensions = ["heic", "jpg", "jpeg", "png"]
let imageFiles = fileURLs
    .filter { url in
        let ext = (url as NSString).pathExtension.lowercased()
        return imageExtensions.contains(ext)
    }
    .sorted()

// 逐个文件设置时间
for (index, file) in imageFiles.enumerated() {
    let imagePath = (folderPath as NSString).appendingPathComponent(file)
    let newDate = startDate.addingTimeInterval(TimeInterval(index))

    let exifTime = DateFormatter()
    exifTime.dateFormat = "yyyy:MM:dd HH:mm:ss"
    exifTime.locale = Locale(identifier: "en_US_POSIX")
    let formattedTime = exifTime.string(from: newDate)

    print("👉 修改 [\(file)] → \(formattedTime)")

    // 调用 exiftool 命令
    let task = Process()
    task.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/exiftool")  // 或 /opt/homebrew/bin/exiftool（M1 Mac）
    task.arguments = [
        "-overwrite_original",
        "-DateTimeOriginal=\(formattedTime)",
        "-CreateDate=\(formattedTime)",
        "-ModifyDate=\(formattedTime)",
        imagePath
    ]

    do {
        try task.run()
        task.waitUntilExit()
    } catch {
        print("❌ 修改失败：\(file)")
    }
}
