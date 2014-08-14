//
//  THMultipeerSession.m
//  Num
//
//  Created by BuUuKeen on 13/8/14.
//  Copyright (c) 2014 Thkeen. All rights reserved.
//

#import "THMultipeerSession.h"
#import "NSData+Helpers.h"

@interface THMultipeerSession() <MCSessionDelegate>
@property (nonatomic, strong, readwrite) NSString *sessionID;
@property (nonatomic, strong, readwrite) NSMutableArray *peers;
@property (nonatomic, strong) MCSession *session;
@property (nonatomic, copy) void(^invitationHandler)(BOOL accept, MCSession *session);

- (instancetype)initWithLocalPeerID:(MCPeerID*)localPeerID browser:(MCNearbyServiceBrowser*)browser;
@end

@implementation THMultipeerSession

- (instancetype)initWithInfo:(NSDictionary*)info localPeer:(MCPeerID*)localPeerID browser:(MCNearbyServiceBrowser*)browser {
    self = [self initWithLocalPeerID:localPeerID browser:browser];
    if (self) {
        self.sessionID = [info objectForKey:@"sessionID"];
    }
    return self;
}

- (instancetype)init:(MCPeerID*)localPeerID browser:(MCNearbyServiceBrowser*)browser {
    self = [self initWithLocalPeerID:localPeerID browser:browser];
    if (self) {
        self.sessionID = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (instancetype)initWithLocalPeerID:(MCPeerID*)localPeerID browser:(MCNearbyServiceBrowser*)browser{
    self = [super init];
    if (self) {
        self.session = [[MCSession alloc] initWithPeer:localPeerID];
        self.session.delegate = self;
    }
    return self;
}

#pragma mark - Public methods

- (void)invitePeers:(NSArray *)peerIDs withInfo:(NSDictionary*)info {
    if (self.browser) {
        for (MCPeerID *peerID in peerIDs) {
            [self.browser invitePeer:peerID toSession:self.session withContext:[NSData dataWithDictionary:@{@"sessionID": self.sessionID, @"info": info ? info : @{}}] timeout:10];
        }
    } else {
        NSAssert(YES, @"THMultipeer Exception: Browser must not be nil in order to invite.");
    }
}

- (void)sendInfoToPeers:(NSDictionary *)info {
    NSError *error;
    [self.session sendData:[NSData dataWithDictionary:info] toPeers:self.peers withMode:MCSessionSendDataReliable error:&error];
    if (error) {
        NSLog(@"Error when sending info to peers: %@",error);
    }
}

- (void)disconnect {
    [self.session disconnect];
}

#pragma mark - MCSessionDelegate

// Remote peer changed state
- (void)session:(MCSession *)session peer:(MCPeerID *)peerID didChangeState:(MCSessionState)state {
    
}

// Received data from remote peer
- (void)session:(MCSession *)session didReceiveData:(NSData *)data fromPeer:(MCPeerID *)peerID {
    
}

// Received a byte stream from remote peer
- (void)session:(MCSession *)session didReceiveStream:(NSInputStream *)stream withName:(NSString *)streamName fromPeer:(MCPeerID *)peerID {
    
}

// Start receiving a resource from remote peer
- (void)session:(MCSession *)session didStartReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID withProgress:(NSProgress *)progress {
    
}

// Finished receiving a resource from remote peer and saved the content in a temporary location - the app is responsible for moving the file to a permanent location within its sandbox
- (void)session:(MCSession *)session didFinishReceivingResourceWithName:(NSString *)resourceName fromPeer:(MCPeerID *)peerID atURL:(NSURL *)localURL withError:(NSError *)error {
    
}

// Made first contact with peer and have identity information about the remote peer (certificate may be nil)
- (void)session:(MCSession *)session didReceiveCertificate:(NSArray *)certificate fromPeer:(MCPeerID *)peerID certificateHandler:(void(^)(BOOL accept))certificateHandler {
    certificateHandler(YES);
}

@end
