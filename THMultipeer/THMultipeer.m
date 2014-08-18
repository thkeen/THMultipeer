//
//  THMultipeer.m
//  Num
//
//  Created by BuUuKeen on 13/8/14.
//  Copyright (c) 2014 Thkeen. All rights reserved.
//

#import "THMultipeer.h"
#import "THMultipeerSession.h"
#import "NSData+Helpers.h"

@interface THMultipeer () <MCNearbyServiceBrowserDelegate, MCNearbyServiceAdvertiserDelegate>
@property (nonatomic, strong, readwrite) NSMutableArray *peers; // readwrite
@property (nonatomic, strong, readwrite) NSMutableDictionary *peersForIdentifier; // keep this in sync with self.peers for performance
@property (nonatomic, strong, readwrite) NSMutableDictionary *peerInfos; // readwrite
@property (nonatomic, strong, readwrite) NSMutableArray *sessions; // readwrite
@property (nonatomic, strong, readwrite) NSMutableDictionary *sessionsForIdentifier; // keep this in sync with self.sessions for performance
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
        self.sessions = [NSMutableArray array];
        self.sessionsForIdentifier = [NSMutableDictionary dictionary];
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
        NSMutableDictionary *newInfo = [NSMutableDictionary dictionaryWithDictionary:info];
        [newInfo setObject:self.name forKey:@"name"];
        _info = newInfo;
    } else {
        NSAssert(YES, @"THMultipeer exception: Please stop broadcasting before setting info.");
    }
}

#pragma mark - Private methods

#pragma mark - Public methods

- (void)broadcast {
    if (self.serviceType.length > 0) {
        NSLog(@"startBroadcasting");
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.myPeerID discoveryInfo:self.info serviceType:self.serviceType];
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
    NSLog(@"stopBroadcasting");
    [self.browser stopBrowsingForPeers];
    [self.advertiser stopAdvertisingPeer];
    self.browser.delegate = nil;
    self.advertiser.delegate = nil;
    [self.peers removeAllObjects];
    [self.peersForIdentifier removeAllObjects];
    [self.peerInfos removeAllObjects]; // should I remove this?
    if ([self.delegate respondsToSelector:@selector(multipeerAllPeersRemoved)]) {
        [self.delegate multipeerAllPeersRemoved];
    }
    self.browser = nil;
    self.advertiser = nil;
}

- (void)sendInfo:(NSDictionary *)info toPeer:(MCPeerID *)peerID {
    [self.browser invitePeer:peerID toSession:[[MCSession alloc] initWithPeer:self.myPeerID] withContext:[NSData dataWithDictionary:@{@"type": @"info", @"info": info ? info : @{}}] timeout:10];
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
    return [self.peerInfos objectForKey:peerID.displayName];
}

- (NSInteger)indexOfPeer:(MCPeerID *)peerID {
    return [self.peers indexOfObject:peerID];
}

#pragma mark - MCNearbyServiceBrowserDelegate

// Found a nearby advertising peer
- (void)browser:(MCNearbyServiceBrowser *)browser foundPeer:(MCPeerID *)peerID withDiscoveryInfo:(NSDictionary *)info {
    NSLog(@"Found peer %@ with info: %@", peerID, info);
    if ([self.peersForIdentifier objectForKey:peerID.displayName]) {
        // this means this UUID was added before, somehow it appears again. Let's delete the old one and overwrite with this new one
        MCPeerID *existedPeerID = [self.peersForIdentifier objectForKey:peerID.displayName];
        [self.peers setObject:peerID atIndexedSubscript:[self.peers indexOfObject:existedPeerID]];
        [self.peersForIdentifier setObject:peerID forKey:peerID.displayName];
        [self.peerInfos setObject:(info ? info : @{}) forKey:peerID.displayName];
    } else {
        // new one added in and tell the delegate to update UI
        [self.peers insertObject:peerID atIndex:0];
        [self.peersForIdentifier setObject:peerID forKey:peerID.displayName];
        [self.peerInfos setObject:(info ? info : @{}) forKey:peerID.displayName];
        if ([self.delegate respondsToSelector:@selector(multipeerNewPeerFound:withName:andInfo:atIndex:)]) {
            [self.delegate multipeerNewPeerFound:peerID withName:[info objectForKey:@"name"] andInfo:info atIndex:0];
        }
    }
}

