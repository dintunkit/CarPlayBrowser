//
//  AdBlockRuleManager.swift
//  CarPlayBrowser
//
//  High-performance WebKit Content Blocker manager maintaining compiled
//  bytecode rules in WKContentRuleListStore. Provides in-memory caching
//  and fallback compilation for in-car web browsing.
//

import Foundation
import WebKit

public final class AdBlockRuleManager {

    // MARK: - Singleton
    public static let shared = AdBlockRuleManager()

    // MARK: - Constants
    public static let ruleListIdentifier = "CarPlayAdBlockerRuleList_v1"

    // MARK: - In-Memory Cache
    public private(set) var cachedRuleList: WKContentRuleList?
    private let lock = NSLock()
    private var isCompiling = false
    private var pendingCompletions: [(WKContentRuleList?) -> Void] = []

    // MARK: - Initialization
    private init() {}

    // MARK: - Public API

    /// Retrieves the cached compiled rule list, looks up on-disk store cache,
    /// or compiles from JSON definition if absent.
    ///
    /// - Parameter completion: Handler returning the compiled WKContentRuleList or nil.
    public func getOrCompileRuleList(completion: @escaping (WKContentRuleList?) -> Void) {
        lock.lock()
        // 1. Check in-memory cache first
        if let cached = cachedRuleList {
            lock.unlock()
            completion(cached)
            return
        }

        // If compilation is already in flight, queue completion handler
        if isCompiling {
            pendingCompletions.append(completion)
            lock.unlock()
            return
        }

        isCompiling = true
        pendingCompletions.append(completion)
        lock.unlock()

        let store = WKContentRuleListStore.default()

        // 2. Check on-disk store cache
        store?.lookUpContentRuleList(forIdentifier: Self.ruleListIdentifier) { [weak self] ruleList, error in
            guard let self = self else { return }

            if let ruleList = ruleList, error == nil {
                self.handleCompilationSuccess(ruleList)
                return
            }

            // 3. Fallback: Compile from raw JSON definition
            let jsonString = self.loadRulesJSONString()
            store?.compileContentRuleList(
                forIdentifier: Self.ruleListIdentifier,
                encodedContentRuleList: jsonString
            ) { compiledRuleList, compileError in
                if let error = compileError {
                    print("[AdBlockRuleManager] Rule compilation error: \(error.localizedDescription)")
                }

                if let compiled = compiledRuleList {
                    self.handleCompilationSuccess(compiled)
                } else {
                    self.handleCompilationFailure()
                }
            }
        }
    }

    /// Convenience method to compile rules and attach directly to WKWebViewConfiguration
    public func compileAndApplyRules(
        to configuration: WKWebViewConfiguration,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        getOrCompileRuleList { ruleList in
            DispatchQueue.main.async {
                if let ruleList = ruleList {
                    configuration.userContentController.add(ruleList)
                    completion(.success(()))
                } else {
                    let error = NSError(
                        domain: "com.carplaybrowser.adblock",
                        code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Failed to compile WKContentRuleList"]
                    )
                    completion(.failure(error))
                }
            }
        }
    }

    /// Resets in-memory cached rule list
    public func resetCache() {
        lock.lock()
        cachedRuleList = nil
        lock.unlock()
    }

    // MARK: - Private Helpers

    private func handleCompilationSuccess(_ ruleList: WKContentRuleList) {
        lock.lock()
        cachedRuleList = ruleList
        isCompiling = false
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        lock.unlock()

        for comp in completions {
            comp(ruleList)
        }
    }

    private func handleCompilationFailure() {
        lock.lock()
        isCompiling = false
        let completions = pendingCompletions
        pendingCompletions.removeAll()
        lock.unlock()

        for comp in completions {
            comp(nil)
        }
    }

