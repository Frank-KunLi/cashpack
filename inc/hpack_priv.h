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

enum hpack_type_e {
	HPACK_INDEXED	= 0x80, /* Section 6.1 */
	HPACK_DYNAMIC	= 0x40, /* Section 6.2.1 */
	HPACK_LITERAL	= 0x00, /* Section 6.2.2 */
	HPACK_NEVER	= 0x10, /* Section 6.2.3 */
	HPACK_UPDATE	= 0x20, /* Section 6.3 */
};

struct hpack {
	uint32_t	magic;
#define ENCODER_MAGIC	0x8ab1fb4c
#define DECODER_MAGIC	0xab0e3218
	size_t		max;
};

struct hpack_ctx {
	enum hpack_res_e	res;
	struct hpack		*hp;
	const uint8_t		*buf;
	size_t			len;
	hpack_decoded_f		*cb;
	void			*priv;
};

#define HPACK_CTX	struct hpack_ctx *ctx

#define EXPECT(ctx, err, cond)				\
	do {						\
		if (!(cond)) {				\
			(ctx)->res = HPACK_RES_##err;	\
			return (-1);			\
		}					\
	} while (0)

#define INCOMPL(ctx)	EXPECT(ctx, DEV, 0)
