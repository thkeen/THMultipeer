THMultipeer
===========
## Nearby connectivity library for iOS 7 (bluetooth or wifi)
THMultpeer is a wrapper on top of Apple iOS Multipeer Connectivity framework. It provides an easier way to create and manage sessions. It will save you time for handling disconnection and already has a mechanism to identify peers by setting displayName to be the device identifierForVendor (UUID String). Thus there will be no conflict if two devices having the same name.

## How to use
```objective-c
THMultipeer.me().serviceType = "thkeen-Num"
THMultipeer.me().info = ["model": UIDevice.currentDevice().model]
THMultipeer.me().broadcast()
```

## Delegate methods
```objective-c
/**
 *  New peer found, insert to UI
 *
 *  @param peer  MCPeerID
 *  @param name  Device name that was put during the advertisement
 *  @param info  Other info if any
 *  @param index Insert to the appropriate index in the UIwwd
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
```