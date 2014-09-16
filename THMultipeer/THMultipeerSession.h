//
//  THMultipeerSession.h
//  Num
//
//  Created by BuUuKeen on 13/8/14.
//  Copyright (c) 2014 Thkeen. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@protocol THMultipeerSessionDelegate <NSObject>
- (void)multipeerSessionPeerAdded:(MCPeerID*)peerID atIndex:(NSInteger)index;
- (void)multipeerSessionPeerRemoved:(MCPeerID*)peerID atIndex:(NSInteger)index;
- (void)multipeerSessionPeer:(MCPeerID*)peerID didChangeState:(MCSessionState)state;
@end

@interface THMultipeerSession : NSObject
/**
 *  UUID to make sure the session is identical, will create if this is a host. Otherwise take from other host.
 */
@property (nonatomic, strong, readonly) NSString *sessionID;
/**
 *  All the important information about this Session (must be there for every reconnect invitation)
 */
@property (nonatomic, strong, readonly) NSDictionary *info;
/**
 *  The original list of peers. This is important to the Host in order to reconnect.
 *  If the user is a peer, this doesn't make different much but just for display purpose only.
 */
@property (nonatomic, strong, readonly) NSMutableArray *peers;

/**
 *  Must be set before inviting any peer
 */
@property (nonatomic, strong) id<THMultipeerSessionDelegate> delegate;
/**
 *  The main browser
 */
@property (nonatomic, strong, readonly) MCNearbyServiceBrowser *browser; // must not be nil
/**
 *  
 */
@property BOOL isAccepted;

- (instancetype)init:(MCPeerID*)localPeerID browser:(MCNearbyServiceBrowser*)browser;
- (instancetype)initWithInfo:(NSDictionary*)info localPeer:(MCPeerID*)localPeerID browser:(MCNearbyServiceBrowser*)browser;

- (void)invitePeers:(NSArray*)peerIDs withInfo:(NSDictionary*)info;
- (void)sendInfoToPeers:(NSDictionary*)info;
- (void)disconnect;

@end
