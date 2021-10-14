//
//  DTXMeasurements.h
//  DTXObjectiveCHelpers
//
//  Created by Leo Natan (Wix) on 1/23/19.
//  Copyright © 2017-2020 Wix. All rights reserved.
//

#if DEBUG
    #ifndef ENABLE_UITUNNEL
        #define ENABLE_UITUNNEL 1
    #endif
#endif

#if ENABLE_UITUNNEL

#ifndef DTXMeasurements_h
#define DTXMeasurements_h

#define DTXStartTimeMeasurment() CFTimeInterval ___startTime = CACurrentMediaTime();

#define DTXEndTimeMeasurment(action) CFTimeInterval ___elapsedTime = CACurrentMediaTime() - ___startTime; \
dtx_log_info(@"%@ took %f seconds to " action, self.class, ___elapsedTime);

#endif /* DTXMeasurements_h */

#endif
