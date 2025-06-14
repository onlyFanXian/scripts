#!/usr/bin/env swift

import Foundation
// 支持的文件类型，String类集合
let supportedExtensions: Set<String> = ["jpg", "jpeg", "png", "tiff"]


// 创建一个文件操作类
let fileManager = FileManager.default
// 创建一个队列操作，方便多线程吗
let queue = DispatchQueue.global(qos: .userInitiated)
let group = DispatchGroup()

func convertImage(at path: URL) {
    // guard 确保文件存在
    guard fileManager.fileExists(atPath: path.path) else { return }
    // 我怎么感觉重复了，确认了两遍扩展名
    let ext = path.pathExtension.lowercased()
    guard supportedExtensions.contains(ext) else { return }
    // 更改扩展名
    let outputURL = path.deletingPathExtension().appendingPathExtension("heic")
    // 创建进程，调用系统命令
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/sips")
    // 就像执行命令一样
    process.arguments = [
        "--setProperty", "format", "heic",
        path.path,
        "--out", outputURL.path,
    ]
    //  执行命令
    do {
        try process.run()
        process.waitUntilExit()

        if process.terminationStatus == 0 {
            try fileManager.removeItem(at: path)
            // lastPathComponent 路径的最后一部分，就是/
            print("✅ \(path.lastPathComponent) → \(outputURL.lastPathComponent)")
        } else {
            print("❌ 转换失败: \(path.lastPathComponent)")
        }
    } catch {
        print("❌ 错误: \(error.localizedDescription)")
    }
}



// 获取路径后从这里开始执行
// _省略外部参数名，就是说调用函数的时候不用输入processPath(inputPath:xxx),而是直接用processPath(xxx)
func processPath(_ inputPath: URL) {
    // 建立一个空数组
    var filesToConvert: [URL] = []
    // 判断是不是文件夹
    // 落后的代码要兼容objc
    var isDir: ObjCBool = false
    if fileManager.fileExists(atPath: inputPath.path, isDirectory: &isDir) {
        // 传入的是文件夹，遍历添加
        if isDir.boolValue {
            // 使用迭代器获取所有文件和文件夹路径url
            if let enumerator = fileManager.enumerator(at: inputPath, includingPropertiesForKeys: nil){
                // 因为enumerator是any类型，所以fileURL要as声明URL类型
                // for case let ... in 是模式匹配循环，等价于
                // for item in enumerator{
                //      if let fileURL = item as? URL
                // }
                for case let fileURL as URL in enumerator {
                    // 如果扩展名在我们设计的集合中，添加入fileURL
                    if supportedExtensions.contains(fileURL.pathExtension.lowercased()) {
                        filesToConvert.append(fileURL)
                    }
                }
            }
        } else {
            // 传入的是文件路径，直接处理文件
            if supportedExtensions.contains(inputPath.pathExtension.lowercased()) {
                filesToConvert.append(inputPath)
            }
        }
    } else {
        print("❌ 路径无效")
        return
    }
    // 并发编程。好啊。高性能
    for fileURL in filesToConvert {
        // 通过group的进出
        group.enter()
        queue.async {
            convertImage(at: fileURL)
            group.leave()
        }
    }

    group.wait()
}

// MARK: - Main
// 传入参数，参数要==两个,命令本身算一个参数，路径算一个参数
let args = CommandLine.arguments
guard args.count == 2 else {
    print("传入一个文件夹，遍历文件夹中的图像转换为heic格式")
    // 1 表示是错误返回。正常返回为0
    exit(1)
}
// as NSString 把swift的string转化为apple的NSString方便后续操作。.expandingTildeInPath可以补全完整路径。
let inputPath = URL(fileURLWithPath: (args[1] as NSString).expandingTildeInPath)
processPath(inputPath)
