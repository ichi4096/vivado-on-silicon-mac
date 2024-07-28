#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <time.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/tcp.h>
#include <netinet/in.h>
#include <ifaddrs.h>

#include "io_ftdi.h"


#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

// Maximum input vector size in bytes. TMS and TDI byte size combined.
//
// Only tested with 4232H FTDI device which has a 2048 FIFO size. Not
// sure but this may need to be reduced for older devices with smaller
// FIFO sizes. It should not matter but try different values here if
// cannot get Xilinx device to successfully reprogram.
//
// NOTE: Did test this with the value 4096 with a FT4232H device and
// the Xilinx device failed to program.
#define VECTOR_IN_SZ 2048

static int jtag_state;
static int vlevel = 0;

//
// JTAG state machine.
//

enum
{
	test_logic_reset, run_test_idle,

	select_dr_scan, capture_dr, shift_dr,
	exit1_dr, pause_dr, exit2_dr, update_dr,

	select_ir_scan, capture_ir, shift_ir,
	exit1_ir, pause_ir, exit2_ir, update_ir,

	num_states
};

static int jtag_step(int state, int tms)
{
	static const int next_state[num_states][2] =
	{
		[test_logic_reset] = {run_test_idle, test_logic_reset},
		[run_test_idle] = {run_test_idle, select_dr_scan},

		[select_dr_scan] = {capture_dr, select_ir_scan},
		[capture_dr] = {shift_dr, exit1_dr},
		[shift_dr] = {shift_dr, exit1_dr},
		[exit1_dr] = {pause_dr, update_dr},
		[pause_dr] = {pause_dr, exit2_dr},
		[exit2_dr] = {shift_dr, update_dr},
		[update_dr] = {run_test_idle, select_dr_scan},

		[select_ir_scan] = {capture_ir, test_logic_reset},
		[capture_ir] = {shift_ir, exit1_ir},
		[shift_ir] = {shift_ir, exit1_ir},
		[exit1_ir] = {pause_ir, update_ir},
		[pause_ir] = {pause_ir, exit2_ir},
		[exit2_ir] = {shift_ir, update_ir},
		[update_ir] = {run_test_idle, select_dr_scan}
	};

	return next_state[state][tms];
}

int32_t getInt32(unsigned char *data)
{
	// Return an int32_t from the received byte string, data. data is
	// expected to be 4 bytes long.
	int32_t num;

	// The int32 in data is sent little endian
	num = data[3];
	num = (num << 8) | data[2];
	num = (num << 8) | data[1];
	num = (num << 8) | data[0];

	return num;
}

void putInt32(unsigned char *data, int32_t num)
{
	// Convert the int32_t number, num, into a 4-byte, little endian
	// string pointed to by data

	data[0] = num & 0x00ff; num >>= 8;
	data[1] = num & 0x00ff; num >>= 8;
	data[2] = num & 0x00ff; num >>= 8;
	data[3] = num & 0x00ff; num >>= 8;

}

static int sread(int fd, void *target, int len)
{
	unsigned char *t = target;
	while (len)
	{
		int r = read(fd, t, len);
		if (r <= 0)
			return r;
		t += r;
		len -= r;
	}
	return 1;
}

