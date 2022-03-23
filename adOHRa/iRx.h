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

unsigned int rate = RATE,
            jitter = JITTER,
            channels = CHANNELS,
            port = PORT,
            referenceRate = PAYLOAD_0_REFERENCE_RATE;
const char *addr = ADDR;

RtpSession* create_rtp_recv(const char *addr_desc, const int port, unsigned int jitter);
void log_stats(void);

#endif /* iRx_h */
