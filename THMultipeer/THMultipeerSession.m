//
//  THMultipeerSession.m
//  Num
//
//  Created by BuUuKeen on 13/8/14.
//  Copyright (c) 2014 Thkeen. All rights reserved.
//

#import "THMultipeerSession.h"

@interface THMultipeerSession()
@property (nonatomic, strong, readwrite) NSMutableArray *peers;
@end

@implementation THMultipeerSession

- (instancetype)initAsPeer:(MCPeerID*)localPeerID withSessionID:(NSString*)sessionID {
    self = [super init];
    if (self) {
        self.sessionID = sessionID;
        self.session = [[MCSession alloc] initWithPeer:localPeerID];
        self.session.delegate = self;
        self.type = THMultipeerSessionIsPeer;
    }
    return self;
}

- (instancetype)initAsHost:(MCPeerID*)localPeerID withPeers:(NSArray*)peers {
    self = [super init];
    if (self) {
        self.sessionID = [[NSUUID UUID] UUIDString];
        self.session = [[MCSession alloc] initWithPeer:localPeerID];
        self.session.delegate = self;
        self.type = THMultipeerSessionIsHost;
    }
    return self;
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
