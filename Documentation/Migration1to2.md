# Migration from 1.x to 2.x

SBTUITestTunnel 2.0 introduces some breaking changes to the `SBTRequestMatch` class and to the stubbing methods declared in `SBTUITunneledApplication`.

Adapting to the new interface will result in a cleaner and frequently to a shorter code if you leverage `SBTStubResponse` default values.

## SBTRequestMatch changes

`SBTRequestMatch`'s class factory methods were replaced by standard initializers to better integrate with Swift syntax.

To update your code to the new syntax you can apply the following _find and replaces_:
`SBTRequestMatch.url(` -> `SBTRequestMatch(url:`
`SBTRequestMatch.query(` -> `SBTRequestMatch(query:`
`SBTRequestMatch.method(` -> `SBTRequestMatch(method:`

## SBTUITunneledApplication stubbing changes

A new class `SBTStubResponse` was introduced to encapsulates all the information of a stubbed response.

The interface of the stubbing method in `SBTUITunneledApplication` have been reduced to 2:

```    
func stubRequests(matching match: SBTRequestMatch, response: SBTStubResponse) -> String?
func stubRequests(matching match: SBTRequestMatch, response: SBTStubResponse, removeAfterIterations iterations: UInt) -> String?
```

The parameters (stub data, return code, headers, contentType, response time) that were previously in the various stubRequests method interfaces have been moved to the `SBTStubResponse` initializers. Find further reference [here](https://github.com/Subito-it/SBTUITestTunnel/blob/master/Documentation/Usage.md#sbtstubresponse).