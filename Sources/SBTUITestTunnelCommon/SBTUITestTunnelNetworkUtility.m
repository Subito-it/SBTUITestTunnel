// SBTUITestTunnelNetworkUtility.m
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

#import "include/SBTUITestTunnelNetworkUtility.h"
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <netdb.h>

@implementation SBTUITestTunnelNetworkUtility

+ (NSInteger)reserveSocketPort
{
    // Unexpectedly this is binding on ports out of the IPPORT_RESERVED < port < IPPORT_USERRESERVED
    // A lame workaround is to simply try again
    for (int retry = 0; retry < 50; retry++) {
        struct sockaddr_in addr;
        socklen_t len = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_port = 0;
        inet_aton("0.0.0.0", &addr.sin_addr);
        int server_sock = socket(AF_INET, SOCK_STREAM, 0);
        if (server_sock < 0) {
            return -1;
        }
        if (bind(server_sock, (struct sockaddr *)&addr, sizeof(addr)) != 0) {
            close(server_sock);
            return -2;
        }
        if (getsockname(server_sock, (struct sockaddr *)&addr, &len) != 0) {
            close(server_sock);
            return -3;
        }

        in_port_t port = addr.sin_port;

        if (port <= 1023) {
            close(server_sock);
            NSLog(@"[SBTUITestTunnel] Invalid port assigned, trying again");
            continue;
        }

        // Attempt to reserve the port by putting it in TIME_WAIT state. During this
        // time, the system prevents other applications from binding to the same
        // port, to prevent packets meant for the recently closed connection from
        // being misdirected to the new application. Since SBTWebServer is utilizing
        // SO_REUSEADDR on the server socket, we can bind to the port even though
        // it's in TIME_WAIT state, effectively reserving it for our own use until
        // we close the server socket.
        if (listen(server_sock, 1)) {
            close(server_sock);
            return -4;
        }

        int client_sock = socket(AF_INET, SOCK_STREAM, 0);
        if (client_sock < 0) {
            close(server_sock);
            return -5;
        }

        if (connect(client_sock, (struct sockaddr *)&addr, sizeof(addr))) {
            close(server_sock);
            close(client_sock);
            return -6;
        }

        int accept_sock = accept(server_sock, nil, nil);
        if (accept_sock < 0) {
            close(server_sock);
            close(client_sock);
            return -7;
        }

        close(server_sock);
        close(client_sock);
        close(accept_sock);

        return port;
    }

    return -8;
}

@end
