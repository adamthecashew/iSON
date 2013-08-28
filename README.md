iSON
====

GSON for objective-c (or as close as it can be).
I tried to make this function as similar as possible to GSON.  Reason? GSON is amazing and once you don't have to create your own
objects from JSON you'll never want to again.

Currently serializes NSObjects into a JSON string and will deserialize back into NSObjects.

Not working with unnamed JSON Array's (yet).

You must call iSON registerObjectByPropertyName:forClass for all NSArray's inside of your objects that you want to deserialize.
Sadly objective-c has no type casting of arrays which is why this partial mapping is required.

objectToJSON: will serialize any object into a JSON NSString

objectFromJSON:forClass will deserialize your JSON String to an NSObject.  You must specify the class of this object
for it to deserialize correctly. (THIS METHOD WILL NOT WORK WITH UNNAMED JSON ARRAY'S)


