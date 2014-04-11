# OSMKit
OSMKit is helpful library for parsing and storing [OpenStreetMap](https://openstreetmpa.org) data in a [spatialite](http://www.gaia-gis.it/gaia-sins/) databse. OSMKit supports nodes, ways, relations, users and notes objects.

##How to Get Started

###Install
Add it to your Podfile.

```ruby 
pod
```

Then run `pod install`.

### Usage


####Parsing
```objective-c
OSMKTBXMLParser *xmlParser = [[OSMKTBXMLParser alloc] initWithDelegate:parserDelegate delegateQueue:nil];
[xmlParser parseXMLData:osmXMLData];
```

Then just implement the parser delegate protocol: `OSMKParserDelegateProtocol`

```objective-c
- (void)parserDidStart:(OSMKParser *)parser;
- (void)parser:(OSMKParser *)parser didFindNode:(OSMKNode *)node;
- (void)parser:(OSMKParser *)parser didFindWay:(OSMKWay *)way;
- (void)parser:(OSMKParser *)parser didFindRelation:(OSMKRelation *)relation;
- (void)parser:(OSMKParser *)parser didFindNote:(OSMKNote *)note;
- (void)parser:(OSMKParser *)parser didFindUser:(OSMKUser *)user;
- (void)parserDidFinish:(OSMKParser *)parser;
- (void)parser:(OSMKParser *)parser parseErrorOccurred:(NSError *)parseError;
```

####Parsing + Storage
```objective-c
OSMKSpatiaLiteStorage * spatiaLiteStorage = [[OSMKSpatiaLiteStorage alloc] initWithdatabaseFilePath:databasePath delegate:storageDelegate delegateQueue:nil];
[spatiaLiteStorage importXMLData:osmXMLData];
```

Then just implement the storage delegate protocol: `OSMKStorageDelegateProtocol`

```objective-c
- (void)storageDidStartImporting:(OSMKStorage *)storage;
- (void)storage:(OSMKStorage *)storage didSaveNodes:(NSArray *)nodes;
- (void)storage:(OSMKStorage *)storage didSaveWays:(NSArray *)ways;
- (void)storage:(OSMKStorage *)storage didSaveRelations:(NSArray *)relations;
- (void)storage:(OSMKStorage *)storage didSaveUsers:(NSArray *)users;
- (void)storage:(OSMKStorage *)storage didSaveNotes:(NSArray *)notes;
- (void)storageDidFinishImporting:(OSMKStorage *)storage;
```