    /// Loads adblock JSON string from bundle or file system, falling back to embedded string
    public func loadRulesJSONString() -> String {
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath

        let candidatePaths = [
            Bundle.main.path(forResource: "adblock_rules", ofType: "json"),
            "\(currentDir)/Resources/adblock_rules.json",
            "\(currentDir)/CarPlayBrowser/Browser/ContentFilter/Resources/adblock_rules.json",
            "\(currentDir)/../Resources/adblock_rules.json"
        ]

        for path in candidatePaths.compactMap({ $0 }) {
            if fileManager.fileExists(atPath: path),
               let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
               let str = String(data: data, encoding: .utf8),
               !str.isEmpty {
                return str
            }
        }

        return Self.embeddedDefaultRulesJSON
    }

    // MARK: - Embedded Default Rules JSON Fallback
    public static let embeddedDefaultRulesJSON: String = """
    [
      {
        "trigger": {
          "url-filter": "^https?://+([a-zA-Z0-9.-]+\\\\.)?doubleclick\\\\.net/",
          "resource-type": ["script", "image", "raw", "subdocument", "xmlhttprequest"]
        },
        "action": {
          "type": "block"
        }
      },
      {
        "trigger": {
          "url-filter": "^https?://+([a-zA-Z0-9.-]+\\\\.)?googlesyndication\\\\.com/"
        },
        "action": {
          "type": "block"
        }
      },
      {
        "trigger": {
          "url-filter": "^https?://+([a-zA-Z0-9.-]+\\\\.)?googleadservices\\\\.com/"
        },
        "action": {
          "type": "block"
        }
      },
      {
        "trigger": {
          "url-filter": "^https?://+([a-zA-Z0-9.-]+\\\\.)?adservice\\\\.google\\\\.com/"
        },
        "action": {
          "type": "block"
        }
      },
      {
        "trigger": {
          "url-filter": "^https?://+([a-zA-Z0-9.-]+\\\\.)?youtube\\\\.com/pagead/"
        },
        "action": {
          "type": "block"
        }
      },
      {
        "trigger": {
          "url-filter": "^https?://+([a-zA-Z0-9.-]+\\\\.)?youtube\\\\.com/api/stats/ads"
        },
        "action": {
          "type": "block"
        }
      },
      {
        "trigger": {
          "url-filter": "^https?://+([a-zA-Z0-9.-]+\\\\.)?youtube\\\\.com/ptracking"
        },
        "action": {
          "type": "block"
        }
      },
      {
        "trigger": {
          "url-filter": "^https?://+([a-zA-Z0-9.-]+\\\\.)?youtube\\\\.com/get_midroll_info"
        },
        "action": {
          "type": "block"
        }
      },
      {
        "trigger": {
          "url-filter": "^https?://+([a-zA-Z0-9.-]+\\\\.)?adnxs\\\\.com/"
        },
        "action": {
          "type": "block"
        }
      },
      {
        "trigger": {
          "url-filter": "^https?://+([a-zA-Z0-9.-]+\\\\.)?scorecardresearch\\\\.com/"
        },
        "action": {
          "type": "block"
        }
      },
      {
        "trigger": {
          "url-filter": "^https?://+([a-zA-Z0-9.-]+\\\\.)?amazon-adsystem\\\\.com/"
        },
        "action": {
          "type": "block"
        }
      },
      {
        "trigger": {
          "url-filter": ".*"
        },
        "action": {
          "type": "css-display-none",
          "selector": ".ytp-ad-overlay-container, .ytp-ad-overlay-slot, #player-ads, #masthead-ad, .ytp-ad-player-overlay, ytd-ad-slot-renderer, ytd-in-feed-ad-layout-renderer, ytd-banner-promo-renderer, ytd-promoted-sparkles-web-renderer, ytd-display-ad-renderer, ytm-promoted-sparkles-web-renderer, ytm-companion-ad-renderer, .sparkles-light-cta, .video-ads, .ytp-ad-module, .ytp-ad-player-overlay-layout"
        }
      }
    ]
    """
}
