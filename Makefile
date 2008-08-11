TESTS=		20080809
OLD=		${TESTS:S/$/.old/}
NEW=		${TESTS:S/$/.new/}
PATCHES=	${TESTS:S/$/.bsdiff/}
TARS=		${TESTS:S/$/.tbz/}
SIGS=		${TESTS:S/$/.tbz.sig/}
OUTPUTS=	${TESTS:S/$/.out/}
CP?=		cp
RM?=		rm -f
OPENSSL?=	openssl
BSDIFF?=	bsdiff
DIFF?=		diff -u
TAR?=		tar
PATCHADD?=	/usr/local/bin/patch_add
PATCHDEL?=	/usr/local/bin/patch_delete
SPOOLDIR?=	/var/spool/patches

OSABI!=		uname -s
OSVERS!=	uname -r
OSARCH!=	uname -m

.PHONY:	all test clean show-vars ${TESTS}

all:

test:	${OUTPUTS}

clean:
	${RM} ${OLD} ${NEW} ${OLD:S/$/.sig/} ${NEW:S/$/.sig/} ${PATCHES}
	${RM} ${TESTS} ${TARS} ${SIGS} ${OUTPUTS} +COMMENT +CONTENTS +INFO
	${RM} ${OUTPUTS:S/$/.new/}

show-vars:
	@echo "Tests: ${TESTS}"
	@echo "Old: ${OLD}"
	@echo "New: ${NEW}"

${OLD} ${NEW}:
	${CC} ${CFLAGS} -o ${.TARGET} ${.TARGET:S/$/.c/}
	${OPENSSL} smime -sign -binary -outform PEM -signer testkey.pem	\
		-in ${.TARGET} -out ${.TARGET:S/$/.sig/}

${PATCHES}: ${OLD} ${NEW}
	${BSDIFF} ${.TARGET:S/.bsdiff$/.old/} ${.TARGET:S/.bsdiff$/.new/} \
		${.TARGET}

${TARS}: ${PATCHES}
	echo ABI=${OSABI} > +INFO
	echo OS_VERSION=${OSVERS} >> +INFO
	echo MACHINE_ARCH=${OSARCH} >> +INFO
	echo PATCHTOOLS=0.1 >> +INFO
	echo NAME=${.TARGET:S/.tbz$//} >> +INFO
	echo "Test patch ${.TARGET:S/.tbz$//}" > +COMMENT
	echo "./${.TARGET:S/.tbz$//} ${.TARGET:S/.tbz$/.bsdiff/} `sha1 -n "${.TARGET:S/.tbz$/.old/}" | awk '{ print $$1 }'` `sha1 -n "${.TARGET:S/.tbz$/.new/}" | awk '{ print $$1 }'`" > +CONTENTS
	${TAR} cjvf ${.TARGET} +INFO +COMMENT +CONTENTS ${.TARGET:S/.tbz$/.bsdiff/}
	${RM} +INFO +COMMENT +CONTENTS

${SIGS}: ${TARS}
	${OPENSSL} smime -sign -binary -outform PEM -signer testkey.pem	\
		-in ${.TARGET:S/.sig$//} -out ${.TARGET}

${OUTPUTS}: ${TARS} ${SIGS}
	${CP} ${.TARGET:S/.out$/.old/} ${.TARGET:S/.out$//}
	${CP} ${.TARGET:S/.out$/.tbz/} ${.TARGET:S/.out$/.tbz.sig/} ${SPOOLDIR}
	./${.TARGET:S/.out$//} > ${.TARGET:S/$/.new/}
	${PATCHADD} ${.TARGET:S/.out$//}
	./${.TARGET:S/.out$//} >> ${.TARGET:S/$/.new/}
	${PATCHDEL} ${.TARGET:S/.out$//}
	./${.TARGET:S/.out$//} >> ${.TARGET:S/$/.new/}
	${DIFF} ${.TARGET:S/$/.new/} ${.TARGET:S/.out$/.txt/} &&	\
		${CP} ${.TARGET:S/$/.new/} ${.TARGET}