//
// handle_data(fd) handles JTAG shift instructions.
//   To allow multiple programs to access the JTAG chain
//   at the same time, we only allow switching between
//   different clients only when we're in run_test_idle
//   after going test_logic_reset. This ensures that one
//   client can't disrupt the other client's IR or state.
//
int handle_data(int fd, unsigned long frequency)
{
	int i;
	int seen_tlr = 0;

	const char xvcInfo[] = "xvcServer_v1.0:" TOSTRING(VECTOR_IN_SZ) "\n";

	do
	{
		char cmd[16];
		unsigned char buffer[VECTOR_IN_SZ], result[VECTOR_IN_SZ/2];
		memset(cmd, 0, 16);

		if (sread(fd, cmd, 2) != 1)
			return 1;

		if (memcmp(cmd, "ge", 2) == 0)
		{
			if (sread(fd, cmd, 6) != 1)
				return 1;
			memcpy(result, xvcInfo, strlen(xvcInfo));
			if (write(fd, result, strlen(xvcInfo)) != strlen(xvcInfo))
			{
				perror("write");
				return 1;
			}
			if (vlevel > 0)
			{
				printf("%u : Received command: 'getinfo'\n", (int)time(NULL));
				printf("\t Replied with %s\n", xvcInfo);
			}
			break;
		} else if (memcmp(cmd, "se", 2) == 0)
		{
			if (sread(fd, cmd, 9) != 1)
				return 1;

			// Convert the 4-byte little endian integer after "settck:" to be an integer
			int32_t period, actPeriod;

			// if frequency argument is non-0, use it instead of the
			// period from the settck: command
			if (frequency == 0)
			{
				period = getInt32((unsigned char*)cmd+5);
			} else
			{
				period = 1000000000 / frequency;
			}

			actPeriod = io_set_period((unsigned int)period);

			if (actPeriod < 0)
			{
				fprintf(stderr, "Error while setting the JTAG TCK period\n");
				actPeriod = period; /* on error, simply echo back the period value so client while not try to change it*/
			}

			putInt32(result, actPeriod);

			if (write(fd, result, 4) != 4)
			{
				perror("write");
				return 1;
			}
			if (vlevel > 0)
			{
				printf("%u : Received command: 'settck'\n", (int)time(NULL));
				printf("\t Replied with '%d'\n\n", actPeriod);
			}
			break;
		} else if (memcmp(cmd, "sh", 2) == 0)
		{
			if (sread(fd, cmd, 4) != 1)
				return 1;
			if (vlevel > 1)
			{
				printf("%u : Received command: 'shift'\n", (int)time(NULL));
			}
		} else
		{

			fprintf(stderr, "invalid cmd '%s'\n", cmd);
			return 1;
		}
		
		if (sread(fd, cmd+6, 4) != 1)
		{
			fprintf(stderr, "reading length failed\n");
			return 1;
		}

		int32_t len;
		len = getInt32((unsigned char*)cmd+6);

		int nr_bytes = (len + 7) / 8;
		if (nr_bytes * 2 > sizeof(buffer))
		{
			fprintf(stderr, "buffer size exceeded\n");
			return 1;
		}
		
		if (sread(fd, buffer, nr_bytes * 2) != 1)
		{
			fprintf(stderr, "reading data failed\n");
			return 1;
		}
		
		memset(result, 0, nr_bytes);

		if (vlevel > 2)
		{
			printf("\tNumber of Bits  : %d\n", len);
			printf("\tNumber of Bytes : %d \n", nr_bytes);

			if (vlevel > 3)
			{
				int i;
				printf("TMS#");
				for (i = 0; i < nr_bytes; ++i)
					printf("%02x ", buffer[i]);
				printf("\n");
				printf("TDI#");
				for (; i < nr_bytes * 2; ++i)
					printf("%02x ", buffer[i]);
				printf("\n");
			}
		}

		//
		// Only allow exiting if the state is rti and the IR
		// has the default value (IDCODE) by going through test_logic_reset.
		// As soon as going through capture_dr or capture_ir no exit is
		// allowed as this will change DR/IR.
		//
		seen_tlr = (seen_tlr || jtag_state == test_logic_reset) && (jtag_state != capture_dr) && (jtag_state != capture_ir);
		
		
		//
		// Due to a weird bug(??) xilinx impacts goes through another "capture_ir"/"capture_dr" cycle after
		// reading IR/DR which unfortunately sets IR to the read-out IR value.
		// Just ignore these transactions.
		//
		
		if ((jtag_state == exit1_ir && len == 5 && buffer[0] == 0x17) || (jtag_state == exit1_dr && len == 4 && buffer[0] == 0x0b))
		{
			if (vlevel > 0)
				printf("ignoring bogus jtag state movement in jtag_state %d\n", jtag_state);
		} else
		{
			for (i = 0; i < len; ++i)
			{
				//
				// Do the actual cycle.
				//
				
				int tms = !!(buffer[i/8] & (1<<(i&7)));
				//
				// Track the state.
				//
				jtag_state = jtag_step(jtag_state, tms);
			}
			if (io_scan(buffer, buffer + nr_bytes, result, len) < 0)
			{
				fprintf(stderr, "io_scan failed\n");
				exit(1);
			}

			if (vlevel > 3) {
				int i;
				printf("TDO#");
				for (i = 0; i < nr_bytes; ++i)
					printf("%02x ", result[i]);
				printf("\n");
			}
		}

		if (write(fd, result, nr_bytes) != nr_bytes)
		{
			perror("write");
			return 1;
		}
		
		if (vlevel > 1)
		{
			printf("jtag state %d\n", jtag_state);
		}
	} while (!(seen_tlr && jtag_state == run_test_idle));
	return 0;
}

