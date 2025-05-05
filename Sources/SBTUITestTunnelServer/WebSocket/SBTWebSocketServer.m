// SBTWebSocketServer.m
//
// Copyright (C) 2016 Subito.it S.r.l (www.subito.it)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "SBTWebSocketServer.h"

@interface SBTWebSocketServer ()

@property (nonatomic) nw_listener_t listener;
@property (nonatomic, strong) NSMutableArray<NSValue *> *clients;
@property (nonatomic, assign, readwrite) NSInteger port;

@end

@implementation SBTWebSocketServer

- (instancetype)initWithPort:(NSInteger)port
{
    self = [super init];
    if (self) {
        _port = port;
        _clients = [NSMutableArray array];
    }
    
    return self;
}

- (void)startWithError:(NSError **)error
{
    nw_parameters_t parameters = nw_parameters_create_secure_tcp(NW_PARAMETERS_DISABLE_PROTOCOL, NW_PARAMETERS_DEFAULT_CONFIGURATION);
    nw_parameters_set_reuse_local_address(parameters, true); // Allow re-binding to the same port quickly
    
    nw_protocol_options_t wsOptions = nw_ws_create_options(nw_ws_version_13);
    nw_ws_options_set_auto_reply_ping(wsOptions, true);
    
    nw_protocol_stack_t stack = nw_parameters_copy_default_protocol_stack(parameters);
    nw_protocol_stack_prepend_application_protocol(stack, wsOptions);
    
    const char *portCString = [[NSString stringWithFormat:@"%ld", self.port] UTF8String];
    nw_endpoint_t endpoint = nw_endpoint_create_host("127.0.0.1", portCString);
    nw_parameters_set_local_endpoint(parameters, endpoint);
    
    self.listener = nw_listener_create(parameters);
    if (!self.listener) {
        if (error) {
            *error = [NSError errorWithDomain:@"SBTWebsocketServer"
                                         code:-1
                                     userInfo:@{ NSLocalizedDescriptionKey: @"nw_listener_create failed" }];
        }
        
        return;
    }
    
    __weak typeof(self) weakSelf = self;
    
    nw_listener_set_new_connection_handler(self.listener, ^(nw_connection_t connection) {
        [weakSelf acceptConnection:connection];
    });
    
    nw_listener_set_queue(self.listener, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    nw_listener_start(self.listener);
    
    NSLog(@"SBTWebSocketServer started!");
}

- (void)acceptConnection:(nw_connection_t)connection
{
    [self.clients addObject:[NSValue valueWithPointer:(__bridge const void * _Nullable)(connection)]];
    
    __weak typeof(self) weakSelf = self;
    nw_connection_set_state_changed_handler(connection, ^(nw_connection_state_t state, nw_error_t  _Nullable err) {
        if (state == nw_connection_state_ready) {
            NSLog(@"[SBTUITestTunnel] SBTWebSocketServer client ready");
            
            [weakSelf sendStubbedResponse];
        } else if (state == nw_connection_state_failed) {
            NSLog(@"[SBTUITestTunnel] SBTWebSocketServer client failed: %@", err);
        } else if (state == nw_connection_state_cancelled) {
            NSLog(@"[SBTUITestTunnel] SBTWebSocketServer client cancelled");
        }
        
        if ([self.delegate respondsToSelector:@selector(webSocketServer:didChangeState:)]) {
            [self.delegate webSocketServer:self didChangeState:state];
        }
    });
    
    [self receiveOnConnection:connection];
    
    nw_connection_set_queue(connection, dispatch_get_main_queue());
    nw_connection_start(connection);
}

- (void)receiveOnConnection:(nw_connection_t)connection
{
    __weak typeof(self) weakSelf = self;
    
    // Ask for at least 1 byte, up to UINT32_MAX
    nw_connection_receive(connection,
                          1,
                          UINT32_MAX,
                          ^(dispatch_data_t content, nw_content_context_t context, bool is_complete, nw_error_t  _Nullable err) {
        if (content) {
            nw_protocol_definition_t wsDef = nw_protocol_copy_ws_definition();
            nw_protocol_metadata_t meta = nw_content_context_copy_protocol_metadata(context, wsDef);
            
            if (nw_protocol_metadata_is_ws(meta)) {
                nw_ws_opcode_t opcode = nw_ws_metadata_get_opcode(meta);

                __block NSMutableData *collected = [NSMutableData data];
                dispatch_data_apply(content, ^bool(dispatch_data_t region, size_t offset, const void *buffer, size_t size) {
                    [collected appendBytes:buffer length:size];
                    return true;
                });
                
                if (opcode == nw_ws_opcode_text) {
                    NSString *text = [[NSString alloc] initWithData:collected
                                                           encoding:NSUTF8StringEncoding];
                    NSLog(@"[SBTUITestTunnel] SBTWebSocketServer got text: %@", text);
                } else {
                    NSLog(@"[SBTUITestTunnel] SBTWebSocketServer got binary: %zu bytes", (size_t)collected.length);
                }
                                
                [weakSelf sendStubbedResponse];
            }
        }
        
        if (!err) {
            [weakSelf receiveOnConnection:connection];
        }
    });
}

- (void)sendStubbedResponse
{
    if (!self.stubResponseData) {
        return;
    }
    
    dispatch_data_t content = dispatch_data_create(self.stubResponseData.bytes,
                                                   self.stubResponseData.length,
                                                   dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0),
                                                   DISPATCH_DATA_DESTRUCTOR_DEFAULT);

    for (NSValue *val in self.clients) {
        nw_connection_t connection = (__bridge nw_connection_t)val.pointerValue;

        // Create a WebSocket text‐frame metadata (final fragment)
        nw_protocol_metadata_t metadata = nw_ws_create_metadata(nw_ws_opcode_text);

        nw_content_context_t context = nw_content_context_create("send-message");
        nw_content_context_set_metadata_for_protocol(context, metadata);
        
        // Send the data
        nw_connection_send(connection,
                           content,
                           context,
                           true,   // is_complete
                           ^(nw_error_t sendErr) {
            if (sendErr) {
                NSLog(@"[SBTUITestTunnel] SBTWebSocketServer send failed: %@", sendErr);
            }
        });
    }
}

@end
