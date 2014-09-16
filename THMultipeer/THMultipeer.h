//
//  THMultipeer.h
//  Num
//
//  Created by BuUuKeen on 13/8/14.
//  Copyright (c) 2014 Thkeen. All rights reserved.
//

#import <MultipeerConnectivity/MultipeerConnectivity.h>

@class THMultipeerSession;

@protocol THMultipeerDelegate <NSObject>

@optional
/**
 *  New peer found, insert to UI
 *
 *  @param peer  MCPeerID
 *  @param name  Device name that was put during the advertisement
 *  @param info  Other info if any
 *  @param index Insert to the appropriate index in the UI
 */
- (void)multipeerNewPeerFound:(MCPeerID*)peerID withName:(NSString*)name andInfo:(NSDictionary*)info atIndex:(NSInteger)index;
/**
 *  Lost a peer, remove from UI
 *
 *  @param peer  MCPeerID
 *  @param index Index to remove
 */
- (void)multipeerPeerLost:(MCPeerID*)peerID atIndex:(NSInteger)index;
/**
 *  All found peers were removed, update UI now
 */
- (void)multipeerAllPeersRemoved;
/**
 *  Could not advertising or browsing
 *
 *  @param error
 */
- (void)multipeerDidNotBroadcastWithError:(NSError*)error;
/**
 *  This is actually a wrapper on didReceiveInvitation but we make use of it as a protocol for sending simple message without having to accept the invitation.
 *
 *  @param info NSDictionary: invitation context
 *  @param peer MCPeerID
 */
- (void)multipeerDidReceiveInfo:(NSDictionary*)info fromPeer:(MCPeerID*)peerID;
- (void)multipeerSessionAdded:(THMultipeerSession*)session atIndex:(NSInteger)index;
- (void)multipeerSessionRemoved:(THMultipeerSession*)session atIndex:(NSInteger)index;
- (void)multipeerSession:(THMultipeerSession*)session didReceiveInfo:(NSDictionary*)info fromPeer:(MCPeerID*)peerID;
- (void)multipeerSession:(THMultipeerSession*)session peer:(MCPeerID*)peerID didChangeState:(MCSessionState)state;
@end

@interface THMultipeer : NSObject

+ (THMultipeer*)me;

@property (nonatomic, strong) id<THMultipeerDelegate> delegate;
@property (nonatomic, strong, readonly) NSMutableArray *peers;
@property (nonatomic, strong, readonly) NSMutableDictionary *peerInfos;
@property (nonatomic, strong, readonly) NSMutableArray *sessions;

/**
 *  The type of service to advertise. This should be a short text string that describes the app's networking protocol, in the same format as a Bonjour service type:
    - Must be 1–15 characters long
    - Can contain only ASCII lowercase letters, numbers, and hyphens.
    - This name should be easily distinguished from unrelated services. For example, a text chat app made by ABC company could use the service type abc-txtchat.
 */
@property (nonatomic, strong) NSString *serviceType;

/**
 *  Name of device that will be visible to others.
 *  By default is device name, if set to another will be saved in NSUserDefaults.
    Note: You must not set name after the device already broadcasts. Stop broadcasting first then set the name.
 */
@property (nonatomic, strong) NSString *name;

/**
 *  Whatever discovery information you want to inform other peers when advertising.
    Note: You must not set info after the device already broadcasts. Stop broadcasting first then set the info.
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
- (void)sendInfo:(NSDictionary*)info toPeer:(MCPeerID*)peerID;

/**
 *  Send a dictionary to all peers found without having to connect to the same session
 *
 *  @param info NSDictionary
 *  @param peer MCPeerID
 */
- (void)sendInfoToAllPeers:(NSDictionary*)info;
/**
 *  Get the display name of the peer
 *
 *  @param peer MCPeerID
 *
 *  @return NSString: Display name
 */
- (NSString*)nameForPeer:(MCPeerID*)peerID;
/**
 *  Get extra info of the peer (if any)
 *
 *  @param peer MCPeerID
 *
 *  @return NSDictionary
 */
- (NSDictionary*)infoForPeer:(MCPeerID*)peerID;
/**
 *  get index of peer in array
 *
 *  @param peerID MCPeerID
 *
 *  @return NSInteger
 */
- (NSInteger)indexOfPeer:(MCPeerID*)peerID;
/**
 *  Create a new special session which will never die unless user chooses to quit. Invite everyone in and the special session itself will maintain the connection for you
 *
 *  @param peers MCPeerID list of peers you want to invite
 *
 *  @return New Session
 */
//- (THMultipeerSession*)invitePeersToNewSession:(NSArray*)peers;

@end
