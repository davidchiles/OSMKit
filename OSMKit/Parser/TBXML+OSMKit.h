//
//  TBXML+OSMKit.h
//  Pods
//
//  Created by David Chiles on 12/11/14.
//
//

#import "TBXML.h"

@interface TBXML (OSMKit)

+ (NSDictionary *)osmk_attributesDictionaryWithElement:(TBXMLElement *)element;

+ (NSDictionary *)osmk_tagsDictioanryWithElement:(TBXMLElement *)element;

+ (NSArray *)osmk_wayNodesWithElement:(TBXMLElement *)element;

+ (NSArray *)osmk_relationMembersWithElement:(TBXMLElement *)element;

@end
