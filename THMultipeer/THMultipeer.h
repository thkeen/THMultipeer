//
//  THMultipeer.h
//  Num
//
//  Created by BuUuKeen on 13/8/14.
//  Copyright (c) 2014 Thkeen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class MCPeerID;

@protocol THMultipeerDelegate <NSObject>
/**
 *  Got an invitation from other peer
 *
 *  @param info NSDictionary: invitation context
 *  @param peer MCPeerID
 */
- (void)multipeerDidReceiveInfo:(NSDictionary*)info fromPeer:(MCPeerID*)peer;
/**
 *  All found peers were removed, update UI now
 */
- (void)multipeerAllPeersRemoved;
/**
 *  New peer found, insert to UI
 *
 *  @param peer  MCPeerID
 *  @param name  Device name that was put during the advertisement
 *  @param info  Other info if any
 *  @param index Insert to the appropriate index in the UI
 */
- (void)multipeerNewPeerFound:(MCPeerID*)peer withName:(NSString*)name andInfo:(NSDictionary*)info atIndex:(NSUInteger)index;
/**
 *  Lost a peer, remove from UI
 *
 *  @param peer  MCPeerID
 *  @param index Index to remove
 */
- (void)multipeerPeerLost:(MCPeerID*)peer atIndex:(NSUInteger)index;
/**
 *  Could not advertising or browsing
 *
 *  @param error
 */
- (void)multipeerDidNotBroadcastWithError:(NSError*)error;
@end

@interface THMultipeer : NSObject

+ (THMultipeer*)me;

@property (nonatomic, strong) id<THMultipeerDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableArray *peers;
@property (nonatomic, strong, readonly) NSMutableDictionary *peerInfos;

/**
 *  The type of service to advertise. This should be a short text string that describes the app's networking protocol, in the same format as a Bonjour service type:
    - Must be 1–15 characters long
    - Can contain only ASCII lowercase letters, numbers, and hyphens.
    - This name should be easily distinguished from unrelated services. For example, a text chat app made by ABC company could use the service type abc-txtchat.
 */
@property (nonatomic, strong) NSString *serviceType;

/**
 *  Name of device that will be visible to others.
 *  By default is device name, if set to another will be saved in NSUserDefaults
 */
@property (nonatomic, strong) NSString *name;

/**
 *  Whatever discovery information you want to inform other peers when advertising
 */
@property (nonatomic, strong) NSDictionary *info;

/**
 *  Start advertising self and browsing for other peers (always like this)
 */
- (void)broadcast;

/**
 *  Stop browsing and advertising, also clear all peers
 */
- (void)stopBroadcasting;

/**
 *  Send a dictionary to a peer without having to connect to the same session
 *
 *  @param info NSDictionary
 *  @param peer MCPeerID
 */
- (void)sendInfo:(NSDictionary*)info toPeer:(MCPeerID*)peer;

/**
 *  Send a dictionary to all peers found without having to connect to the same session
 *
 *  @param info NSDictionary
 *  @param peer MCPeerID
 */
- (void)sendInfoToAllPeers:(NSDictionary*)info;

@end
