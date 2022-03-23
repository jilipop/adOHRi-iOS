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

RtpSession *session;
OpusDecoder *decoder;
//JBParameters jbparams;

static void timestamp_jump(RtpSession *session, void *a, void *b, void *c) {
    printf("|\n");
    rtp_session_resync(session);
}

RtpSession* create_rtp_recv(const char *addr_desc, const int port, unsigned int jitter) {
    
    RtpSession *session;
    
    /* jbparams.enabled = TRUE;
    jbparams.adaptive = TRUE;
    jbparams.buffer_algorithm = OrtpJitterBufferBasic;
    jbparams.nom_size = jitter;
    jbparams.min_size = jitter;
    jbparams.max_size = 200;
    jbparams.max_packets = 10;
    jbparams.refresh_ms = 200; */
    
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

void log_stats() {
    printf("\n");
    printf("global rtp stats:\n");
    printf("received                             %llu packets\n", ortp_global_stats.packet_recv);
    printf("                                     %llu duplicated packets\n", ortp_global_stats.packet_dup_recv);
    printf("                                     %llu bytes\n", ortp_global_stats.hw_recv);
    printf("incoming delivered to the app        %llu bytes\n", ortp_global_stats.recv);
    printf("incoming cumulative lost             %llu packets\n", ortp_global_stats.cum_packet_loss);
    printf("incoming received too late           %llu packets\n", ortp_global_stats.outoftime);
    printf("incoming bad formatted               %llu packets\n", ortp_global_stats.bad);
    printf("incoming discarded (queue overflow)  %llu packets\n", ortp_global_stats.discarded);
}
