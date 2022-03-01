/*
 * Copyright (C) 2020 Mark Hills <mark@xwax.org>
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * version 2, as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License version 2 for more details.
 *
 * You should have received a copy of the GNU General Public License
 * version 2 along with this program; if not, write to the Free
 * Software Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 *
 */

#include "iRx.h"

unsigned int rate = RATE,
            jitter = JITTER,
            channels = CHANNELS,
            port = PORT,
referenceRate = PAYLOAD_0_REFERENCE_RATE;
const char *addr = ADDR;

pthread_t thread_id;
bool isPlayRequested = false;
bool isInitialSilenceOver = false;

RtpSession *session;
OpusDecoder *decoder;
TPCircularBuffer *buffer;
JBParameters jbparams;

static void timestamp_jump(RtpSession *session, void *a, void *b, void *c) {
    printf("|\n");
    rtp_session_resync(session);
}

static RtpSession* create_rtp_recv(const char *addr_desc, const int port, unsigned int jitter) {
    
    RtpSession *session;
    
    jbparams.enabled = TRUE;
    jbparams.adaptive = TRUE;
    jbparams.buffer_algorithm = OrtpJitterBufferBasic;
    jbparams.nom_size = jitter;
    jbparams.min_size = jitter;
    jbparams.max_size = 200;
    jbparams.max_packets = 10;
    jbparams.refresh_ms = 200;
    
    session = rtp_session_new(RTP_SESSION_RECVONLY);
    rtp_session_set_scheduling_mode(session, TRUE);
    rtp_session_set_blocking_mode(session, TRUE);
    rtp_session_set_local_addr(session, addr_desc, port, -1);
    rtp_session_set_connected_mode(session, FALSE);
    
    rtp_session_enable_adaptive_jitter_compensation(session, TRUE);
    rtp_session_set_jitter_compensation(session, jitter);
    //rtp_session_set_jitter_buffer_params(session, &jbparams);
    
    rtp_session_set_time_jump_limit(session, jitter * 16); /* ms */
    if (rtp_session_set_payload_type(session, 0) != 0)
        abort();
    if (rtp_session_signal_connect(session, "timestamp_jump",
                    timestamp_jump, 0) != 0)
    {
        abort();
    }

    rtp_session_enable_rtcp(session, FALSE);

    return session;
}

static int play_one_frame(void *packet, opus_int32 len) {
    
    int numDecodedSamples;
    unsigned int samples = 1920;
    
    float pcm[sizeof(float) * samples * channels];
    if (packet == NULL) {
        numDecodedSamples = opus_decode_float(decoder, NULL, 0, pcm, samples, 1);
    } else {
        numDecodedSamples = opus_decode_float(decoder, packet, len, pcm, samples, 0);
    }
    if (numDecodedSamples < 0) {
        printf("opus_decode: %s\n", opus_strerror(numDecodedSamples));
        return -1;
    }
    
    uint32_t decodedBytes = numDecodedSamples * channels * sizeof(float);
    printf("decoded samples: %d\n", numDecodedSamples);
    printf("bytes decoded: %d\n", decodedBytes);
    
    if (isInitialSilenceOver == false && packet != NULL) {
        isInitialSilenceOver = true;
    }
    
    if (isInitialSilenceOver == true) {
        bool dataWritten = TPCircularBufferProduceBytes(buffer, pcm, decodedBytes);
        if (dataWritten == false) {
            printf("Error: Circular buffer overflow.\n");
        }
    }
    return numDecodedSamples;
}

static void *run_rx() {
    int timestamp = 0;
    
    while (isPlayRequested == true) {
        int numBytesReceived, have_more;
        char buf[32768];
        void *packet;

        numBytesReceived = rtp_session_recv_with_ts(session, (uint8_t*)buf,
                sizeof(buf), timestamp, &have_more);

        if (numBytesReceived == 0) {
            packet = NULL;
            printf("#\n");
        } else {
            packet = buf;
            printf(".\n");
        }
        int numDecodedSamples = play_one_frame(packet, numBytesReceived);
        if (numDecodedSamples == -1)
            printf("Error: numDecodedSamples is -1.\n");

        timestamp += numDecodedSamples * referenceRate / rate;
    }
    return NULL;
}

static void iRx_init() {
    int error;
    
    if (decoder == NULL) {
        decoder = opus_decoder_create(rate, channels, &error);
        if (decoder == NULL) {
            printf("opus_decoder_create: %s\n",
                opus_strerror(error));
            return;
        }
    }

    if (session == NULL) {
        ortp_set_log_level("iRx", 1);
        ortp_init();
        ortp_scheduler_init();
        session = create_rtp_recv(addr, port, jitter);
    }
}

void iRx_start(TPCircularBuffer *circularBuffer) {
    buffer = circularBuffer;
    iRx_init();
    isPlayRequested = true;
    pthread_create(&thread_id, NULL, run_rx, NULL);
}

void iRx_deinit() {
    if (session != NULL) {
        rtp_session_destroy(session);
        ortp_exit();
    }
    
    if (decoder != NULL) {
        opus_decoder_destroy(decoder);
    }
}

void iRx_stop() {
    isPlayRequested = false;
    isInitialSilenceOver = false;
    errno = 0;
    if (pthread_join(thread_id, NULL) != 0)
        printf("%s\n",strerror(errno));
}
