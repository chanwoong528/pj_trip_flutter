import Foundation

class EnvParser {
  static let shared = EnvParser()
  private var envDict: [String: String] = [:]
  
  private init() {}
  
  // .env 파일 로드
  func loadEnvFile() -> Bool {
    guard let path = Bundle.main.path(forResource: ".env", ofType: nil) else {
      print(".env 파일을 찾을 수 없습니다.")
      return false
    }
    
    do {
      let content = try String(contentsOfFile: path, encoding: .utf8)
      let lines = content.components(separatedBy: .newlines)
      
      for line in lines {
        let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 주석이나 빈 줄 건너뛰기
        if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
          continue
        }
        
        // KEY=VALUE 형식 파싱
        if trimmedLine.contains("=") {
          let components = trimmedLine.components(separatedBy: "=")
          if components.count >= 2 {
            let key = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let value = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
            
            if !key.isEmpty && !value.isEmpty {
              envDict[key] = value
            }
          }
        }
      }
      
      print("환경변수 로드 완료: \(envDict.keys.joined(separator: ", "))")
      return true
    } catch {
      print(".env 파일 읽기 오류: \(error)")
      return false
    }
  }
  
  // 특정 키의 값 가져오기
  func getValue(for key: String) -> String? {
    return envDict[key]
  }
  
  // 특정 키의 값 가져오기 (기본값 포함)
  func getValue(for key: String, defaultValue: String) -> String {
    return envDict[key] ?? defaultValue
  }
  
  // 모든 환경변수 출력 (디버깅용)
  func printAllEnvVars() {
    print("=== 환경변수 목록 ===")
    for (key, value) in envDict {
      print("\(key): \(value)")
    }
    print("===================")
  }
} 