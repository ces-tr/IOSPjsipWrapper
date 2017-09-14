//
//  Macros.h
//  ipjsua
//
//  Created by MacBook  on 8/24/17.
//  Copyright © 2017 Teluu. All rights reserved.
//

#ifndef Macros_h
#define Macros_h

#define AssetIdentifier(asset) \
^(NSInteger identifier) { \
switch (identifier) { \
case asset: \
default: \
return @#asset; \
} \
}(asset)

#endif /* Macros_h */
