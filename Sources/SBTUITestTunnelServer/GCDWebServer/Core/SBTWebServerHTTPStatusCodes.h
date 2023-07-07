/*
 Copyright (c) 2012-2019, Pierre-Olivier Latour
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 * The name of Pierre-Olivier Latour may not be used to endorse
 or promote products derived from this software without specific
 prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 DISCLAIMED. IN NO EVENT SHALL PIERRE-OLIVIER LATOUR BE LIABLE FOR ANY
 DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// http://www.w3.org/Protocols/rfc2616/rfc2616-sec10.html
// http://www.iana.org/assignments/http-status-codes/http-status-codes.xhtml

#import <Foundation/Foundation.h>

/**
 *  Convenience constants for "informational" HTTP status codes.
 */
typedef NS_ENUM(NSInteger, SBTWebServerInformationalHTTPStatusCode) {
  kSBTWebServerHTTPStatusCode_Continue = 100,
  kSBTWebServerHTTPStatusCode_SwitchingProtocols = 101,
  kSBTWebServerHTTPStatusCode_Processing = 102
};

/**
 *  Convenience constants for "successful" HTTP status codes.
 */
typedef NS_ENUM(NSInteger, SBTWebServerSuccessfulHTTPStatusCode) {
  kSBTWebServerHTTPStatusCode_OK = 200,
  kSBTWebServerHTTPStatusCode_Created = 201,
  kSBTWebServerHTTPStatusCode_Accepted = 202,
  kSBTWebServerHTTPStatusCode_NonAuthoritativeInformation = 203,
  kSBTWebServerHTTPStatusCode_NoContent = 204,
  kSBTWebServerHTTPStatusCode_ResetContent = 205,
  kSBTWebServerHTTPStatusCode_PartialContent = 206,
  kSBTWebServerHTTPStatusCode_MultiStatus = 207,
  kSBTWebServerHTTPStatusCode_AlreadyReported = 208
};

/**
 *  Convenience constants for "redirection" HTTP status codes.
 */
typedef NS_ENUM(NSInteger, SBTWebServerRedirectionHTTPStatusCode) {
  kSBTWebServerHTTPStatusCode_MultipleChoices = 300,
  kSBTWebServerHTTPStatusCode_MovedPermanently = 301,
  kSBTWebServerHTTPStatusCode_Found = 302,
  kSBTWebServerHTTPStatusCode_SeeOther = 303,
  kSBTWebServerHTTPStatusCode_NotModified = 304,
  kSBTWebServerHTTPStatusCode_UseProxy = 305,
  kSBTWebServerHTTPStatusCode_TemporaryRedirect = 307,
  kSBTWebServerHTTPStatusCode_PermanentRedirect = 308
};

/**
 *  Convenience constants for "client error" HTTP status codes.
 */
typedef NS_ENUM(NSInteger, SBTWebServerClientErrorHTTPStatusCode) {
  kSBTWebServerHTTPStatusCode_BadRequest = 400,
  kSBTWebServerHTTPStatusCode_Unauthorized = 401,
  kSBTWebServerHTTPStatusCode_PaymentRequired = 402,
  kSBTWebServerHTTPStatusCode_Forbidden = 403,
  kSBTWebServerHTTPStatusCode_NotFound = 404,
  kSBTWebServerHTTPStatusCode_MethodNotAllowed = 405,
  kSBTWebServerHTTPStatusCode_NotAcceptable = 406,
  kSBTWebServerHTTPStatusCode_ProxyAuthenticationRequired = 407,
  kSBTWebServerHTTPStatusCode_RequestTimeout = 408,
  kSBTWebServerHTTPStatusCode_Conflict = 409,
  kSBTWebServerHTTPStatusCode_Gone = 410,
  kSBTWebServerHTTPStatusCode_LengthRequired = 411,
  kSBTWebServerHTTPStatusCode_PreconditionFailed = 412,
  kSBTWebServerHTTPStatusCode_RequestEntityTooLarge = 413,
  kSBTWebServerHTTPStatusCode_RequestURITooLong = 414,
  kSBTWebServerHTTPStatusCode_UnsupportedMediaType = 415,
  kSBTWebServerHTTPStatusCode_RequestedRangeNotSatisfiable = 416,
  kSBTWebServerHTTPStatusCode_ExpectationFailed = 417,
  kSBTWebServerHTTPStatusCode_UnprocessableEntity = 422,
  kSBTWebServerHTTPStatusCode_Locked = 423,
  kSBTWebServerHTTPStatusCode_FailedDependency = 424,
  kSBTWebServerHTTPStatusCode_UpgradeRequired = 426,
  kSBTWebServerHTTPStatusCode_PreconditionRequired = 428,
  kSBTWebServerHTTPStatusCode_TooManyRequests = 429,
  kSBTWebServerHTTPStatusCode_RequestHeaderFieldsTooLarge = 431
};

/**
 *  Convenience constants for "server error" HTTP status codes.
 */
typedef NS_ENUM(NSInteger, SBTWebServerServerErrorHTTPStatusCode) {
  kSBTWebServerHTTPStatusCode_InternalServerError = 500,
  kSBTWebServerHTTPStatusCode_NotImplemented = 501,
  kSBTWebServerHTTPStatusCode_BadGateway = 502,
  kSBTWebServerHTTPStatusCode_ServiceUnavailable = 503,
  kSBTWebServerHTTPStatusCode_GatewayTimeout = 504,
  kSBTWebServerHTTPStatusCode_HTTPVersionNotSupported = 505,
  kSBTWebServerHTTPStatusCode_InsufficientStorage = 507,
  kSBTWebServerHTTPStatusCode_LoopDetected = 508,
  kSBTWebServerHTTPStatusCode_NotExtended = 510,
  kSBTWebServerHTTPStatusCode_NetworkAuthenticationRequired = 511
};
