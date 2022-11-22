#ifndef __RTMP_H__
#define __RTMP_H__
/*
 *      Copyright (C) 2005-2008 Team XBMC
 *      http://www.xbmc.org
 *      Copyright (C) 2008-2009 Andrej Stepanchuk
 *      Copyright (C) 2009-2010 Howard Chu
 *
 *  This file is part of librtmp.
 *
 *  librtmp is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as
 *  published by the Free Software Foundation; either version 2.1,
 *  or (at your option) any later version.
 *
 *  librtmp is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with librtmp see the file COPYING.  If not, write to
 *  the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA  02110-1301, USA.
 *  http://www.gnu.org/copyleft/lgpl.html
 */

#define NO_CRYPTO

#if !defined(NO_CRYPTO) && !defined(CRYPTO)
#define CRYPTO
#endif

#include <errno.h>
#include <stddef.h>
#include <stdint.h>

#include "amf.h"
#include "error.h"

#ifdef __cplusplus
extern "C" {
#endif

#define RTMP_LIB_VERSION 0x020300 /* 2.3 */

#define RTMP_FEATURE_HTTP 0x01
#define RTMP_FEATURE_ENC 0x02
#define RTMP_FEATURE_SSL 0x04
#define RTMP_FEATURE_MFP 0x08 /* not yet supported */
#define RTMP_FEATURE_WRITE 0x10 /* publish, not play */
#define RTMP_FEATURE_HTTP2 0x20 /* server-side rtmpt */

#define RTMP_PROTOCOL_UNDEFINED -1
#define RTMP_PROTOCOL_RTMP 0
#define RTMP_PROTOCOL_RTMPE RTMP_FEATURE_ENC
#define RTMP_PROTOCOL_RTMPT RTMP_FEATURE_HTTP
#define RTMP_PROTOCOL_RTMPS RTMP_FEATURE_SSL
#define RTMP_PROTOCOL_RTMPTE (RTMP_FEATURE_HTTP | RTMP_FEATURE_ENC)
#define RTMP_PROTOCOL_RTMPTS (RTMP_FEATURE_HTTP | RTMP_FEATURE_SSL)
#define RTMP_PROTOCOL_RTMFP RTMP_FEATURE_MFP

#define RTMP_DEFAULT_CHUNKSIZE 128

/* needs to fit largest number of bytes recv() may return */
#define RTMP_BUFFER_CACHE_SIZE (16 * 1024)

#define RTMP_CHANNELS 65600

extern const char PILI_RTMPProtocolStringsLower[][7];
extern const AVal PILI_RTMP_DefaultFlashVer;
extern int PILI_RTMP_ctrlC;

uint32_t PILI_RTMP_GetTime(void);

#define RTMP_PACKET_TYPE_AUDIO 0x08
#define RTMP_PACKET_TYPE_VIDEO 0x09
#define RTMP_PACKET_TYPE_INFO 0x12

#define RTMP_MAX_HEADER_SIZE 18     

// 下面四个值描述FLV数据中dataheader的大小
#define RTMP_PACKET_SIZE_LARGE 0
#define RTMP_PACKET_SIZE_MEDIUM 1
#define RTMP_PACKET_SIZE_SMALL 2
#define RTMP_PACKET_SIZE_MINIMUM 3

typedef struct PILI_RTMPChunk {
    int c_headerSize;
    int c_chunkSize;
    char *c_chunk;
    char c_header[RTMP_MAX_HEADER_SIZE];
} PILI_RTMPChunk;

typedef struct PILI_RTMPPacket {
    uint8_t m_headerType;   // 块头类型
    uint8_t m_packetType;   // 负载格式
    uint8_t m_hasAbsTimestamp; // 是否绝对时间戳
    int m_nChannel;     // 块流ID
    uint32_t m_nTimeStamp;   // 时间戳
    int32_t m_nInfoField2; // 块流ID
    uint32_t m_nBodySize;   // 负载大小
    uint32_t m_nBytesRead; // 读入负载大小
    PILI_RTMPChunk *m_chunk; // 在RTMP_ReadPacket()调用时，若该字段非NULL，表示关心原始块的信息，通常设为NULL
    char *m_body; // 负载指针
} PILI_RTMPPacket;

typedef struct PILI_RTMPSockBuf {
    int sb_socket;
    int sb_size; /* number of unprocessed bytes in buffer */
    char *sb_start; /* pointer into sb_pBuffer of next byte to process */
    char sb_buf[RTMP_BUFFER_CACHE_SIZE]; /* data read from socket */
    int sb_timedout;
    void *sb_ssl;
} PILI_RTMPSockBuf;

// 重置报文
void PILI_RTMPPacket_Reset(PILI_RTMPPacket *p);

void PILI_RTMPPacket_Dump(PILI_RTMPPacket *p);
// 为报文分配负载空间
int PILI_RTMPPacket_Alloc(PILI_RTMPPacket *p, int nSize);
// 释放负载空间
void PILI_RTMPPacket_Free(PILI_RTMPPacket *p);

// 检查报文是否可读，当报文被分块，且接收未完成时不可读
#define RTMPPacket_IsReady(a) ((a)->m_nBytesRead == (a)->m_nBodySize)

typedef struct PILI_RTMP_LNK {
    AVal hostname;
    AVal domain;
    AVal sockshost;

    AVal playpath0; /* parsed from URL */
    AVal playpath; /* passed in explicitly */
    AVal tcUrl;
    AVal swfUrl;
    AVal pageUrl;
    AVal app;
    AVal auth;
    AVal flashVer;
    AVal subscribepath;
    AVal token;
    AMFObject extras;
    int edepth;

    int seekTime;
    int stopTime;

#define RTMP_LF_AUTH 0x0001 /* using auth param */
#define RTMP_LF_LIVE 0x0002 /* stream is live */
#define RTMP_LF_SWFV 0x0004 /* do SWF verification */
#define RTMP_LF_PLST 0x0008 /* send playlist before play */
#define RTMP_LF_BUFX 0x0010 /* toggle stream on BufferEmpty msg */
#define RTMP_LF_FTCU 0x0020 /* free tcUrl on close */
    int lFlags;

    int swfAge;

    int protocol;
    int timeout; /* connection timeout in seconds */
    int send_timeout; /* send data timeout */

    unsigned short socksport;
    unsigned short port;

#ifdef CRYPTO
#define RTMP_SWF_HASHLEN 32
    void *dh; /* for encryption */
    void *rc4keyIn;
    void *rc4keyOut;

    uint32_t SWFSize;
    uint8_t SWFHash[RTMP_SWF_HASHLEN];
    char SWFVerificationResponse[RTMP_SWF_HASHLEN + 10];
#endif
} PILI_RTMP_LNK;

/* state for read() wrapper */
typedef struct PILI_RTMP_READ {
    char *buf;
    char *bufpos;
    unsigned int buflen;
    uint32_t timestamp;
    uint8_t dataType;
    uint8_t flags;
#define RTMP_READ_HEADER 0x01
#define RTMP_READ_RESUME 0x02
#define RTMP_READ_NO_IGNORE 0x04
#define RTMP_READ_GOTKF 0x08
#define RTMP_READ_GOTFLVK 0x10
#define RTMP_READ_SEEKING 0x20
    int8_t status;
#define RTMP_READ_COMPLETE -3
#define RTMP_READ_ERROR -2
#define RTMP_READ_EOF -1
#define RTMP_READ_IGNORE 0

    /* if bResume == TRUE */
    uint8_t initialFrameType;
    uint32_t nResumeTS;
    char *metaHeader;
    char *initialFrame;
    uint32_t nMetaHeaderSize;
    uint32_t nInitialFrameSize;
    uint32_t nIgnoredFrameCounter;
    uint32_t nIgnoredFlvFrameCounter;
} PILI_RTMP_READ;

typedef struct PILI_RTMP_METHOD {
    AVal name;
    int num;
} PILI_RTMP_METHOD;

typedef void (*PILI_RTMPErrorCallback)(RTMPError *error, void *userData);

typedef struct PILI_CONNECTION_TIME {
    uint32_t connect_time;
    uint32_t handshake_time;
} PILI_CONNECTION_TIME;

typedef void (*PILI_RTMP_ConnectionTimeCallback)(
    PILI_CONNECTION_TIME *conn_time, void *userData);

typedef struct PILI_RTMP {
    int m_inChunkSize;  // 最大接收块大小
    int m_outChunkSize;// 最大发送块大小
    int m_nBWCheckCounter;// 带宽检测计数器
    int m_nBytesIn;// 接收数据计数器
    int m_nBytesInSent;// 当前数据已回应计数器
    int m_nBufferMS;// 当前缓冲的时间长度，以MS为单位
    int m_stream_id; // 当前连接的流ID
    int m_mediaChannel;// 当前连接媒体使用的块流ID
    uint32_t m_mediaStamp;// 当前连接媒体最新的时间戳
    uint32_t m_pauseStamp;// 当前连接媒体暂停时的时间戳
    int m_pausing;// 是否暂停状态
    int m_nServerBW;// 服务器带宽
    int m_nClientBW;// 客户端带宽
    uint8_t m_nClientBW2;// 客户端带宽调节方式
    uint8_t m_bPlaying;// 当前是否推流或连接中
    uint8_t m_bSendEncoding;// 连接服务器时发送编码
    uint8_t m_bSendCounter;// 设置是否向服务器发送接收字节应答

    int m_numInvokes; // 0x14命令远程过程调用计数
    int m_numCalls;// 0x14命令远程过程请求队列数量
    PILI_RTMP_METHOD *m_methodCalls; // 远程过程调用请求队列

    PILI_RTMPPacket *m_vecChannelsIn[RTMP_CHANNELS];// 对应块流ID上一次接收的报文
    PILI_RTMPPacket *m_vecChannelsOut[RTMP_CHANNELS];// 对应块流ID上一次发送的报文
    int m_channelTimestamp[RTMP_CHANNELS]; // 对应块流ID媒体的最新时间戳

    double m_fAudioCodecs; // 音频编码器代码
    double m_fVideoCodecs; // 视频编码器代码
    double m_fEncoding; /* AMF0 or AMF3 */

    double m_fDuration; // 当前媒体的时长

    int m_msgCounter; // 使用HTTP协议发送请求的计数器
    int m_polling;// 使用HTTP协议接收消息主体时的位置
    int m_resplen;// 使用HTTP协议接收消息主体时的未读消息计数
    int m_unackd;// 使用HTTP协议处理时无响应的计数
    AVal m_clientID;// 使用HTTP协议处理时的身份ID

    PILI_RTMP_READ m_read;// RTMP_Read()操作的上下文
    PILI_RTMPPacket m_write;// RTMP_Write()操作使用的可复用报文对象
    PILI_RTMPSockBuf m_sb;// RTMP_ReadPacket()读包操作的上下文
    PILI_RTMP_LNK Link;// RTMP连接上下文

    PILI_RTMPErrorCallback m_errorCallback; // rtmp链接断开或者失败后的回调
    PILI_RTMP_ConnectionTimeCallback m_connCallback;    // 连接超时的回调
    RTMPError *m_error; //
    void *m_userData;
    int m_is_closing;
    int m_tcp_nodelay;
    uint32_t ip;
} PILI_RTMP;

// 解析流地址
int PILI_RTMP_ParseURL(const char *url, int *protocol, AVal *host,
                       unsigned int *port, AVal *playpath, AVal *app);

int PILI_RTMP_ParseURL2(const char *url, int *protocol, AVal *host,
                        unsigned int *port, AVal *playpath, AVal *app, AVal *domain);

void PILI_RTMP_ParsePlaypath(AVal *in, AVal *out);
// 连接前，设置服务器发送给客户端的媒体缓存时长
void PILI_RTMP_SetBufferMS(PILI_RTMP *r, int size);
// 连接后，更新服务器发送给客户端的媒体缓存时长
void PILI_RTMP_UpdateBufferMS(PILI_RTMP *r, RTMPError *error);

// 更新RTMP上下文中的相应选项
int PILI_RTMP_SetOpt(PILI_RTMP *r, const AVal *opt, AVal *arg,
                     RTMPError *error);
// 设置流地址
int PILI_RTMP_SetupURL(PILI_RTMP *r, const char *url, RTMPError *error);
// 设置RTMP上下文播放地址和相应选项，不关心的可以设为NULL
void PILI_RTMP_SetupStream(PILI_RTMP *r, int protocol, AVal *hostname,
                           unsigned int port, AVal *sockshost, AVal *playpath,
                           AVal *tcUrl, AVal *swfUrl, AVal *pageUrl, AVal *app,
                           AVal *auth, AVal *swfSHA256Hash, uint32_t swfSize,
                           AVal *flashVer, AVal *subscribepath, int dStart,
                           int dStop, int bLiveStream, long int timeout);
// 客户端连接及握手
int PILI_RTMP_Connect(PILI_RTMP *r, PILI_RTMPPacket *cp, RTMPError *error);
struct sockaddr;
int PILI_RTMP_Connect0(PILI_RTMP *r, struct addrinfo *ai, unsigned short port,
                       RTMPError *error);
int PILI_RTMP_Connect1(PILI_RTMP *r, PILI_RTMPPacket *cp, RTMPError *error);
// 服务端握手
int PILI_RTMP_Serve(PILI_RTMP *r, RTMPError *error);

// 接收一个报文
int PILI_RTMP_ReadPacket(PILI_RTMP *r, PILI_RTMPPacket *packet);
// 发送一个报文，queue为1表示当包类型为0x14时，将加入队列等待响应
int PILI_RTMP_SendPacket(PILI_RTMP *r, PILI_RTMPPacket *packet, int queue,
                         RTMPError *error);
// 直接发送块
int PILI_RTMP_SendChunk(PILI_RTMP *r, PILI_RTMPChunk *chunk, RTMPError *error);
// 检查网络是否连接
int PILI_RTMP_IsConnected(PILI_RTMP *r);
// 返回套接字
int PILI_RTMP_Socket(PILI_RTMP *r);
// 检查连接是否超时
int PILI_RTMP_IsTimedout(PILI_RTMP *r);
// 获取当前媒体的时长
double PILI_RTMP_GetDuration(PILI_RTMP *r);
// 暂停与播放切换控制
int PILI_RTMP_ToggleStream(PILI_RTMP *r, RTMPError *error);
// 连接流，并指定开始播放的位置
int PILI_RTMP_ConnectStream(PILI_RTMP *r, int seekTime, RTMPError *error);
// 重新创建流
int PILI_RTMP_ReconnectStream(PILI_RTMP *r, int seekTime, RTMPError *error);
// 删除当前流
void PILI_RTMP_DeleteStream(PILI_RTMP *r, RTMPError *error);
// 获取第一个媒体包
int PILI_RTMP_GetNextMediaPacket(PILI_RTMP *r, PILI_RTMPPacket *packet);
// 处理客户端的报文交互，即处理报文分派逻辑
int PILI_RTMP_ClientPacket(PILI_RTMP *r, PILI_RTMPPacket *packet);

// 初使化RTMP上下文，设默认值
void PILI_RTMP_Init(PILI_RTMP *r);
// 关闭RTMP上下文
void PILI_RTMP_Close(PILI_RTMP *r, RTMPError *error);
// 分配RTMP上下文
PILI_RTMP *PILI_RTMP_Alloc(void);
// 释放RTMP上下文
void PILI_RTMP_Free(PILI_RTMP *r);
// 开启客户端的RTMP写开关，用于推流
void PILI_RTMP_EnableWrite(PILI_RTMP *r);
// 返回RTMP的版本
int PILI_RTMP_LibVersion(void);
// 开启RTMP工作中断
void PILI_RTMP_UserInterrupt(void); /* user typed Ctrl-C */
// 发送0x04号命令的控制消息
int PILI_RTMP_SendCtrl(PILI_RTMP *r, short nType, unsigned int nObject,
                       unsigned int nTime, RTMPError *error);

/* caller probably doesn't know current timestamp, should
   * just use RTMP_Pause instead
   */
// 发送0x14号远程调用控制暂停
int PILI_RTMP_SendPause(PILI_RTMP *r, int DoPause, int dTime, RTMPError *error);
int PILI_RTMP_Pause(PILI_RTMP *r, int DoPause, RTMPError *error);
// 递归在一个对象中搜索指定的属性
int PILI_RTMP_FindFirstMatchingProperty(AMFObject *obj, const AVal *name,
                                        AMFObjectProperty *p);
// 底层套接口的网络读取、发送、关闭连接操作
int PILI_RTMPSockBuf_Fill(PILI_RTMPSockBuf *sb);
int PILI_RTMPSockBuf_Send(PILI_RTMPSockBuf *sb, const char *buf, int len);
int PILI_RTMPSockBuf_Close(PILI_RTMPSockBuf *sb);
// 发送建流操作
int PILI_RTMP_SendCreateStream(PILI_RTMP *r, RTMPError *error);
// 发送媒体时间定位操作
int PILI_RTMP_SendSeek(PILI_RTMP *r, int dTime, RTMPError *error);
// 发送设置服务器应答窗口大小操作
int PILI_RTMP_SendServerBW(PILI_RTMP *r, RTMPError *error);
// 发送设置服务器输出带宽操作
int PILI_RTMP_SendClientBW(PILI_RTMP *r, RTMPError *error);
// 删除0x14命令远程调用队列中的请求
void PILI_RTMP_DropRequest(PILI_RTMP *r, int i, int freeit);
// 读取FLV格式数据
int PILI_RTMP_Read(PILI_RTMP *r, char *buf, int size);
// 发送FLV格式数据
int PILI_RTMP_Write(PILI_RTMP *r, const char *buf, int size, RTMPError *error);

/* hashswf.c */
int PILI_RTMP_HashSWF(const char *url, unsigned int *size, unsigned char *hash,
                      int age);

#ifdef __cplusplus
};
#endif

#endif
