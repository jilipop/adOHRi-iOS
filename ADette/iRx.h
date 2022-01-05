#ifndef iRx_h
#define iRx_h

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <netdb.h>
#include <string.h>
#include <opus/opus.h>
#include <ortp/ortp.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <pthread.h>

#include "constants.h"
#include "TPCircularBuffer.h"

void iRx_start(TPCircularBuffer *buffer);
void iRx_stop(void);

#endif /* iRx_h */
