CC = gcc
CFLAGS = -Wall -g
TARGET = writer

# If CROSS_COMPILE is not specified,do nothing, else, use it as a prefic to the compiler.
ifeq ($(CROSS_COMPILE),)
else
	CC = $(CROSS_COMPILE)gcc
endif

.PHONY: all clean ..

all: $(TARGET)

$(TARGET): writer.o
	$(CC) $(CFLAGS) -o $(TARGET) writer.o

writer.o: writer.c
	$(CC) $(CFLAGS) -c writer.c

clean:
	rm -f $(TARGET) writer.o