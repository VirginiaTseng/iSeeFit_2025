import Foundation

// MARK: - 用户配置管理（简化版）
class UserConfig: ObservableObject {
    static let shared = UserConfig()
    
    @Published var openAIAPIKey: String = ""
    
    private let configFileName = "user_config.txt"
    private let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    
    private init() {
        loadConfig()
    }
    
    // MARK: - 配置文件路径
    private var configFileURL: URL {
        return documentsPath.appendingPathComponent(configFileName)
    }
    
    // MARK: - 加载配置（优先从项目 bundle 读取）
    private func loadConfig() {
        // 1. 首先尝试从项目 bundle 读取
        if let bundleURL = Bundle.main.url(forResource: "user_config", withExtension: "txt") {
            do {
                let content = try String(contentsOf: bundleURL, encoding: .utf8)
                let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedContent.isEmpty && !trimmedContent.hasPrefix("#") && !trimmedContent.contains("your_openai_api_key_here") {
                    openAIAPIKey = trimmedContent
                    print("DEBUG: UserConfig - Loaded API key from bundle user_config.txt")
                    return
                }
            } catch {
                print("DEBUG: UserConfig - Error reading from bundle: \(error)")
            }
        }
        
        // 2. 尝试从 Documents 目录读取
        do {
            let content = try String(contentsOf: configFileURL, encoding: .utf8)
            openAIAPIKey = content.trimmingCharacters(in: .whitespacesAndNewlines)
            print("DEBUG: UserConfig - Loaded API key from Documents user_config.txt")
        } catch {
            print("DEBUG: UserConfig - No user_config.txt found in Documents: \(error)")
            // 尝试从其他来源加载
            loadFromFallbackSources()
        }
    }
    
    // MARK: - 备用加载方式
    private func loadFromFallbackSources() {
        // 1. 从环境变量加载
        if let envKey = ProcessInfo.processInfo.environment["OPENAI_API_KEY"], !envKey.isEmpty {
            openAIAPIKey = envKey
            print("DEBUG: UserConfig - Loaded from environment variable")
            return
        }
        
        // 2. 从 Info.plist 加载
        if let plistKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String, !plistKey.isEmpty {
            openAIAPIKey = plistKey
            print("DEBUG: UserConfig - Loaded from Info.plist")
            return
        }
        
        print("DEBUG: UserConfig - No API key found in any source")
    }
    
    // MARK: - 只读配置（不需要保存功能）
    
    // MARK: - 检查是否有 API Key
    func hasOpenAIAPIKey() -> Bool {
        return !openAIAPIKey.isEmpty
    }
    
    // MARK: - 获取 API Key
    func getOpenAIAPIKey() -> String {
        return openAIAPIKey
    }
}
