TESTS=		20080809
OLD=		${TESTS:S/$/.old/}
NEW=		${TESTS:S/$/.new/}
RM?=		rm -f
OPENSSL=	openssl

all:

test:	${OLD} ${NEW}

clean:
	${RM} ${OLD} ${NEW}

show-vars:
	@echo "Tests: ${TESTS}"
	@echo "Old: ${OLD}"
	@echo "New: ${NEW}"

${OLD} ${NEW}:
	${CC} ${CFLAGS} -o ${.TARGET} ${.TARGET:S/$/.c/}
	${OPENSSL} smime -sign -binary -outform PEM -signer testkey.pem	\
		-in ${.TARGET} -out ${.TARGET:S/$/.sig/}