int main(int argc, char **argv)
{
	int i;
	int s;
	int c;
	int port = 2542;
	int product = -1, vendor = -1, index = 0, interface = 0;
	unsigned long frequency = 0;
	char * serial = NULL;
	struct sockaddr_in address;
	
	opterr = 0;
	
	while ((c = getopt(argc, argv, "vV:P:S:I:i:p:f:")) != -1)
		switch (c)
		{
		case 'p':
			port = strtoul(optarg, NULL, 0);
			break;
		case 'V':
			vendor = strtoul(optarg, NULL, 0);
			break;
		case 'P':
			product = strtoul(optarg, NULL, 0);
			break;
		case 'S':
			serial = optarg;
			break;
		case 'I':
			index = strtoul(optarg, NULL, 0);
			break;
		case 'i':
			interface = strtoul(optarg, NULL, 0);
			break;
		case 'v':
			vlevel++;
			//printf ("verbosity level is %d\n", vlevel);
			break;
		case 'f':
			frequency = strtoul(optarg, NULL, 0);
			break;
		case '?':
			fprintf(stderr, "usage: %s [-v] [-V vendor] [-P product] [-S serial] [-I index] [-i interface] [-f frequency] [-p port]\n\n", *argv);
			fprintf(stderr, "          -v: verbosity, increase verbosity by adding more v's\n");
			fprintf(stderr, "          -V: vendor ID, use to select the desired FTDI device if multiple on host. (default = 0x0403)\n");
			fprintf(stderr, "          -P: product ID, use to select the desired FTDI device if multiple on host. (default = 0x6010)\n");
			fprintf(stderr, "          -S: serial number, use to select the desired FTDI device if multiple devices with same vendor\n");
			fprintf(stderr, "              and product IDs on host. \'lsusb -v\' can be used to find the serial numbers.\n");
			fprintf(stderr, "          -I: USB index, use to select the desired FTDI device if multiple devices with same vendor\n");
			fprintf(stderr, "              and product IDs on host. Can be used instead of -S but -S is more definitive. (default = 0)\n");
			fprintf(stderr, "          -i: interface, select which \'port\' on the selected device to use if multiple port device. (default = 0)\n");
			fprintf(stderr, "          -f: frequency in Hz, force TCK frequency. If set to 0, set from settck commands sent by client. (default = 0)\n");
			fprintf(stderr, "          -p: TCP port, TCP port to listen for connections from client (default = %d)\n\n", port);
			return 1;
		}

	if (vlevel > 0) 
	{
		printf ("verbosity level is %d\n", vlevel);
	}

	if (io_init(vendor, product, serial, index, interface, frequency, vlevel))
	{
		fprintf(stderr, "io_init failed\n");
		return 1;
	}
	
	//
	// Listen on port 2542.
	//
	
	s = socket(AF_INET, SOCK_STREAM, 0);
	
	if (s < 0)
	{
		perror("socket");
		return 1;
	}
	
	i = 1;
	setsockopt(s, SOL_SOCKET, SO_REUSEADDR, &i, sizeof i);
	
	address.sin_addr.s_addr = INADDR_ANY;
	address.sin_port = htons(port);
	address.sin_family = AF_INET;
	
	if (bind(s, (struct sockaddr*)&address, sizeof(address)) < 0)
	{
		perror("bind");
		return 1;
	}
	
	if (listen(s, 0) < 0)
	{
		perror("listen");
		return 1;
	}
	
	fd_set conn;
	int maxfd = 0;
	
	FD_ZERO(&conn);
	FD_SET(s, &conn);
	
	maxfd = s;

	if (vlevel > 0)
		printf("waiting for connection on port %d...\n", port);
	
	while (1)
	{
		fd_set read = conn, except = conn;
		int fd;
		
		//
		// Look for work to do.
		//
		
		if (select(maxfd + 1, &read, 0, &except, 0) < 0)
		{
			perror("select");
			break;
		}
		
		for (fd = 0; fd <= maxfd; ++fd)
		{
			if (FD_ISSET(fd, &read))
			{
				//
				// Readable listen socket? Accept connection.
				//
				
				if (fd == s)
				{
					int newfd;
					socklen_t nsize = sizeof(address);
					
					newfd = accept(s, (struct sockaddr*)&address, &nsize);
					if (vlevel > 0)
						printf("connection accepted - fd %d\n", newfd);
					if (newfd < 0)
					{
						perror("accept");
					} else
					{
						if (vlevel > 0) printf("setting TCP_NODELAY to 1\n");
						int flag = 1;
						int optResult = setsockopt(newfd,
									   IPPROTO_TCP,
									   TCP_NODELAY,
									   (char *)&flag,
									   sizeof(int));
						if (optResult < 0)
							perror("TCP_NODELAY error");
						if (newfd > maxfd)
						{
							maxfd = newfd;
						}
						FD_SET(newfd, &conn);
					}
				}
				//
				// Otherwise, do work.
				//
				else if (handle_data(fd, frequency))
				{
					//
					// Close connection when required.
					//
					
					if (vlevel > 0)
						printf("connection closed - fd %d\n", fd);
					close(fd);
					FD_CLR(fd, &conn);
				}
			}
			//
			// Abort connection?
			//
			else if (FD_ISSET(fd, &except))
			{
				if (vlevel > 0)
					printf("connection aborted - fd %d\n", fd);
				close(fd);
				FD_CLR(fd, &conn);
				if (fd == s)
					break;
			}
		}
	}
	
	//
	// Un-map IOs.
	//
	io_close();
	
	return 0;
}
