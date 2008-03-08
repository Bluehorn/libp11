/* libp11, a simple layer on to of PKCS#11 API
 * Copyright (C) 2005 Olaf Kirch <okir@lst.de>
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free Software
 *  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307  USA
 */

/*
 * PKCS11 attribute querying.
 *
 * The number of layers we stack on top of each other here
 * is frightening.
 *
 * Copyright (C) 2002, Olaf Kirch <okir@lst.de>
 */

#include <assert.h>
#include <string.h>

#include "libp11-int.h"

static int pkcs11_getattr_int(PKCS11_CTX *, CK_SESSION_HANDLE,
			      CK_OBJECT_HANDLE, CK_ATTRIBUTE_TYPE, void *, size_t *);

/*
 * Query pkcs11 attributes
 */
static int
pkcs11_getattr_int(PKCS11_CTX * ctx, CK_SESSION_HANDLE session,
		   CK_OBJECT_HANDLE o, CK_ATTRIBUTE_TYPE type, void *value,
		   size_t * size)
{
	CK_ATTRIBUTE templ;
	int rv;

	templ.type = type;
	templ.pValue = value;
	templ.ulValueLen = *size;

	rv = CRYPTOKI_call(ctx, C_GetAttributeValue(session, o, &templ, 1));
	CRYPTOKI_checkerr(PKCS11_F_PKCS11_GETATTR, rv);

	*size = templ.ulValueLen;
	return 0;
}

int
pkcs11_getattr_var(PKCS11_TOKEN * token, CK_OBJECT_HANDLE object,
		   unsigned int type, void *value, size_t * size)
{
	return pkcs11_getattr_int(TOKEN2CTX(token),
				  PRIVSLOT(TOKEN2SLOT(token))->session,
				  object, type, value, size);
}

int
pkcs11_getattr(PKCS11_TOKEN * token, CK_OBJECT_HANDLE object,
	       unsigned int type, void *value, size_t size)
{
	return pkcs11_getattr_var(token, object, type, value, &size);
}

int
pkcs11_getattr_s(PKCS11_TOKEN * token, CK_OBJECT_HANDLE object,
		 unsigned int type, void *value, size_t size)
{
	memset(value, 0, size);
	return pkcs11_getattr_var(token, object, type, value, &size);
}

int
pkcs11_getattr_bn(PKCS11_TOKEN * token, CK_OBJECT_HANDLE object,
		  unsigned int type, BIGNUM ** bn)
{
	CK_BYTE binary[4196 / 8];
	size_t size = sizeof(binary);

	if (pkcs11_getattr_var(token, object, type, binary, &size))
		return -1;
	if (size == -1) {
		PKCS11err(PKCS11_F_PKCS11_GETATTR,
			  pkcs11_map_err(CKR_ATTRIBUTE_TYPE_INVALID));
		return -1;
	}
	*bn = BN_bin2bn(binary, size, *bn);
	return *bn ? 0 : -1;
}

/*
 * Add attributes to template
 */
void pkcs11_addattr(CK_ATTRIBUTE_PTR ap, int type, const void *data, size_t size)
{
	ap->type = type;
	ap->pValue = malloc(size);
	memcpy(ap->pValue, data, size);
	ap->ulValueLen = size;
}

/* In PKCS11, virtually every integer is a CK_ULONG */
void pkcs11_addattr_int(CK_ATTRIBUTE_PTR ap, int type, unsigned long value)
{
	CK_ULONG ulValue = value;

	pkcs11_addattr(ap, type, &ulValue, sizeof(ulValue));
}

void pkcs11_addattr_bool(CK_ATTRIBUTE_PTR ap, int type, int value)
{
	pkcs11_addattr(ap, type, &value, sizeof(CK_BBOOL));
}

void pkcs11_addattr_s(CK_ATTRIBUTE_PTR ap, int type, const char *s)
{
	pkcs11_addattr(ap, type, s, s ? strlen(s) : 0); // RFC2279 string an unpadded string of CK_UTF8CHARs with no null-termination
}

void pkcs11_addattr_bn(CK_ATTRIBUTE_PTR ap, int type, const BIGNUM * bn)
{
	unsigned char temp[1024];
	unsigned int n;

	assert(BN_num_bytes(bn) <= sizeof(temp));
	n = BN_bn2bin(bn, temp);
	pkcs11_addattr(ap, type, temp, n);
}

void pkcs11_addattr_obj(CK_ATTRIBUTE_PTR ap, int type, pkcs11_i2d_fn enc, void *obj)
{
	unsigned char *p;

	ap->type = type;
	ap->ulValueLen = enc(obj, NULL);
	ap->pValue = p = (unsigned char *) malloc(ap->ulValueLen);
	enc(obj, &p);
}

void pkcs11_zap_attrs(CK_ATTRIBUTE_PTR ap, unsigned int n)
{
	while (n--) {
		if (ap[n].pValue)
			free(ap[n].pValue);
	}
}
