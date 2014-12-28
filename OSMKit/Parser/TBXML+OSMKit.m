//
//  TBXML+OSMKit.m
//  Pods
//
//  Created by David Chiles on 12/11/14.
//
//

#import "TBXML+OSMKit.h"
#import "OSMKConstants.h"
#import "OSMKRelationMember.h"

@implementation TBXML (OSMKit)

+ (NSDictionary *)osmk_attributesDictionaryWithElement:(TBXMLElement *)element
{
    NSMutableDictionary *elementDict = [[NSMutableDictionary alloc] init];
    
    TBXMLAttribute *attribute = element->firstAttribute;
    while (attribute) {
        [elementDict setObject:[TBXML attributeValue:attribute] forKey:[TBXML attributeName:attribute]];
        attribute = attribute->next;
    }
    return elementDict;
}

+ (NSDictionary *)osmk_tagsDictioanryWithElement:(TBXMLElement *)element
{
    TBXMLElement* tagElement = [TBXML childElementNamed:@"tag" parentElement:element];
    NSMutableDictionary * dictionary = [NSMutableDictionary dictionary];
    
    while (tagElement)
    {
        NSString* key = [TBXML valueOfAttributeNamed:@"k" forElement:tagElement];
        NSString* value = [TBXML valueOfAttributeNamed:@"v" forElement:tagElement];
        
        [dictionary setObject:value forKey:key];
        tagElement = [TBXML nextSiblingNamed:@"tag" searchFromElement:tagElement];
    }
    
    return dictionary;
}

+ (NSArray *)osmk_wayNodesWithElement:(TBXMLElement *)element
{
    TBXMLElement *ndElement = [TBXML childElementNamed:@"nd" parentElement:element];
    NSMutableArray *mutableArray = [NSMutableArray array];
    
    while (ndElement) {
        
        NSNumber *ref = @([[TBXML valueOfAttributeNamed:@"ref" forElement:ndElement] longLongValue]);
        [mutableArray addObject:ref];
        
        
        ndElement = [TBXML nextSiblingNamed:@"nd" searchFromElement:ndElement];
    }
    return mutableArray;
}

+ (NSArray *)osmk_relationMembersWithElement:(TBXMLElement *)element
{
    TBXMLElement *memberElement = [TBXML childElementNamed:OSMKRelationMemberElementName parentElement:element];
    NSMutableArray *mutableArray = [NSMutableArray array];
    
    while (memberElement) {
        OSMKRelationMember *member = [[OSMKRelationMember alloc] initWithAttributesDictionary:[self osmk_attributesDictionaryWithElement:memberElement]];
        if (member) {
            [mutableArray addObject:member];
        }
        memberElement = [TBXML nextSiblingNamed:OSMKRelationMemberElementName searchFromElement:memberElement];
    }
    return mutableArray;
}

@end
