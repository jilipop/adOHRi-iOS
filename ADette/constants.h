#ifndef CONSTANTS_H
#define CONSTANTS_H

#define ADDR "::"
#define PORT 1350
#define JITTER 16
#define RATE 48000
#define CHANNELS 2
#define PAYLOAD_0_REFERENCE_RATE 8000
#define BUFFER_LENGTH 122880
#define PACKET_DURATION 40 /* in ms, defined by sender */
#define SAMPLES 1920 /* (PACKET_DURATION * RATE / 1000) */

#endif
