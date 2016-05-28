/*-
 * Copyright (c) 2016 Dridi Boukelmoune
 * All rights reserved.
 *
 * Author: Dridi Boukelmoune <dridi.boukelmoune@gmail.com>
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED.  IN NO EVENT SHALL AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

#define HPT_STATIC_MAX 61

/**********************************************************************
 * Data Structures
 */

enum hpack_pattern_e {
	HPACK_PAT_HUF	= 0x80, /* Section 5.2 */
	HPACK_PAT_RAW	= 0x00, /* Section 5.2 */
	HPACK_PAT_IDX	= 0x80, /* Section 6.1 */
	HPACK_PAT_DYN	= 0x40, /* Section 6.2.1 */
	HPACK_PAT_LIT	= 0x00, /* Section 6.2.2 */
	HPACK_PAT_NVR	= 0x10, /* Section 6.2.3 */
	HPACK_PAT_UPD	= 0x20, /* Section 6.3 */
};

enum hpack_stp_e {
	HPACK_STP_FLD_INT = 0,
	HPACK_STP_NAM_LEN = 1,
	HPACK_STP_NAM_STR = 2,
	HPACK_STP_VAL_LEN = 3,
	HPACK_STP_VAL_STR = 4,
};

struct hpt_field {
	char		*nam;
	char		*val;
	uint16_t	nam_sz;
	uint16_t	val_sz;
};

struct hpt_entry {
	uint32_t	magic;
#define HPT_ENTRY_MAGIC	0xe4582b39
	uint32_t	align; /* fill a hole on 64-bit systems */
	int64_t		pre_sz;
	uint16_t	nam_sz;
	uint16_t	val_sz;
	uint16_t	pad[5];
	/* NB: The last two bytes are never written nor read. They are here
	 * only to guarantee that this struct size is exactly 32 bytes, the
	 * per-entry overhead defined in RFC 7541 section 4.1.
	 */
	uint16_t	unused;
};

struct hpt_priv {
	struct hpack_ctx	*ctx;
	struct hpt_entry	*he;
	void			*wrt;
	unsigned		nam;
};

struct hpack_ctx {
	struct hpack		*hp;
	const uint8_t		*buf;
	uint8_t			*cur;
	size_t			len;
	size_t			max;
	size_t			ins;
	union {
		hpack_decoded_f	*dec;
		hpack_encoded_f	*enc;
		hpack_encoded_f	*cb; /* dirty covariance hack */
	};
	void			*priv;
	enum hpack_result_e	res;
	unsigned		can_upd;
};

struct hpack_size {
	/* NB: mem is the table size currently allocated. It may get out of
	 * sync with the maximum size in some cases. Like when the realloc
	 * function is omitted.
	 */
	size_t			mem;
	/* NB: max represents the maximum table size defined by the decoder,
	 * conveyed out of band with for example HTTP/2 settings. The lim
	 * field represents the soft limit chosen the encoder and it must not
	 * exceed the maximum.
	 *
	 * See RFC 7541 section 4.2. for the details.
	 */
	size_t			max;
	ssize_t			lim;
	/* NB: when the table limit is capped to a new value, it is stored in
	 * the cap field to be applied when the next header list is encoded.
	 */
	ssize_t			cap;
	/* NB: len is the current length of the dynamic table. */
	size_t			len;
	/* NB: When the size is updated out of band by the decoder, it must be
	 * signalled by the encoder in an HPACK block. However, this change is
	 * deferred until the encode acknowledges the change happening out of
	 * band. The decoder may also resize the table more than once in which
	 * case we keep track of the last (nxt) change and the smallest (min)
	 * one.
	 *
	 * A negative value is used when no update-after-resize is expected.
	 *
	 * See RFC 7541 section 4.2. for the details.
	 */
	ssize_t			nxt;
	ssize_t			min;
};

struct hpack_state {
	uint32_t			magic;
#define INT_STATE_MAGIC			0x494E5453
#define STR_STATE_MAGIC			0x53545253
#define HUF_STATE_MAGIC			0x48554653
	enum hpack_stp_e		stp;
	int				bsy;
	uint16_t			idx;
	uint8_t				typ;
	/* NB: the field below belongs to string decoding state but saves up
	 * to 8 bytes on structure packing if moved here.
	 */
	uint8_t				first;
	union {
		/* integer decoding state */
		struct {
			uint16_t	v;
			uint8_t		m;
		};
		/* string decoding state */
		struct {
			uint64_t	bits;
			uint32_t	cod;
			uint16_t	len;
			uint8_t		pos;
			uint8_t		blen;
		};
	};
};

struct hpack {
	uint32_t		magic;
#define ENCODER_MAGIC		0x8ab1fb4c
#define DECODER_MAGIC		0xab0e3218
#define DEFUNCT_MAGIC		0xdffadae9
	struct hpack_alloc	alloc;
	struct hpack_size	sz;
	struct hpack_state	state;
	/* NB: cnt is the entries counter. */
	size_t			cnt;
	/* NB: off keep tracks of the table offset when an entry is inserted
	 * and the whole table is moved in a FIFO fashion.
	 */
	ptrdiff_t		off;
	/* NB: Decoding is inherently stateful, so the context might as well
	 * be part of the whole data structure. It is still a separate data
	 * structure because it is possible to chain contexts.
	 */
	struct hpack_ctx	ctx;
	/* NB: This is where the dynamic table starts, it's not actually part
	 * of this structure.
	 */
	struct hpt_entry	tbl[0];
};

typedef int hpack_validate_f(struct hpack_ctx*, const char *, size_t, unsigned);

/**********************************************************************
 * Utility Macros
 */

#define TRUST_ME(ptr)	((void *)(uintptr_t)(ptr))

#define HPACK_CTX	struct hpack_ctx *ctx
#define HPACK_FLD	const struct hpack_field *fld

#define HPACK_LIMIT(hp) \
	(((hp)->sz.lim >= 0 ? (size_t)(hp)->sz.lim : (hp)->sz.max))

#define CALL(func, args...)				\
	do {						\
		if ((func)(args) != 0)			\
			return (-1);			\
	} while (0)

#define CALLBACK(ctx, args...)				\
	do {						\
		(ctx)->cb((ctx)->priv, args);		\
	} while (0)

#define EXPECT(ctx, err, cond)				\
	do {						\
		if (!(cond)) {				\
			(ctx)->res = HPACK_RES_##err;	\
			return (HPACK_RES_##err);	\
		}					\
	} while (0)

/**********************************************************************
 * Function Signatures
 */

void HPE_push(HPACK_CTX, const void *, size_t);
void HPE_send(HPACK_CTX);

int  HPI_decode(HPACK_CTX, size_t, uint16_t *);
void HPI_encode(HPACK_CTX, size_t, uint8_t, uint16_t);

int  HPH_decode(HPACK_CTX, enum hpack_event_e, size_t);
void HPH_encode(HPACK_CTX, const char *);
void HPH_size(const char *, size_t *);

hpack_validate_f HPV_token;
hpack_validate_f HPV_value;

hpack_decoded_f HPT_insert;
void HPT_adjust(struct hpack_ctx *, size_t);
int  HPT_search(HPACK_CTX, size_t, struct hpt_field *);
void HPT_foreach(HPACK_CTX);
int  HPT_decode(HPACK_CTX, size_t);
int  HPT_decode_name(HPACK_CTX);
