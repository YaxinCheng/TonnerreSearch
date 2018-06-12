# TonnerreSearch ![icon](https://user-images.githubusercontent.com/13768613/41316616-35a65846-6e69-11e8-8687-d9f3b31fc921.png)

## Intro

A complete file indexing and search toolkit. Based on Apple's [SearchKit](https://developer.apple.com/documentation/coreservices/search_kit) and [File System Events](https://developer.apple.com/documentation/coreservices/file_system_events), TonnerreSearch provides a complete and concise way to build a **File Search Engine**. 

TonnerreSearch provides pure Swift interface, with C code running underneath it (from SearchKit and File System Events). It is the best way to combine the concise APIs and efficiency.

## Platform

- macOS (with Swift version after 4.0)
  - Tested on High Sierra, should be working with Mojave

## Installation

- Manually
  - git clone this repo, and compile. Then add the compiled `TonnerreSearch.framework` to your project
- Carthage
  - In consideration...

## Features

- Support aggregated search with keywords: `AND`, `OR`, and wildcard `*` 
- Fast for indexing and search
- Complementary indexing with listening to File System Events
- Light weighted

## User Manual:

Import `TonnerreSearch` in a file

```swift
import TonnerreSearch
```
### Index Part

This part introduces the basic index interfaces, and things need to be warned

#### TonnerreIndex.swift

Following APIs are provided:

```swift
init(filePath: String, indexType: TonnerreIndexType, writable: Bool)
init(filePath: URL, indexType: TonnerreIndexType, writable: Bool)
func addDocument(atPath: String, additionalNote: String) throws -> Bool
func addDocument(atPath: URL, additionalNote: String) throws -> Bool
func removeDocument(atPath: String) -> Bool
func removeDocument(atPath: URL) -> Bool
func search(query: String, limit: Int, options: TonnerreSearchOptions..., timeLimit: Double) -> [URL]
```

When user firstly initialize an instance of `TonnerreIndex`, it creates an index file at the given `filePath`. If the path is missing, a fatal error will occur. The second time, with the same `filePath`, `TonnerreIndex` will be initialized with the existing index file, instead of write over the original one.

> Note: one index file cannot have more than 1 writable instance. Otherwise, it will crash

Only **writable** instances can `addDocument` or `removeDocument` from the index file, however, `TonnerreIndex` is thread-safe. The search behaviour would not interfere the adding/removing process.

#### TonnerreIndexOptions.swift

```swift
// Used during a search, one or more options may be selected
public enum TonnerreSearchOptions: SKSearchOptions {
    case defaultOption// Most default behaviour, space means AND, with relevance score
    case noRelevanceScore// Search without relevance score
    case spaceMeansOR// Space means OR instead of AND
    case findSimilar// Finds documents similar to the query, ignoring all search operators like AND OR
}
// A swifty wrapper for SKSearchOptions. For more details, see (https://developer.apple.com/documentation/coreservices/sksearchoptions)
```

```swift
// Used when creaing an index
public enum TonnerreIndexType {
  case nameOnly // index file only keeps file names as the contents
  case metadata // index file imports the content extractor from Spotlight, and keeps the document contents in the file
}
// Only one of them can be chosen
```

TonnerreIndexType.metadata uses the default spotlight extractor to read document contents, users have no control of how the content should be read or what should be read. 

> WARNING: Using metadata mode to load huge PDF files would consume a large amount of memory. Using autoreleasingpool to wrap up the addDocument function is a good choice.

#### TonnerreIndexError.swift

Throw out an error when the file to index does not exist

### File System Event Part

This part introduces the File System Event Monitoring

#### TonnerreFSDetector.swift

An efficient way to listen to file events in the File System

```swift
typealias event = (path: String, flags: [TonnerreFSEvent])
convenience init(pathes: String..., callback: @escaping ([event])->Void)
init(pathes: [String], callback: @escaping ([event])->Void)
func start()
func stop()
```

Really straightforward, users need to pass a few path and a callback function to initialize one instance of `TonnerreFSDetector`. Once the `start()` is called, the detector starts to work. Once events happen, the detector calls the callback function, with a list of events. 

`stop()` will stop the detection

#### TonnerreFSEvent.swift

```swift
enum TonnerreFSEvent {// Different types of File System Event
  case created       
  case removed       
  case inodeModified 
  case renamed       
  case modified      
  case finderModified
  case changeOwner   
  case XattrModified 
  case isFile        
  case isDirectory   
  case isSymlink     
  
  // Tear apart a UInt32 type of flags to an array of TonnerreFSEvent
  static func segregate(flag: UInt32) -> [TonnerreFSEvent]
}
```

## License

TonnerreSearch is released under the GPL license. See LICENSE for details.
