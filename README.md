# OSMKit
OSMKit is helpful library for parsing and storing [OpenStreetMap](https://openstreetmpa.org) data in a [spatialite](http://www.gaia-gis.it/gaia-sins/) databse. OSMKit supports nodes, ways, relations, users and notes objects.

##How to Get Started

###Install
Add it to your Podfile.

```ruby
pod OSMKit
```

For Now you'll also have to add:
```ruby
pod "SpatialDBKit", :git => 'https://github.com/davidchiles/SpatialDBKit' , :branch => 'master'

pre_install do |installer_representation|
    path = Pathname(installer_representation.sandbox.pod_dir("spatialite"))+"src/spatialite/spatialite.c"

    text = File.read(path)
  	new_text = text.gsub(/#include <spatialite\/spatialite\.h>/, "#include <spatialite/spatialite/spatialite.h>")

  	File.open(path, "w") {|file| file.puts new_text }

end
```

Then run `pod install`.

### Usage


####Parsing
```objective-c
OSMKTBXMLParser *parser = [[OSMKTBXMLParser alloc] initWithData:data error:&error];
NSArray *nodes = [parser parseNodes];
NSArray *ways = [parser parseWays];
NSArray *relations = [parser parseRelations];
NSArray *users = [parser parseUsers];
NSArray *notes = [parser parseNotes];
```

####Parsing + Storage
```objective-c
OSMKImporter *importer = [[OSMKImporter alloc] init];
[importer setupDatbaseWithPath:path overwrite:YES];
[importer importXMLData:testObject.data
                     completion:^{
                         NSLog(@"all done");
                     }
                completionQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
```
