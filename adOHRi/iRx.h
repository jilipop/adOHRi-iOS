#ifndef iRx_h
#define iRx_h

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <netdb.h>
#include <string.h>
#include <opus/opus.h>
#include <ortp/ortp.h>
#include <bctoolbox/logging.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <AudioToolbox/AudioToolbox.h>

#include "constants.h"

unsigned int rate = RATE,
            jitter = JITTER,
            channels = CHANNELS,
            framesize = FRAME_SIZE,
            port = PORT,
            referenceRate = PAYLOAD_0_REFERENCE_RATE;
const char *addr = ADDR;

void iRx_start(void);
int rx(AudioBufferList*);
void iRx_stop(void);

#endif /* iRx_h */
