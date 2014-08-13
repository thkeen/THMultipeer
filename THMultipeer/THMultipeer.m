//
//  THMultipeer.m
//  Num
//
//  Created by BuUuKeen on 13/8/14.
//  Copyright (c) 2014 Thkeen. All rights reserved.
//

#import "THMultipeer.h"
#import <MultipeerConnectivity/MultipeerConnectivity.h>

@interface NSData (Helpers)
+ (NSData*)dataWithDictionary:(NSDictionary*)dictionary;
+ (NSDictionary*)dictionaryFromData:(NSData*)data;
@end
@implementation NSData (Helpers)
+ (NSData *)dataWithDictionary:(NSDictionary *)dictionary {
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:dictionary forKey:@"dictionary"];
    [archiver finishEncoding];
    return data;
}
+ (NSDictionary *)dictionaryFromData:(NSData *)data {
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSDictionary *dictionary = [unarchiver decodeObjectForKey:@"dictionary"];
    [unarchiver finishDecoding];
    return dictionary;
}
@end

@interface THMultipeer () <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>
@property (nonatomic, strong, readwrite) NSMutableArray *peers; // readwrite
@property (nonatomic, strong, readwrite) NSMutableDictionary *peersForIdentifier; // keep this in sync with self.peers for performance
@property (nonatomic, strong, readwrite) NSMutableDictionary *peerInfos; // readwrite
@property (nonatomic, strong) MCPeerID *myPeerID;
@property (nonatomic, strong) MCNearbyServiceAdvertiser *advertiser;
@property (nonatomic, strong) MCNearbyServiceBrowser *browser;
@end

@implementation THMultipeer

@synthesize name = _name;

+ (THMultipeer*)me {
    static id singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [[self alloc] init];
    });
    return singleton;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.peers = [NSMutableArray array];
        self.peersForIdentifier = [NSMutableDictionary dictionary];
        self.peerInfos = [NSMutableDictionary dictionary];
        self.myPeerID = [[MCPeerID alloc] initWithDisplayName:[[[UIDevice currentDevice] identifierForVendor] UUIDString]]; // prefix will always be UUID
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Properties

- (NSString *)name {
    if (!_name) {
        _name = [[NSUserDefaults standardUserDefaults] objectForKey:@"multipeer_display_name"];
        if (!_name) {
            _name = [[UIDevice currentDevice] name]; // only happens first time, will use device name as default
            [[NSUserDefaults standardUserDefaults] setObject:_name forKey:@"multipeer_display_name"];
            [[NSUserDefaults standardUserDefaults] synchronize];
        }
    }
    return _name;
}
- (void)setName:(NSString *)name {
    // can only set name if not broadcasting
    if (!self.advertiser) {
        [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"multipeer_display_name"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        _name = name;
    } else {
        NSAssert(YES, @"THMultipeer exception: Please stop broadcasting before setting name.");
    }
}
- (void)setInfo:(NSDictionary *)info {
    // can only set info if not broadcasting
    if (!self.advertiser) {
        _info = info;
    } else {
        NSAssert(YES, @"THMultipeer exception: Please stop broadcasting before setting info.");
    }
}

#pragma mark - Private methods

#pragma mark - Public methods

- (void)broadcast {
    if (self.serviceType.length > 0) {
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.myPeerID discoveryInfo:@{@"name": self.name, @"info": self.info ? self.info : @{}} serviceType:self.serviceType];
        self.advertiser.delegate = self;
        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.myPeerID serviceType:self.serviceType];
        self.browser.delegate = self;
        [self.advertiser startAdvertisingPeer];
        [self.browser startBrowsingForPeers];
    } else {
        NSAssert(YES, @"THMultipeer exception: Service Type cannot be empty.");
    }
}

- (void)stopBroadcasting {
    [self.browser stopBrowsingForPeers];
    [self.advertiser stopAdvertisingPeer];
    [self.peers removeAllObjects];
    [self.peersForIdentifier removeAllObjects];
    [self.peerInfos removeAllObjects]; // should I remove this?
    [self.delegate multipeerAllPeersRemoved];
    self.browser = nil;
    self.advertiser = nil;
}

- (void)sendInfo:(NSDictionary *)info toPeer:(MCPeerID *)peerID {
    [self.browser invitePeer:peerID toSession:nil withContext:[NSData dataWithDictionary:info] timeout:10];
}

- (void)sendInfoToAllPeers:(NSDictionary *)info {
    for (MCPeerID *peer in self.peers) {
        [self sendInfo:info toPeer:peer];
    }
}

- (NSString *)nameForPeer:(MCPeerID *)peerID {
    return [[self.peerInfos objectForKey:peerID.displayName] objectForKey:@"name"];
}

- (NSDictionary *)infoForPeer:(MCPeerID *)peerID {
    return [[self.peerInfos objectForKey:peerID.displayName] objectForKey:@"info"];
}

#pragma mark - MCNearbyServiceBrowserDelegate

// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    if ([self.peersForIdentifier objectForKey:peerID.displayName]) {
        // this means this UUID was added before, somehow it appears again. Let's delete the old one and overwrite with this new one
        MCPeerID *existedPeerID = [self.peersForIdentifier objectForKey:peerID.displayName];
        [self.peers setObject:peerID atIndexedSubscript:[self.peers indexOfObject:existedPeerID]];
    } else {
        // new one added in and tell the delegate to update UI
        [self.peers insertObject:peerID atIndex:0];
        [self.delegate multipeerNewPeerFound:peerID withName:[info objectForKey:@"name"] andInfo:[info objectForKey:@"info"] atIndex:0];
    }
    [self.peersForIdentifier setObject:peerID forKey:peerID.displayName];
    if (info) {
        [self.peerInfos setObject:info forKey:peerID.displayName];
    }
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    if ([self.peersForIdentifier objectForKey:peerID.displayName]) {
        MCPeerID *existedPeerID = [self.peersForIdentifier objectForKey:peerID.displayName];
        [self.peers removeObjectAtIndex:[self.peers indexOfObject:existedPeerID]];
        [self.peersForIdentifier removeObjectForKey:peerID.displayName];
        [self.peerInfos removeObjectForKey:peerID.displayName];
    }
}

// Browsing did not start due to an error
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    [self.delegate multipeerDidNotBroadcastWithError:error];
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

// Incoming invitation request.  Call the invitationHandler block with YES and a valid session to connect the inviting peer to the session.
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler {
    [self.delegate multipeerDidReceiveInfo:[NSData dictionaryFromData:context] fromPeer:peerID];
}

// Advertising did not start due to an error
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    [self.delegate multipeerDidNotBroadcastWithError:error];
}

#pragma mark - NSNotificationCenter

- (void)applicationWillEnterForeground {
    [self broadcast];
}

- (void)applicationDidEnterBackground {
    [self stopBroadcasting];
}

@end
