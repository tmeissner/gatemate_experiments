#include <stdio.h>    /* Standard input/output definitions */
#include <stdlib.h> 
#include <stdint.h>   /* Standard types */
#include <string.h>   /* String function definitions */
#include <unistd.h>   /* UNIX standard function definitions */
#include <fcntl.h>    /* File control definitions */
#include <errno.h>    /* Error number definitions */
#include <termios.h>  /* POSIX terminal control definitions */
#include <sys/ioctl.h>


#ifdef __APPLE__
// define 460k baud rate, seems not to be available in headers on osx
#define B460800	460800
#endif


void help(void);
int serialport_init(const char* serialport, unsigned int baud);
int serialport_read_until(int fd, unsigned int until);


// Checks for an argument (characters with a leading '-')
// Returns 0 if argument does not exist or the index of argument
// type in the argv[] array
int parArgTypExists (int argc, char *argv[], char argType)
{
  char tmp[3];

  tmp[0] = '-';
  tmp[1] = argType;
  tmp[2] = 0;

  if (argc > 1) {
    for (int i = 1; i < argc; i++) {
      if (!strcmp (argv[i], tmp))
        return i;
    }
  }
  return 0;
}


// Get string argument value
// Returns 0 in error case, returns 1 if OK
// (string is limited to max. 4096 characters)
int parGetString (int argc, char *argv[], char argType, char *value)
{
  int a = parArgTypExists(argc, argv, argType);

  // Check for errors
  if (a == 0) return 0;
  if (a >= (argc -1)) return 0;
  if (strlen(argv[a+1]) > 256) return 0;

  strcpy(value, argv[a+1]);
  return 1;
}


// Get unsigned int argument value
// Returns 0 in error case, 1 if OK
int parGetUnsignedInt (int argc, char *argv[], char argType,
                        unsigned int *value)
{
  int a = parArgTypExists (argc, argv, argType);

  /* error checking */
  if (a == 0) return 0;
  if (a >= (argc -1)) return 0;

  a = sscanf(argv[a+1], "%iu", value);

  return a;
}


void help(void) {
    printf("Usage: uart_trng -p <serialport> [OPTIONS]\n"
    "\n"
    "Options:\n"
    "  -h, --help                   Print this help message\n"
    "  -p, --port=serialport        Serial port where the uart_trng device is plugged on\n"
    "  -b, --baud=baudrate          Baudrate (bps) of uart_trng device, default = 9600\n"
    "  -s, --size                   number of bytes to receive from uart_trng device,\n"
    "                               0 for reading until break with Ctrl-c, default = 1024\n"
    "\n");
}


int main(int argc, char *argv[]) 
{
    int fd = 0;
    int r = 0;
    char serialport[256];
    unsigned int baudrate = 9600;
    unsigned int size     = 1024;

  // check for command line arguments
  if (argc == 1) {
    help();
    return 1;
  }
  else {
    if (parArgTypExists (argc, argv, 'h')) {
      help();
      return 1;
    }
    // get serial port
    if (parArgTypExists (argc, argv, 'p')) {
      r = parGetString (argc, argv, 'p', serialport);
      if (r == 0) {
        return (1);
      }
    } else {
      help();
      return (1);
    }
    // get baud rate
    if (parArgTypExists (argc, argv, 'b')) {
      r = parGetUnsignedInt (argc, argv, 'b', &baudrate);
      if (r == 0) {
        return (1);
      }
    }
    // get read size in bytes
    if (parArgTypExists (argc, argv, 's')) {
      r = parGetUnsignedInt (argc, argv, 's', &size);
      if (r == 0) {
        return (1);
      }
    }
  }

  fd = serialport_init(serialport, baudrate);
  if (fd == -1)
    return -1;
  serialport_read_until(fd, size);

  exit(EXIT_SUCCESS);    
}


int serialport_read_until(int fd, unsigned int until)
{
    char b[1];
    int index = 0;
    int n;
    while (1) {
      while (1) {
        // read one char
        n = read(fd, b, 1);
        // we had a read error
        // check if there were no bytes to read or if it was a real error
        if (n == -1) {
          if (errno != EAGAIN) {
            fprintf(stderr,"serial read error at byte %d", index);
            return -1;
          }
        } else {
          break;
        }
      }
      // we got no byte, so wait 10 ms for the next try
      if (n == 0) {
        usleep (10 * 1000);
	continue;
      }
      printf("%c",b[0]);
      if (until == 0) {
	continue;
      } else {
	index++;
	if (index == until) {
	  break;
	}
      }
    };

  fprintf(stderr,"uart_trng: read %d random bytes from device\n", until);
  return 0;
}


// takes the string name of the serial port (e.g. "/dev/tty.usbserial","COM1")
// and a baud rate (bps) and connects to that port at that speed and 8N1.
// opens the port in fully raw mode so you can send binary data.
// returns valid fd, or -1 on error
int serialport_init(const char* serialport, unsigned int baud)
{
    struct termios toptions;
    int fd;
    
    fprintf(stderr,"init_serialport: opening port %s @ %u bps\n",
            serialport, baud);

    fd = open(serialport, O_RDWR | O_NOCTTY | O_NDELAY);
    if (fd == -1)  {
        perror("init_serialport: Unable to open port ");
        return -1;
    }
    
    if (tcgetattr(fd, &toptions) < 0) {
        perror("init_serialport: Couldn't get term attributes");
        return -1;
    }
    speed_t brate = baud; // let you override switch below if needed
    switch(baud) {
    case 4800:   brate=B4800;   break;
    case 9600:   brate=B9600;   break;
#ifdef B14400
    case 14400:  brate=B14400;  break;
#endif
    case 19200:  brate=B19200;  break;
#ifdef B28800
    case 28800:  brate=B28800;  break;
#endif
    case 38400:  brate=B38400;  break;
    case 57600:  brate=B57600;  break;
    case 115200: brate=B115200; break;
    case 230400: brate=B230400; break;
    case 460800: brate=B460800; break;
    }
    cfsetispeed(&toptions, brate);
    cfsetospeed(&toptions, brate);

    // 8N1
    toptions.c_cflag &= ~PARENB;
    toptions.c_cflag &= ~CSTOPB;
    toptions.c_cflag &= ~CSIZE;
    toptions.c_cflag |= CS8;
    // no flow control
    toptions.c_cflag &= ~CRTSCTS;

    toptions.c_cflag |= CREAD | CLOCAL;  // turn on READ & ignore ctrl lines
    toptions.c_iflag &= ~(IXON | IXOFF | IXANY); // turn off s/w flow ctrl

    toptions.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG); // make raw
    toptions.c_oflag &= ~OPOST; // make raw

    // see: http://unixwiz.net/techtips/termios-vmin-vtime.html
    toptions.c_cc[VMIN]  = 0;
    toptions.c_cc[VTIME] = 20;
    
    if( tcsetattr(fd, TCSANOW, &toptions) < 0) {
        perror("init_serialport: Couldn't set term attributes");
        return -1;
    }

    return fd;
}

