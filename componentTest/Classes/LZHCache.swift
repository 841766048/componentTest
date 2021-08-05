//
//	File name:  LZHCache.swift
//	Description:
//	2021/8/3 File created.


import Foundation
import Cache

@objc class LZHCacheKey: NSObject { }

@objc class LZHDiskName: NSObject { }

public class LZHCacheTool: NSObject {
    /// 获取磁盘配置对象
    /// - Parameters:
    ///   - name: 磁盘存储的名称，这将用作目录中的文件夹名称
    ///   - expiry: 默认情况下为每个添加的对象应用的到期日期
    ///   - maxSize: 磁盘缓存存储的最大大小（以字节为单位）
    ///   - directory: 存储磁盘缓存的位置。如果为 nil，则放置在 `cachesDirectory` 目录中。
    ///   - protectionType: 数据保护是用来存储文件以加密格式在磁盘上，并对其进行解密需求
    /// - Returns: 返回DiskConfig对象
    public static func getDiskConfig(name: String, expiry: Expiry = .never,
                              maxSize: UInt = 0, directory: URL? = nil,
                              protectionType: FileProtectionType? = nil) ->DiskConfig {
        return DiskConfig(name: name, expiry: expiry,
                          maxSize: maxSize, directory: directory,
                          protectionType: protectionType)
    }

    /// 获取内存配置对象
    /// - Parameters:
    ///   - expiry: 默认情况下为每个添加的对象应用的到期日期
    ///   - countLimit: 缓存应该容纳的最大内存对象数
    ///   - totalCostLimit: 在开始驱逐对象之前缓存可以容纳的最大总成本
    /// - Returns: 返回MemoryConfig
    public static func getMemoryConfig(expiry: Expiry = .never, countLimit: UInt = 0,
                                totalCostLimit: UInt = 0) -> MemoryConfig {
        return MemoryConfig(expiry: expiry, countLimit: countLimit, totalCostLimit: totalCostLimit)
    }
}

public final class LZHCache<T:Codable> {
    let diskConfig: Cache.DiskConfig
    let memoryConfig: Cache.MemoryConfig
    
    public init(diskConfig: Cache.DiskConfig, memoryConfig: Cache.MemoryConfig) {
        self.diskConfig = diskConfig
        self.memoryConfig = memoryConfig
    }
    
    func getStoreTool() -> Cache.Storage<String, T> {
        let store = try! Cache.Storage<String, String>(
            diskConfig: diskConfig,
            memoryConfig: memoryConfig,
            transformer: TransformerFactory.forCodable(ofType: String.self) // Storage<String, T>
          )
        return store.transformCodable(ofType: T.self)
    }
}

extension LZHCache {

    /// 同步保存数据
    /// - Parameters:
    ///   - data: 保存的数据
    ///   - key: 保存的key
    public func syncSaveData(data: T, key: String) {
        guard let _ = try? getStoreTool().setObject(data, forKey: key) else {
            print("保存数据出错")
            return
        }
    }

    /// 同步获取缓存数据
    /// - Parameter key: 缓存的key值
    /// - Returns: 缓存的数据
    public func syncGetData(key: String) -> T? {
        guard let data = try? getStoreTool().object(forKey: key) else {
            print("获取数据出错")
            return nil
        }
        return data
    }

    /// 同步检测缓存的key是否存在
    /// - Parameter key: 缓存的key值
    /// - Returns: true：存在  false：不存在
    public func syncExistsObject(key: String) -> Bool {
        guard let value = try? getStoreTool().existsObject(forKey: key) else {
            return false
        }
        return value
    }

    /// 删除存储的key
    /// - Parameter key: 缓存的key值
    public func syncRemoveObject(key: String) {
        guard let _ = try? getStoreTool().removeObject(forKey: key) else {
            print("删除失败")
            return
        }
        print("\(key) 删除成功")
    }

    /// 删除存储的所有key
    public func syncRemoveAll() {
        guard let _ = try? getStoreTool().removeAll() else {
            print("删除失败")
            return
        }
        print("全部key删除成功")
    }

    /// 删除过期对象
    public func syncRemoveExpiredObjects() {
        guard let _ = try? getStoreTool().removeExpiredObjects() else {
            print("删除过期对象失败")
            return
        }
        print("删除过期对象成功")
    }
}

extension LZHCache {

    /// 异步保存数据
    /// - Parameters:
    ///   - data: 保存的数据
    ///   - key: 保存的key
    ///   - success: 保存成功回调
    ///   - failure: 失败回调
    public func asyncSaveData(data: T, key: String, success:(()->Void)? = nil, failure: (()->Void)? = nil) {
        getStoreTool().async.setObject(data, forKey: key, completion: { result in
            switch result {
            case .value:
                print("数据保存成功")
                if let suc = success {
                    suc()
                }
            case .error(let error):
                print("error = \(error)")
                if let fai = failure {
                    fai()
                }
            }
        })
    }

    /// 异步获取数据
    /// - Parameters:
    ///   - key: 缓存的key值
    ///   - success: 获取成功回调
    ///   - failure: 获取失败回调
    public func asyncGetData(key: String, success:((T)->Void)? = nil, failure: (()->Void)? = nil) {
        getStoreTool().async.object(forKey: key) { result in
          switch result {
            case .value(let value):
                if let suc = success {
                    suc(value)
                }
            case .error(let error):
                print(error)
                if let fai = failure {
                    fai()
                }
          }
        }
    }
}
