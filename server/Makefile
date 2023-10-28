CC?=$(CROSS_COMPILE)"gcc"

default: aesdsocket;

all: aesdsocket ;

clean:
	rm aesdsocket &>/dev/null

aesdsocket: 
	$(CC) ${CFLAGS} ${INCLUDES} aesdsocket.c -o aesdsocket ${LIBS}