// A nearby peer has stopped advertising
- (void)browser:(MCNearbyServiceBrowser *)browser lostPeer:(MCPeerID *)peerID {
    NSLog(@"Lost peer %@", peerID);
    if ([self.peersForIdentifier objectForKey:peerID.displayName]) {
        MCPeerID *existedPeerID = [self.peersForIdentifier objectForKey:peerID.displayName];
        NSInteger index = [self.peers indexOfObject:existedPeerID];
        [self.peers removeObjectAtIndex:index];
        [self.peersForIdentifier removeObjectForKey:peerID.displayName];
        [self.peerInfos removeObjectForKey:peerID.displayName];
        if ([self.delegate respondsToSelector:@selector(multipeerPeerLost:atIndex:)]) {
            [self.delegate multipeerPeerLost:peerID atIndex:index];
        }
    }
}

// Browsing did not start due to an error
- (void)browser:(MCNearbyServiceBrowser *)browser didNotStartBrowsingForPeers:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(multipeerDidNotBroadcastWithError:)]) {
        [self.delegate multipeerDidNotBroadcastWithError:error];
    }
}

#pragma mark - MCNearbyServiceAdvertiserDelegate

// Incoming invitation request.  Call the invitationHandler block with YES and a valid session to connect the inviting peer to the session.
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didReceiveInvitationFromPeer:(MCPeerID *)peerID withContext:(NSData *)context invitationHandler:(void(^)(BOOL accept, MCSession *session))invitationHandler {
    NSDictionary *info = [NSData dictionaryFromData:context];
    NSLog(@"Did receive invitation from peer %@ with info: %@", peerID, info);
    if ([info objectForKey:@"type"] && [[info objectForKey:@"type"] isEqualToString:@"info"]) {
        // custom invitation, actually just a message. Just decline right away.
        if ([self.delegate respondsToSelector:@selector(multipeerDidReceiveInfo:fromPeer:)]) {
            [self.delegate multipeerDidReceiveInfo:[info objectForKey:@"info"] fromPeer:peerID];
        }
        invitationHandler(NO, nil); // no need to accept this, no point
    } else {
        // real invitation, create UUID for session here
        NSString *sessionID = [info objectForKey:@"sessionID"];
        if (sessionID.length > 0) {
            THMultipeerSession *session = [self.sessionsForIdentifier objectForKey:sessionID];
            if (!session) {
                // first time got the invitation. Otherwise it would've been already in the cache
                session = [[THMultipeerSession alloc] initWithInfo:info localPeer:self.myPeerID browser:self.browser];
                [self.sessionsForIdentifier setObject:session forKey:sessionID];
                [self.sessions insertObject:session atIndex:0];
                if ([self.delegate respondsToSelector:@selector(multipeerSessionPeerAdded:atIndex:)]) {
                    [self.delegate multipeerSessionAdded:session atIndex:0];
                }
            } else {
                // redundant invitation, what to do?
                
            }
        } else {
            NSLog(@"Session ID not found. Ignore invitation.");
        }
    }
}

// Advertising did not start due to an error
- (void)advertiser:(MCNearbyServiceAdvertiser *)advertiser didNotStartAdvertisingPeer:(NSError *)error {
    if ([self.delegate respondsToSelector:@selector(multipeerDidNotBroadcastWithError:)]) {
        [self.delegate multipeerDidNotBroadcastWithError:error];
    }
}

#pragma mark - NSNotificationCenter

- (void)applicationWillEnterForeground {
    [self broadcast];
}

- (void)applicationDidEnterBackground {
    [self stopBroadcasting];
}

@end
