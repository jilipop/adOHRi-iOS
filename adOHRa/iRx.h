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
#include <pthread.h>

#include "constants.h"
#include "TPCircularBuffer.h"

unsigned int rate = RATE,
            jitter = JITTER,
            channels = CHANNELS,
            port = PORT,
            framesize = FRAME_SIZE,
            referenceRate = PAYLOAD_0_REFERENCE_RATE;
const char *addr = ADDR;

void iRx_start(TPCircularBuffer *buffer);
void iRx_stop(void);
void iRx_deinit(void);

#endif /* iRx_h */
