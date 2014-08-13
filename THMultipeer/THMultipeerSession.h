//
//  THMultipeerSession.h
//  Num
//
//  Created by BuUuKeen on 13/8/14.
//  Copyright (c) 2014 Thkeen. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>

typedef enum {
    THMultipeerSessionIsHost = 1,
    THMultipeerSessionIsPeer
} THMultipeerSessionType;

@protocol THMultipeerSessionDelegate <NSObject>

@end

@interface THMultipeerSession : NSObject <MCSessionDelegate>
/**
 *  UUID to make sure the session is identical, will create if this is a host. Otherwise take from other host.
 */
@property (nonatomic, strong) NSString *sessionID;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, strong, readonly) NSMutableArray *peers;
@property THMultipeerSessionType type;
@property (nonatomic, strong) id<THMultipeerSessionDelegate> delegate;

- (void)invitePeer:(MCPeerID*)peerID;
- (void)sendInfoToPeers:(NSDictionary*)info;
- (void)disconnect;

@end
