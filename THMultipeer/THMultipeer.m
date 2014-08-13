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
    [[NSUserDefaults standardUserDefaults] setObject:name forKey:@"multipeer_display_name"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    _name = name;
}

- (void)broadcast {
    if (self.serviceType.length > 0) {
        self.advertiser = [[MCNearbyServiceAdvertiser alloc] initWithPeer:self.myPeerID discoveryInfo:@{@"name": self.name, @"info": self.info ? self.info : @{}} serviceType:self.serviceType];
        self.browser = [[MCNearbyServiceBrowser alloc] initWithPeer:self.myPeerID serviceType:self.serviceType];
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
    [self.delegate multipeerAllPeersRemoved];
}

- (void)sendInfo:(NSDictionary *)info toPeer:(MCPeerID *)peer {
    [self.browser invitePeer:peer toSession:nil withContext:[NSData dataWithDictionary:info] timeout:10];
}

- (void)sendInfoToAllPeers:(NSDictionary *)info {
    for (MCPeerID *peer in self.peers) {
        [self sendInfo:info toPeer:peer];
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
